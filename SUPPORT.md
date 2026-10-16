# Support and diagnostics

Report issues in [Ontos-AI/hipohipo-plugins](https://github.com/Ontos-AI/hipohipo-plugins/issues).
Include the plugin version, client and client version, OS/CPU, installation
route, safe `status` output, and a minimal synthetic reproduction. Do not attach
credentials, SQLite files, real transcripts, or screenshots with private content.

## Cursor display names

The plugin card uses **Hipo Hipo** from version 0.6.14. Its installation
identifier remains `hipohipo`. Refresh the marketplace and update through the
original installation route if the card still shows `hipohipo`.

The **Ontos Ai Hipohipo Plugins** section heading is a separate Cursor
marketplace display name. Open **Manage**, select that marketplace, edit its
marketplace name to **Hipo Hipo**, and save. Cursor stores this display name in
its marketplace management record; the plugin manifest cannot override it.
Keep the repository URL and identifiers unchanged. Reinstalling the plugin,
renaming its identifier or clearing credentials is unnecessary.

## Connection and login

- **Program download failed or is still preparing:** ask the Agent to call
  `runtime_prepare` or `runtime_status`. Each waits at most 30 seconds while
  preparation continues in the background. The live MCP connection retries
  three minutes after failure and refreshes tool discovery when ready. Calls
  and Hooks share one download and cooldown. For an immediate retry, run
  `runtime-retry` using the installed `hipohipo` launcher (`hipohipo.cmd` on
  Windows); `runtime-status` shows the last error and local log path. If a proxy is
  required, use the download proxy controls documented in [README](README.md).
  The launcher commands work without a downloaded program or Hipohipo login.
  In Cursor, inspect **Output > MCP Logs** for startup diagnostics. Other
  clients control their own log viewer; a startup error need not open a popup.

- **Only preparation tools are available:** preparation is still running or
  waiting to retry. Inspect `runtime_status`. Once ready, MCP asks the host to
  refresh its tools. Reconnect if the host does not refresh; a finished Agent
  turn still needs a new user prompt to continue.
- **No tools after install:** enable the plugin's MCP, then restart or reload
  the client. Only the host can restart a closed stdio connection. Check startup errors for missing paths,
  unsupported architecture, policy restrictions, or network failures.
- **Only auth tools are available:** call `auth.login`, complete browser
  authorization, and use the business tools once they appear. `auth.status`
  is hidden after login; do not check it before business calls. Use **Full
  access** for uploads. Reconnect MCP if its tool list does not refresh.
- **The browser did not open:** the automatic attempt is not repeated after
  failure or cancellation. Retry explicitly with `auth.login`, Cursor's
  `/hipohipo-login`, or Claude Code's `/hipohipo:login`. The Agent can start login
  but cannot complete your browser authorization. Check browser-launch and
  network errors rather than repeatedly reconnecting.
- **Credential manager unavailable:** the plugin uses a private filesystem
  fallback. If that location is not writable, fix its permissions and retry
  login. Never print or paste the stored tokens.
- **A manual command shows a different queue:** use the same state directory
  as the installed plugin. Claude Code supplies `CLAUDE_PLUGIN_DATA`; a terminal
  outside the client may not have it set. For Codex, pass `--host codex`, and
  preserve any `HIPO_CODEX_STATE_DIR` override used by the client.

## Conversation capture

- **No history is collected:** enable plugin Hooks and use a local Agent
  conversation. Start a new conversation after loading the plugin. Cursor may
  not attach newly loaded Hooks to an already-running session. Codex Hook
  settings depend on the client version; enable and trust the packaged Hooks
  through the client before testing capture.
  Claude Code on Windows needs its supported command shell, such as Git Bash.
- **Switching chats did not upload:** chat switching and window closing do not
  reliably signal session completion. Completed-turn Hooks queue uploads;
  `sessionEnd` is not required. Later activity retries pending requests.
- **Pending or paused uploads:** use the bundled `auth-status` and `status`
  commands to diagnose authorization, network errors, and write permission.
  Reconnect with Full access when required. Logout does not disable collection
  or erase pending history; disable Hooks to stop collecting.
- **Upload accepted but no memory:** admission and extraction are separate.
  Extraction is asynchronous and can fail or produce no reusable memory. Use
  the available Memory tools to check actual state instead of assuming success.

## Documents and receipt updates

- **No document confirmation form:** MCP Apps are temporarily disabled. All
  clients need native form elicitation for document confirmation. If the client
  cannot provide it, the Agent should explain the limitation and continue the
  original task without uploading; it must not invent a selection.
- **Source parsing failed:** report the original Source and error. Do not create
  another Source using a different upload mode merely to repeat a terminal parse
  failure. `knowhere_http_409` can mean parsing admission failed even when byte
  upload succeeded.
- **No response after a receipt update:** the plugin forwards updates for
  subscribed MCP receipts, but the client controls subscription, resource
  rereading, and whether another Agent turn runs. A receipt update is not a
  promise of automatic continuation. Hook uploads do not have MCP receipts.

## Platforms, updates, and removal

The packages include Apple Silicon macOS, Linux x64/ARM64, and Windows x64 native
programs. Intel Macs, Windows ARM64, and Cursor Cloud Agent capture are not
included. Each client has a separate installation entry; use its own package.

Update through the original route and restart or reload. Keep one Hipohipo
entry enabled in each client. Remove a legacy platform-specific entry before
installing the unified `hipohipo` entry. Renaming the entry may change its data
directory; the old queue is retained but is not automatically moved. Do not
remove state or revoke access solely to update.

For low-bandwidth networks, use the client-specific archives from
[Releases](https://github.com/Ontos-AI/hipohipo-plugins/releases), verify the
matching checksum file, and follow that client's local-plugin installation
instructions. Cursor's extracted package also provides `hipohipo install`.
Local Cursor installation keeps versioned executables; close the client and
plugin processes before deliberately removing old local runtimes.

Uninstalling does not erase local state or uploaded data. System-stored grants
may be shared by Hipohipo plugins on the same OS profile. See [Privacy](PRIVACY.md)
before logging out or deleting data.

Official client documentation: [Cursor plugins](https://cursor.com/docs/reference/plugins),
[Claude Code plugins](https://code.claude.com/docs/en/discover-plugins), and
[Codex plugins](https://developers.openai.com/codex/plugins).
