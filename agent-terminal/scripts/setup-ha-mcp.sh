#!/usr/bin/with-contenv bashio
# Setup ha-mcp (Home Assistant MCP Server) for Grok Build
# Repository: https://github.com/homeassistant-ai/ha-mcp
# Adapted from Claude Terminal (heytcass), MIT.

set -e

configure_ha_mcp_server() {
    local enable_ha_mcp
    enable_ha_mcp=$(bashio::config 'enable_ha_mcp' 'true')

    if [ "$enable_ha_mcp" != "true" ]; then
        bashio::log.info "ha-mcp integration is disabled in configuration"
        return 0
    fi

    bashio::log.info "Setting up ha-mcp (Home Assistant MCP Server)..."

    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.warning "SUPERVISOR_TOKEN not available - ha-mcp setup skipped"
        return 0
    fi

    if ! command -v uvx &> /dev/null; then
        bashio::log.warning "uvx not found - ha-mcp setup skipped"
        return 0
    fi

    if ! command -v grok &> /dev/null; then
        bashio::log.warning "grok not found - ha-mcp setup skipped"
        return 0
    fi

    local version
    version=$(bashio::config 'ha_mcp_version' '7.11.0')

    # Remove existing ha-mcp configuration if present (clean state)
    grok mcp remove home-assistant 2>/dev/null || true

    # ha-mcp >= 4.x requires CPython 3.13 exactly, which no Alpine release
    # ships — uv provisions a managed musl 3.13 build (persisted under /data
    # via XDG_DATA_HOME, so it downloads once).
    # --index-strategy unsafe-best-match: the HA wheels index doesn't carry
    # every version, so let uv consider all indexes (CT #77/#79)
    if grok mcp add home-assistant \
        --scope user \
        -e "HOMEASSISTANT_URL=http://supervisor/core" \
        -e "HOMEASSISTANT_TOKEN=${SUPERVISOR_TOKEN}" \
        -- uvx --python 3.13 --index-strategy unsafe-best-match "ha-mcp@${version}"; then
        bashio::log.info "ha-mcp ${version} configured for Grok Build"

        (uvx --python 3.13 --index-strategy unsafe-best-match \
            --from "ha-mcp@${version}" python -c "" >/dev/null 2>&1 || true) &
        bashio::log.info "Pre-warming ha-mcp environment in background"
    else
        bashio::log.warning "Failed to configure ha-mcp - continuing without MCP integration"
        bashio::log.warning "Manual: grok mcp add home-assistant -e HOMEASSISTANT_URL=http://supervisor/core -e HOMEASSISTANT_TOKEN=\$SUPERVISOR_TOKEN -- uvx --python 3.13 --index-strategy unsafe-best-match ha-mcp@${version}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_ha_mcp_server
fi
