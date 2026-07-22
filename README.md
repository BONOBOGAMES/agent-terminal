# Agent Terminal

Based on [Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons) by Tom Cassady (heytcass), MIT.

This repository contains a custom **Home Assistant app** (formerly called an *add-on*) that integrates xAI’s Grok Build CLI with Home Assistant OS / Supervisor.

**Unofficial.** Not affiliated with, endorsed by, or sponsored by xAI, SpaceXAI, Anthropic, or Home Assistant.

## What is this for?

Agent Terminal runs the [Grok Build](https://docs.x.ai/build/overview) coding agent (`grok`) in a browser terminal **inside** Home Assistant, with your `/config` mounted. Typical use:

- Write and fix automations, scripts, and YAML with help from an AI that can see your config
- Debug dashboards, templates, and entity issues from the same machine that runs HA
- Optionally let Grok talk to Home Assistant via [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) (device state, control, automations)

**Requirements:** Home Assistant OS or Supervised (Apps / Supervisor). You need an **xAI account** and either an **API key** (recommended) or interactive login. Not available on plain Container/Core installs without Supervisor.

## Installation

Requires [Home Assistant OS](https://www.home-assistant.io/installation/) or Supervised (the **Apps** panel, formerly Add-ons).

**Quick path:** open this link on a machine that can reach your HA instance:

[![Open your Home Assistant instance and show the add app repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FBONOBOGAMES%2Fagent-terminal)

Or manually:

1. Go to **[Settings → Apps](https://my.home-assistant.io/redirect/supervisor)** → open the app store (**Install app** / store icon)
2. ⋮ (top right) → **Repositories**
3. Add: `https://github.com/BONOBOGAMES/agent-terminal`
4. Find **Agent Terminal**, install, set **xai_api_key** (recommended), start

> **Note:** Since Home Assistant 2026.2, the UI says **Apps** instead of **Add-ons**. Same Supervisor packaging model; only the label changed. Older guides may still say “Add-on Store”.

## Apps in this repository

### Agent Terminal

A web-based terminal with Grok Build CLI pre-installed. Open it from the HA sidebar and use Grok for coding, automation, and configuration tasks against your live config.

Features:
- Web terminal access through your Home Assistant UI
- Pre-installed Grok Build CLI (`grok`) that launches automatically
- Direct access to your Home Assistant config directory
- Authentication via app option `xai_api_key` (recommended) or interactive login
- Access to Grok Build’s capabilities including:
  - Code generation and explanation
  - Debugging assistance
  - Home Assistant automation help
  - Learning resources

[Documentation](agent-terminal/DOCS.md)

## Support

If you have any questions or issues with this app, please create an issue in this repository.

## Credits

This app is a structural fork of [Claude Terminal](https://github.com/heytcass/home-assistant-addons) by Tom Cassady (heytcass), rewired for xAI’s Grok Build CLI. Upstream is MIT-licensed; see [LICENSE](LICENSE) and [NOTICE](NOTICE).

Created with Grok.

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
