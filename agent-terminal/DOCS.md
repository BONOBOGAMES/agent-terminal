# Agent Terminal

Grok Build CLI in a web terminal, as a Home Assistant add-on.

**Unofficial.** Not affiliated with, endorsed by, or sponsored by xAI, SpaceXAI,
Anthropic, or Home Assistant. Based on [Claude Terminal](https://github.com/heytcass/home-assistant-addons) by Tom Cassady (MIT).

Repository: [github.com/BONOBOGAMES/agent-terminal](https://github.com/BONOBOGAMES/agent-terminal)

## About

This add-on runs xAI’s [Grok Build](https://docs.x.ai/build/overview) CLI (`grok`)
in a browser-based terminal (ttyd + tmux) with your Home Assistant configuration
mounted. Open it from the sidebar, authenticate once, and ask Grok to write
automations, debug YAML, or manage your setup.

## Installation

1. In Home Assistant, open **Settings → Add-ons → Add-on Store**
2. ⋮ → **Repositories** → add:

   `https://github.com/BONOBOGAMES/agent-terminal`

3. Install **Agent Terminal**
4. (Recommended) Open **Configuration** and set **xai_api_key** to your xAI API key
5. Start the add-on
6. Optional: **Info** tab → enable **Show in sidebar**
7. Open the web UI (or use the sidebar)

Credentials and agent state live under `/data` and persist across restarts and
add-on updates.

Using Grok Build Service features requires accepting [xAI Terms of Service](https://x.ai/legal/terms-of-service).
This project does not grant rights to xAI trademarks or services.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `auto_launch_grok` | `true` | Start Grok immediately when the terminal opens. Set to `false` for a shell (run `grok` yourself). |
| `grok_auto_update` | `true` | Keep Grok current: installs the official binary into `/data` and updates it in the background on each startup. |
| `xai_api_key` | `""` | **Recommended.** xAI API key (`xai-...`). Exported as `XAI_API_KEY`. Prefer this over browser OAuth inside HA ingress. |
| `always_approve` | `false` | Launch with `--permission-mode bypassPermissions` (no confirmation prompts). **Read the security note below.** |
| `grok_extra_args` | `""` | Extra flags appended to every Grok launch, e.g. `-m grok-4`. Values are split on spaces; quoted multi-word arguments are not supported. |
| `ha_smart_context` | `true` | Generate `~/.grok/AGENTS.md` with your HA system info so Grok knows your setup. |
| `enable_ha_mcp` | `true` | Register the [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) MCP server so Grok can control Home Assistant directly. |
| `ha_mcp_version` | `"7.11.0"` | ha-mcp release to run. |
| `persistent_apk_packages` | `[]` | APK packages reinstalled on every startup. |
| `persistent_pip_packages` | `[]` | Python packages reinstalled on every startup. |

## Usage

With default settings, Grok launches automatically inside a tmux session named
`grok`. Navigating away in Home Assistant and coming back reattaches to the same
session — your conversation survives.

Useful commands (in shell mode, or after exiting Grok):

```bash
grok               # start Grok Build
grok -c            # continue the most recent conversation
grok -r            # pick a past conversation to resume
grok-doctor        # diagnose network, auth, and environment issues
grok-login-url     # save the OAuth login URL to /config (see Troubleshooting)
persist-install apk htop   # install packages that survive restarts
ha-context         # refresh the Home Assistant context file
```

### Terminal tips

- **Scrolling**: use the mouse wheel — tmux copy-mode opens automatically. Press `q` to jump back to the bottom.
- **Copying**: select text with the mouse; on release it's copied to your clipboard (OSC 52). Long wrapped lines (like OAuth URLs) are joined back into one line automatically. Note: browsers only allow clipboard writes on secure pages — if you access Home Assistant over plain `http://`, use Shift+drag instead.
- **Shift+drag**: bypasses tmux and gives you the browser's native text selection (copy with `Ctrl+C` / right-click).
- **Pasting**: use `Ctrl+Shift+V` (or right-click, depending on browser).

### File access

The terminal starts in `/config` (your Home Assistant configuration). Also mounted:

- `/addon_configs` — configuration directories of your other add-ons
- `/share` — the shared folder

## Authentication

### API key (recommended)

1. Create an API key in the xAI console.
2. Paste it into the add-on option **xai_api_key**.
3. Restart the add-on.

This is the most reliable path inside Home Assistant ingress (no browser OAuth
clipboard pain).

### Interactive login

If you prefer account login, run `grok` and follow prompts. If the login URL is
too long to copy from the terminal, use `grok-login-url` (see Troubleshooting).

## Home Assistant MCP Integration

The bundled [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) server connects
Grok to Home Assistant through the Supervisor API — no long-lived token setup
needed. Grok can query states, control devices, and manage automations when MCP
tools are available.

ha-mcp requires Python 3.13, which Alpine doesn't ship — the add-on provisions a
managed Python build via [uv](https://github.com/astral-sh/uv) into `/data` on
first use (a one-time ~150–250 MB download that persists across restarts).

Disable it with `enable_ha_mcp: false` if you don't want the agent to have this access.

## Security notes

**This add-on gives Grok a lot of power by design**: it runs as root in its
container, has read/write access to `/config`, `/addon_configs`, and `/share`,
and (with MCP enabled) can control devices and modify automations.

**`always_approve` removes the last human checkpoint.** With it enabled, a
misunderstanding — or a prompt injection in any file or web page Grok reads —
can modify your HA configuration or actuate devices without asking you first.
Leave it off unless you understand and accept that trade-off. A warning banner
is printed in the add-on log whenever it is active.

Never commit API keys to git. Keys belong in Supervisor add-on options only.

## Troubleshooting

- **Can't copy the OAuth login URL**: open a second tmux window (`Ctrl+B` then `C`), run `grok-login-url`, and open `/config/grok-login-url.txt` with the File Editor add-on (or over Samba). Prefer **xai_api_key** instead.
- **Grok exits immediately**: check add-on log; ensure `xai_api_key` is set or complete login; run `grok-doctor`.
- **Diagnostics**: run `grok-doctor` in the terminal for connectivity, memory, and environment checks.
- **Install or update fails pulling the image**: check that your HA host can reach `ghcr.io`, then retry. Prebuilt images are published for `amd64` and `aarch64`.

## Credits

- Architecture and add-on patterns from **Claude Terminal** by Tom Cassady ([heytcass/home-assistant-addons](https://github.com/heytcass/home-assistant-addons)), MIT.
- **Grok Build** by xAI / SpaceXAI (Apache-2.0 source; Service use under xAI ToS).
- **ha-mcp** by homeassistant-ai (MIT).

Created with Grok.
