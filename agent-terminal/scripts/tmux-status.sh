#!/bin/bash

# tmux-status.sh — lightweight status bar data for Agent Terminal
# Called by tmux every status-interval seconds. Must be fast (<1s).

# --- Auth status ---
auth_status() {
    # API key path (add-on options export XAI_API_KEY into the environment)
    if [ -n "${XAI_API_KEY:-}" ]; then
        echo "#[fg=colour114]Auth"
        return
    fi

    # OAuth / interactive login artifacts under ~/.grok
    local grok_dir="${HOME}/.grok"
    if [ -f "$grok_dir/auth.json" ]; then
        # Presence of auth.json usually means a login happened; expiry format
        # varies — green if file non-empty, orange if empty/unreadable.
        if [ -s "$grok_dir/auth.json" ]; then
            echo "#[fg=colour114]Auth"
        else
            echo "#[fg=colour208]Auth"
        fi
        return
    fi

    # Deployment key
    if [ -n "${GROK_DEPLOYMENT_KEY:-}" ]; then
        echo "#[fg=colour114]Auth"
        return
    fi

    echo "#[fg=colour203]Auth"
}

# --- HA connection status ---
ha_status() {
    if [ -z "$SUPERVISOR_TOKEN" ]; then
        echo "#[fg=colour245]HA"
        return
    fi

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 2 \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        "http://supervisor/core/api/" 2>/dev/null)

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "#[fg=colour114]HA"
    else
        echo "#[fg=colour208]HA"
    fi
}

auth=$(auth_status)
ha=$(ha_status)
datetime=$(date '+%a %m-%d %H:%M')

echo "${auth} #[fg=colour245]| ${ha} #[fg=colour245]| #[fg=colour252]${datetime}"
