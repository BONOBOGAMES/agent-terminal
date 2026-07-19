#!/usr/bin/with-contenv bashio

# Agent Terminal — Grok Build CLI in a browser terminal
# (ttyd + tmux). Adapted from Claude Terminal (heytcass), MIT.
#
# Startup philosophy: everything the terminal needs is baked into the image,
# and nothing on the boot path may depend on the network or block on input.
# Network work (Grok updates, HA context generation) happens in the
# background after the terminal is already available.

set -e
set -o pipefail

# Initialize environment for Grok Build CLI using /data (HA best practice)
init_environment() {
    # Use /data exclusively - guaranteed writable by HA Supervisor
    local data_home="/data/home"
    local config_dir="/data/.config"
    local cache_dir="/data/.cache"
    local state_dir="/data/.local/state"
    local grok_home="${data_home}/.grok"

    bashio::log.info "Initializing Grok Build environment in /data..."

    if ! mkdir -p "$data_home" "$config_dir" "$cache_dir" "$state_dir" \
        "/data/.local" "$grok_home" "$grok_home/bin" "$grok_home/downloads"; then
        bashio::log.error "Failed to create directories in /data"
        exit 1
    fi

    chmod 755 "$data_home" "$config_dir" "$cache_dir" "$state_dir" "$grok_home"

    # XDG + HOME: Grok stores auth/config under ~/.grok
    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="$cache_dir"
    export XDG_STATE_HOME="$state_dir"
    export XDG_DATA_HOME="/data/.local/share"

    # Persistent Grok install wins over the image-bundled binary
    export PATH="$grok_home/bin:/usr/local/bin:$PATH"

    # API key from add-on options (recommended path for HA ingress)
    if bashio::config.has_value 'xai_api_key'; then
        local key
        key=$(bashio::config 'xai_api_key')
        if [ -n "$key" ] && [ "$key" != "null" ]; then
            export XAI_API_KEY="$key"
            bashio::log.info "XAI_API_KEY loaded from add-on options"
        fi
    fi

    # Install tmux configuration to user home directory
    if [ -f "/opt/scripts/tmux.conf" ]; then
        cp /opt/scripts/tmux.conf "$data_home/.tmux.conf"
        chmod 644 "$data_home/.tmux.conf"
    fi

    bashio::log.info "Environment initialized (HOME=${HOME})"
}

# Install user-facing commands into /usr/local/bin
setup_commands() {
    local entry name script
    for entry in \
        "welcome:/opt/scripts/welcome.sh" \
        "persist-install:/opt/scripts/persist-install.sh" \
        "ha-context:/opt/scripts/ha-context.sh" \
        "grok-doctor:/opt/scripts/health-check.sh" \
        "grok-login-url:/opt/scripts/grok-login-url.sh"; do
        name="${entry%%:*}"
        script="${entry#*:}"
        if [ -f "$script" ]; then
            cp "$script" "/usr/local/bin/$name"
            chmod +x "/usr/local/bin/$name"
        else
            bashio::log.warning "Script not found: $script"
        fi
    done

    # Write add-on version for the welcome banner (no bashio inside ttyd)
    bashio::addon.version > /opt/scripts/addon-version 2>/dev/null \
        || echo "unknown" > /opt/scripts/addon-version
}

# Keep Grok Build current. The copy in the image is frozen at build time,
# so install the official binary into /data (persists across restarts and
# add-on updates) and refresh it in the background on each boot.
update_grok() {
    if [ "$(bashio::config 'grok_auto_update' 'true')" != "true" ]; then
        bashio::log.info "Grok auto-update disabled; using bundled grok binary"
        return 0
    fi

    if [ -x "$HOME/.grok/bin/grok" ]; then
        bashio::log.info "Persistent Grok found; checking for updates in background"
        (
            # Re-run official installer into HOME (static binary under ~/.grok)
            curl -fsSL --connect-timeout 10 https://x.ai/cli/install.sh | bash >/dev/null 2>&1 || true
        ) &
    else
        bashio::log.info "Installing persistent Grok into /data (background)..."
        (
            if curl -fsSL --connect-timeout 10 https://x.ai/cli/install.sh | bash >/dev/null 2>&1 \
                && [ -x "$HOME/.grok/bin/grok" ]; then
                bashio::log.info "Persistent Grok installed: $("$HOME/.grok/bin/grok" --version 2>/dev/null || echo 'version unknown')"
            else
                bashio::log.warning "Persistent Grok install failed; using bundled copy for now"
            fi
        ) &
    fi
}

