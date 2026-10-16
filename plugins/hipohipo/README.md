# Hipohipo

Search your Hipohipo memory and document library from Cursor, Claude Code, or
Codex. The plugin captures conversation history for memory extraction and lets
you choose which supplied files or completed documents to save to your library.

Conversation capture is enabled by default, including local collection before
login. Upload requires authorization. Document upload requires your confirmation
in the save card. See [Privacy](PRIVACY.md) for collection and retention details.

## Install

Install `hipohipo` from the same public repository in your client:

```text
https://github.com/Ontos-AI/hipohipo-plugins
```

Each client receives its own MCP, Hooks, and Skills. The package selects the
native program for your operating system automatically. On first use, its
script launcher downloads the matching program from Hipohipo's public Vercel
Blob storage, verifies it, and saves it in your OS user cache. Subsequent starts
reuse that exact version without checking the download server. No separately installed Go, Node.js, or Python is required. macOS/Linux
use the system POSIX shell, awk, curl, gzip, and sha256sum or shasum. Windows AMD64
uses built-in Windows PowerShell 5.1+, curl.exe, and .NET.

All three marketplace indices resolve the same self-contained plugin directory.
The public repository keeps only the latest root commit. Its version tags all
identify that current marketplace snapshot; they are not historical source
checkouts. Previous versioned Release attachments and runtime downloads remain
available. For historical source, follow `sourceCommit` to `Ontos-AI/hipo`.

The first download needs network access. MCP connects immediately and exposes
`runtime_prepare` and `runtime_status` while the program downloads. Each tool
waits at most 30 seconds; a pending result leaves preparation running in the
background. A live MCP connection automatically retries three minutes after a
failure and asks the client to refresh its tools when ready. Ordinary
conversations can continue; capture starts when the program is ready, and
history recovery depends on the client transcript. The plugin does not
guarantee complete capture during initialization.

### Cursor

Open **Customize > From GitHub Repository**, enter the repository URL, and
install **Hipo Hipo** (identifier `hipohipo`). Let the download finish, enable the
plugin's MCP and Hooks, then run **Developer: Reload Window** and start a new
local Agent conversation.

The marketplace section title is managed separately by Cursor. To rename an
existing **Ontos Ai Hipohipo Plugins** section, open **Manage**, select that
marketplace, edit its marketplace name to **Hipo Hipo**, and save. This changes
its display name; keep its repository URL and plugin identifiers unchanged.
Updating the plugin does not rename an existing marketplace section.

