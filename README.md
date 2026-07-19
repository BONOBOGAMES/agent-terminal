# Agent Terminal

Based on [Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons) by Tom Cassady (heytcass), MIT.

This repository contains a custom add-on that integrates xAI’s Grok Build CLI with Home Assistant.

**Unofficial.** Not affiliated with, endorsed by, or sponsored by xAI, SpaceXAI, Anthropic, or Home Assistant.

## Installation

To add this repository to your Home Assistant instance:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots menu in the top right corner
3. Select **Repositories**
4. Add the URL: `https://github.com/BONOBOGAMES/agent-terminal`
5. Click **Add**

## Add-ons

### Agent Terminal

A web-based terminal interface with Grok Build CLI pre-installed. This add-on provides a terminal environment directly in your Home Assistant dashboard, allowing you to use Grok’s AI capabilities for coding, automation, and configuration tasks.

Features:
- Web terminal access through your Home Assistant UI
- Pre-installed Grok Build CLI (`grok`) that launches automatically
- Direct access to your Home Assistant config directory
- Authentication via add-on option `xai_api_key` (recommended) or interactive login
- Access to Grok Build’s capabilities including:
  - Code generation and explanation
  - Debugging assistance
  - Home Assistant automation help
  - Learning resources

[Documentation](agent-terminal/DOCS.md)

## Support

If you have any questions or issues with this add-on, please create an issue in this repository.

## Credits

This add-on is a structural fork of [Claude Terminal](https://github.com/heytcass/home-assistant-addons) by Tom Cassady (heytcass), rewired for xAI’s Grok Build CLI. Upstream is MIT-licensed; see [LICENSE](LICENSE) and [NOTICE](NOTICE).

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