# Install persistent packages from config and saved state
install_persistent_packages() {
    local persist_config="/data/persistent-packages.json"
    local apk_packages=""
    local pip_packages=""

    if bashio::config.has_value 'persistent_apk_packages'; then
        local config_apk
        config_apk=$(bashio::config 'persistent_apk_packages')
        if [ -n "$config_apk" ] && [ "$config_apk" != "null" ]; then
            apk_packages="$config_apk"
        fi
    fi

    if bashio::config.has_value 'persistent_pip_packages'; then
        local config_pip
        config_pip=$(bashio::config 'persistent_pip_packages')
        if [ -n "$config_pip" ] && [ "$config_pip" != "null" ]; then
            pip_packages="$config_pip"
        fi
    fi

    if [ -f "$persist_config" ]; then
        local local_apk local_pip
        local_apk=$(jq -r '.apk_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        if [ -n "$local_apk" ]; then
            apk_packages="$apk_packages $local_apk"
        fi

        local_pip=$(jq -r '.pip_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        if [ -n "$local_pip" ]; then
            pip_packages="$pip_packages $local_pip"
        fi
    fi

    apk_packages=$(echo "$apk_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)
    pip_packages=$(echo "$pip_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)

    if [ -n "$apk_packages" ]; then
        bashio::log.info "Installing persistent APK packages: $apk_packages"
        # shellcheck disable=SC2086
        if apk add --no-cache $apk_packages; then
            bashio::log.info "APK packages installed successfully"
        else
            bashio::log.warning "Some APK packages failed to install"
        fi
    fi

    if [ -n "$pip_packages" ]; then
        bashio::log.info "Installing persistent pip packages: $pip_packages"
        # shellcheck disable=SC2086
        if pip3 install --break-system-packages --no-cache-dir $pip_packages; then
            bashio::log.info "pip packages installed successfully"
        else
            bashio::log.warning "Some pip packages failed to install"
        fi
    fi
}

# Generate Home Assistant context for Grok sessions (background)
generate_ha_context() {
    if [ "$(bashio::config 'ha_smart_context' 'true')" != "true" ]; then
        bashio::log.info "HA Smart Context disabled in configuration"
        return 0
    fi

    if [ -f /usr/local/bin/ha-context ]; then
        bashio::log.info "Generating Home Assistant context in background"
        (/usr/local/bin/ha-context >/dev/null 2>&1 || true) &
    fi
}

# Build extra flags for every grok launch.
# Note: the value is word-split; quoted multi-word arguments are not
# re-parsed (documented limitation).
build_grok_flags() {
    local flags=""

    if [ "$(bashio::config 'always_approve' 'false')" = "true" ]; then
        # Grok equivalent of Claude's --dangerously-skip-permissions
        flags="--permission-mode bypassPermissions"
    fi

    local extra
    extra=$(bashio::config 'grok_extra_args' '')
    if [ -n "$extra" ] && [ "$extra" != "null" ]; then
        flags="${flags:+$flags }$extra"
    fi

    echo "$flags"
}

# Determine the command ttyd runs for each client connection
get_grok_launch_command() {
    local flags="$1"

    if [ "$(bashio::config 'auto_launch_grok' 'true')" = "true" ]; then
        # tmux -A attaches to the live session on browser reconnects and HA
        # navigation instead of stacking new ones
        echo "tmux new-session -A -s grok 'grok${flags:+ $flags}'"
    else
        # Shell mode: banner + interactive bash, still inside tmux
        echo "tmux new-session -A -s grok '/usr/local/bin/welcome --shell'"
    fi
}

# Start main web terminal
start_web_terminal() {
    local port=7681
    local flags
    flags=$(build_grok_flags)

    if [[ "$flags" == *"bypassPermissions"* ]] || [[ "$flags" == *"--always-approve"* ]]; then
        bashio::log.warning "=========================================================="
        bashio::log.warning "always_approve / bypassPermissions is ENABLED."
        bashio::log.warning "Grok will run tools without asking for confirmation."
        bashio::log.warning "It has write access to /config and can control Home"
        bashio::log.warning "Assistant through the Supervisor API and MCP."
        bashio::log.warning "=========================================================="
    fi

    local launch_command
    launch_command=$(get_grok_launch_command "$flags")

    bashio::log.info "Starting web terminal on port ${port} (auto_launch_grok=$(bashio::config 'auto_launch_grok' 'true'))"

    # Terminal theme — dark palette with amber accents (not CT terracotta)
    local ttyd_theme='{"background":"#1a1b26","foreground":"#c0caf5","cursor":"#f59e0b","cursorAccent":"#1a1b26","selectionBackground":"#33467c","selectionForeground":"#c0caf5","black":"#15161e","red":"#f7768e","green":"#9ece6a","yellow":"#e0af68","blue":"#7aa2f7","magenta":"#bb9af7","cyan":"#7dcfff","white":"#a9b1d6","brightBlack":"#414868","brightRed":"#f7768e","brightGreen":"#9ece6a","brightYellow":"#e0af68","brightBlue":"#7aa2f7","brightMagenta":"#bb9af7","brightCyan":"#7dcfff","brightWhite":"#c0caf5"}'

    # keepalive configuration to prevent WebSocket disconnects
    # See CT issue: https://github.com/heytcass/home-assistant-addons/issues/24
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 30 \
        --client-option enableReconnect=true \
        --client-option reconnect=10 \
        --client-option reconnectInterval=5 \
        --client-option "theme=${ttyd_theme}" \
        --client-option fontSize=14 \
        bash -c "$launch_command"
}

# Setup ha-mcp (Home Assistant MCP Server) for Grok Build
setup_ha_mcp() {
    if [ -f "/opt/scripts/setup-ha-mcp.sh" ]; then
        bashio::log.info "Setting up Home Assistant MCP integration..."
        chmod +x /opt/scripts/setup-ha-mcp.sh
        source /opt/scripts/setup-ha-mcp.sh
        configure_ha_mcp_server || bashio::log.warning "ha-mcp setup encountered issues but continuing..."
    fi
}

main() {
    bashio::log.info "Starting Agent Terminal add-on..."

    init_environment
    setup_commands
    update_grok
    install_persistent_packages
    generate_ha_context
    setup_ha_mcp
    start_web_terminal
}

main "$@"