For installation without a repository download, get the Cursor archive from
[Releases](https://github.com/Ontos-AI/hipohipo-plugins/releases), verify its
checksum, and extract it. Run the following in the extracted `hipohipo` folder:

```sh
# macOS / Linux
./hipohipo install
```

```powershell
# Windows PowerShell
.\hipohipo.cmd install
```

Reload Cursor and check the plugin, MCP, and Hooks in Customize. Use one
installation route to avoid duplicate collectors.

### Claude Code

```sh
claude plugin marketplace add Ontos-AI/hipohipo-plugins
claude plugin install hipohipo@hipohipo-plugins
```

Restart Claude Code and check `/mcp` for `hipohipo`. Use `/hipohipo:login`
to connect or retry login. On Windows, Claude Code needs its supported command
shell, such as Git Bash, to run the plugin's commands and Hooks.

### Codex

In Codex Desktop, add the repository through **Customize > Plugins** and install
`hipohipo`. In the CLI, register the marketplace and use `/plugins` to install:

```sh
codex plugin marketplace add Ontos-AI/hipohipo-plugins
```

CLI versions with `codex plugin add` also support:

```sh
codex plugin add hipohipo@hipohipo-plugins
```

Restart the client and start a new local conversation. Check that `hipohipo`
has its MCP and Hooks enabled; seeing the Skill alone does not mean capture is
active. Trust the packaged Hooks through the client before testing capture.
Codex MCP and Hooks use the same OS application-data directory; manual actions
must pass `--host codex` and preserve any `HIPO_CODEX_STATE_DIR` override.
Follow your client's current documentation instead of adding an obsolete flag.

## Connect

The plugin makes one automatic browser login attempt when MCP starts or capture
needs authorization. Complete authorization yourself and choose **Full access**
for conversation and document uploads. A failed or cancelled attempt is not
repeated on every Hook or MCP reconnect.

If the browser does not open, ask the Agent to call `auth.login`, or use your
client's login entry below. The command starts login and returns while you
complete authorization in the browser. After login, business tools become
available and `auth.status` is hidden. Use business tools directly without
checking status first. Before login, `auth.status` can diagnose an incomplete
flow; do not poll it.

| Client | Manual login | Diagnostics | Logout |
| --- | --- | --- | --- |
| Cursor | `/hipohipo-login` | `/hipohipo-status` | `/hipohipo-logout` |
| Claude Code | `/hipohipo:login` | Bundled `auth-status` or `status` command | Ask the Agent to call `auth.logout` |
| Codex | Ask the Agent to call `auth.login` | Bundled `auth-status` or `status` command | Ask the Agent to call `auth.logout` |

All clients expose auth tools before login. Searching and uploading require
valid authorization and the relevant permissions. After login, the plugin asks
the client to refresh its tools; reconnect its MCP if the list does not refresh.
The plugin's login is separate from a manually configured remote HTTP MCP
connection's authentication button.

## Program preparation and logs

From the installed plugin directory, use `./hipohipo` on macOS/Linux or
`.\hipohipo.cmd` in Windows PowerShell with the following commands:

| Command | Purpose |
| --- | --- |
| `runtime-status` | Show program readiness, version, last preparation error and local log path |
| `runtime-retry` | Retry preparation immediately; a live MCP connection detects readiness |
| `proxy-status` | Show the download proxy configuration source without revealing credentials |
| `proxy-set http://127.0.0.1:7890` | Save an explicit download proxy shared by the three clients |
| `proxy-clear` | Remove the explicit download proxy and use environment proxy settings |

These commands work before the program is downloaded. Downloading does not
require Hipohipo login. If MCP is connected, ask the Agent to call
`runtime_prepare` or `runtime_status` to wait for readiness. Concurrent calls,
Hooks and connections share one download and failure cooldown. Reconnect MCP
if the host closed the connection or its tool list does not refresh. Preparation
cannot restart a finished Agent turn automatically.

An explicit download proxy takes precedence over
`HTTP_PROXY`/`HTTPS_PROXY`; otherwise standard environment settings, including
`NO_PROXY`, apply. Automatic system proxy discovery and PAC are not supported.
This setting controls program downloads; it does not configure the host's own
GitHub connection or replace authorization/network settings for Hipo requests.

Preparation errors appear on stderr for the client's MCP logs and are also
recorded locally. Runtime `status` reports the separate capture log path.
Diagnostic logs omit credentials and document/conversation bodies, rotate at
1 MiB for script preparation and 5 MiB for native runtime logs, and retain at
most four files per stream for up to 14 days. Logs remain
on your machine. Missing Hook records do not establish why the client did not
dispatch a Hook.

The same OS user shares verified program downloads across clients. Running
versions and the two most recently used versions are protected; other versions
may be removed after 30 days without use. An installed older plugin can download
its pinned version again. Cleanup does not remove login or capture data.

Pending local history uploads under the current authorization, including after
you reconnect to a different destination. Hipo chooses the destination from the
grant; the plugin does not select a Project. Other Hipohipo plugin installations
on the same OS profile may share the system-stored grant, so reconnecting or
logging out can affect them. Independently authorized HTTP MCP connections
have separate grants.

## Use Hipohipo

Ask the Agent to search memory for a preference or previous decision, or search
your library for information from a saved document. Completed conversation turns
are queued automatically when the client's Hooks run. Memory extraction happens
asynchronously; an accepted upload does not mean a new memory is searchable.
Some conversations produce no reusable memory.

Before reading a supplied document, or after producing a document it considers
ready, the Agent is instructed to request native form elicitation. Drafts and
intermediate revisions are excluded. MCP Apps are temporarily disabled for all
clients. Select the files and an existing folder, then submit or skip. The Agent
transfers only confirmed content and reports parsing status. A filename alone
is not uploaded content.

**Skip**, decline and cancellation tell the Agent to continue the original task
without uploading that revision. The instructions guide the Agent; they do not
intercept file access. If the client does not support form elicitation, the
Agent explains and continues without uploading. Silence never triggers a retry.
Confirmation expires after 30 minutes or a plugin restart.
See [the interaction contract and acceptance checklist](../../docs/hipo-document-confirmation.md).

The plugin forwards MCP receipt updates for clients that subscribe. A client
must reread a receipt to obtain its new state. Notification delivery does not
guarantee that the client starts another Agent response. Automatic history
uploads do not wait for these notifications.

## Platforms

| System | Architecture |
| --- | --- |
| macOS | Apple Silicon / ARM64 |
| Linux or WSL | x64 or ARM64 |
| Windows | x64 |

No separately installed Go, Node.js, Python, or SQLite is required. Claude Code
on Windows additionally needs its supported command shell. Intel Macs and
Windows ARM64 are not included. Conversation capture requires a local client
session that runs the plugin's Hooks; Cursor Cloud Agents are not supported.
Native executables are unsigned, so macOS or Windows may ask you to approve them.

## Update or remove

Update through your original installation route and restart or reload the client.
For Claude Code:

```sh
claude plugin marketplace update hipohipo-plugins
claude plugin update hipohipo@hipohipo-plugins
```

For Codex, refresh the catalog with
`codex plugin marketplace upgrade hipohipo-plugins`, then update or reinstall
`hipohipo` through the plugin interface. Cursor users refresh or reinstall from
the repository and reload the window.

Reinstallation preserves local data and credentials. A new plugin version or
location allows one new automatic login attempt if authorization is missing.
Remove an older platform-specific entry before installing `hipohipo`, so only
one collector is active in each client.

Logout removes local credentials and stops authorized uploads. Remote grant
revocation is best effort and cannot block logout or the next login. Local
collection continues while Hooks are enabled. Disable the plugin's Hooks to stop collection.
Uninstalling does not erase local history or credentials, or delete data already
uploaded to Hipohipo. See [Privacy](PRIVACY.md) before removing local data.

[Support](SUPPORT.md) · [Privacy](PRIVACY.md) · [Changelog](CHANGELOG.md)

Client documentation: [Cursor plugins](https://cursor.com/docs/reference/plugins),
[Claude Code plugins](https://code.claude.com/docs/en/discover-plugins), and
[Codex plugins](https://developers.openai.com/codex/plugins).
