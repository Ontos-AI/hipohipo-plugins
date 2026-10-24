# Hipohipo

Search your Hipohipo memory and document library from Cursor, Claude Code,
Codex Desktop or CLI, or WorkBuddy. The plugin captures conversation history for memory extraction and lets
you choose which supplied files or completed documents to save to your library.

Conversation capture is enabled by default, including local collection before
login. Upload requires authorization. Document upload requires your confirmation
in the save card. See [Privacy](PRIVACY.md) for collection and retention details.

Operational telemetry is enabled by default. It sends sampled timing traces and
warning/error diagnostics through Hipo to Logfire, excluding conversation text,
MCP arguments/results, credentials, URLs and local paths. Use the bundled
`telemetry disable` command to opt out, or set `HIPO_TELEMETRY_ENABLED=false`.
See [telemetry controls](SUPPORT.md#telemetry-controls) for host-specific commands.

## Install and update

WorkBuddy users in mainland China can use the [Chinese installation guide](https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/install/README.zh-CN.md).
The guide, version index, complete marketplace and pinned runtime are mirrored
to OSS; WorkBuddy prefers that runtime mirror and falls back on network failure.

Follow the [unified installation guide](https://raw.githubusercontent.com/Ontos-AI/hipohipo-plugins/main/install/README.md)
for Cursor, Claude Code, Codex and WorkBuddy. It defines installation, updates,
loading, sign-in and completion.

Sign-in can finish through this installed package's CLI when the current
conversation has no MCP tools. Use the same host/profile/data binding. Confirm
`authorized`, then report host MCP availability separately. Capture complete
JSON and the real exit code. Continue pending preparation with the same command;
terminal failures require the action named in `nextAction`, never manual
downloads or lock cleanup. Explicit login replaces a rejected old credential
only for this instance and starts one new consent flow. Normal CLI browser login
stays in the foreground with `--timeout-seconds <1..600>` (default 600). Tell the
user the browser will open before calling it and wait for that invocation.
Preparation still returns pending after at most 30 seconds. Device mode remains
an alternative and the fallback for browser-open or callback-listener failure;
it returns a complete public-code link immediately, then resumes the same code
on subsequent login calls. See `SUPPORT.md` for host budgets and error handling.
Give your Agent this instruction:

> Read https://raw.githubusercontent.com/Ontos-AI/hipohipo-plugins/main/install/README.md and install Hipohipo.

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

The first operation prepares the pinned runtime if needed. Discovery and status
remain available without downloading or logging in. Preparation has one shared
600-second deadline covering download, verification, extraction and publication.
A bounded tool wait can return pending while preparation continues. A failed
attempt stays stopped until an explicit `runtime_prepare` retry. The same tool
catalog remains available throughout; no tool refresh is required after login.
Ordinary conversations can continue; capture starts when the program is ready,
and history recovery depends on the client transcript. The plugin does not
guarantee complete capture during initialization.

### Client notes

The marketplace section title is managed separately by Cursor. To rename an
existing **Ontos Ai Hipohipo Plugins** section, open **Manage**, select that
marketplace, edit its marketplace name to **Hipo Hipo**, and save. This changes
its display name; keep its repository URL and plugin identifiers unchanged.
Updating the plugin does not rename an existing marketplace section.

Codex MCP and Hooks use the same OS application-data directory; manual actions
must pass `--host codex` and preserve any `HIPO_CODEX_STATE_DIR` override.
Follow your client's current documentation instead of adding an obsolete flag.

## Connect

A foreground operation starts or joins login when authorization is missing and
refreshes an expired credential before dispatch. MCP startup, discovery, status
and background capture do not open a browser. Complete browser consent and
choose **Full access** for uploads. Cancellation or terminal failure stops
recovery until you explicitly request `auth.login`; `auth.logout` stops it too.

A bounded tool wait may return pending; the operation has not executed.
The same tools remain available after successful login. `auth.status`
observes local state without networking or refresh. Cached identity is labeled
as last verified. A pending or cancelled operation is never replayed after its
call ends. If recovery changes the account or Project, confirm the destination
before issuing another operation.

| Client | Manual login | Diagnostics | Logout |
| --- | --- | --- | --- |
| Cursor | `/hipohipo-login` | `/hipohipo-status` | `/hipohipo-logout` |
| Claude Code | `/hipohipo:login` | Bundled `auth-status` or `status` command | Ask the Agent to call `auth.logout` |
| Codex | Ask the Agent to call `auth.login` | Bundled `auth-status` or `status` command | Ask the Agent to call `auth.logout` |

All clients expose the same auth and business tool names before and after login.
Searching and uploading require valid authorization and the relevant permissions.
Login does not require the client to refresh its tool list.
The plugin's login is separate from a manually configured remote HTTP MCP
connection's authentication button.

## Program preparation and logs

From the installed plugin directory, use `./hipohipo` on macOS/Linux or
`.\hipohipo.cmd` in Windows PowerShell with the following commands:

| Command | Purpose |
| --- | --- |
| `runtime-prepare` | Start or join preparation without login; terminal failures require explicit retry |
| `runtime-status` | Show program readiness, version, last preparation error and local log path |
| `runtime-retry` | Retry preparation immediately; a live MCP connection detects readiness |
| `proxy-status` | Show the download proxy configuration source without revealing credentials |
| `proxy-set http://127.0.0.1:7890` | Save an explicit download proxy shared by the three clients |
| `proxy-clear` | Remove the explicit download proxy and use environment proxy settings |

These commands work before the program is downloaded. Downloading does not
require Hipohipo login. If MCP is connected, ask the Agent to call
`runtime_prepare` or `runtime_status` to wait for readiness. Concurrent calls,
Hooks and connections share one download. A failed attempt stays stopped until
an explicit retry. Reconnect MCP only if the host closed its connection. Preparation
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

Installation guides, Agent instructions, source code, and configuration used
in engineering tasks do not trigger document capture unless the user explicitly
asks to save them to Hipohipo. The Agent reads or edits them directly.
For other supplied documents or completed document deliverables, the Agent
uses `source.create_background` when the current connection permits proactive
saving. Browser and device authorization offer this choice, enabled by default
with Full access; existing connections also receive the enabled default.
Drafts and intermediate revisions are excluded. The Agent selects an existing
folder or Library root and reports the actual upload/parse status.

There is no per-document form or chat offer. When the background tool is absent
or denied, the Agent skips saving without substituting `source.create` or
starting login. Explicit save requests still use `source.create`. Local reading
and analysis can continue independently of saving. See
[the document-capture contract](../../docs/hipo-document-confirmation.md).

The plugin forwards MCP receipt updates for clients that subscribe. A client
must reread a receipt to obtain its new state. Notification delivery does not
guarantee that the client starts another Agent response. Automatic history
uploads do not wait for these notifications.

## Share a conversation

Run the native sharing command in the conversation you want to share:

| Client | Command |
| --- | --- |
| Cursor Desktop or CLI | `/hipo-share` |
| Claude Code | `/hipohipo:share` |
| Codex CLI | `$hipohipo:hipo-share` |
| WorkBuddy Desktop | Fully typed `/hipo-share` |

The command freezes the selected branch's original user and visible assistant
text before login or upload. It creates a link that anyone holding it can read.
You can revoke the link in Hipo. Sharing does not transfer attachments, tool
outputs or an executable native session. An interrupted upload can retry its
saved snapshot without reading a newer conversation.

The current candidate still requires fresh native acceptance after its version
update. Earlier candidate checks passed the recorded CLI lifecycle cases and
selected Desktop cases. Cursor Desktop's immediate share after an edit/resubmit
rewind remains unaccepted and can return `share_generation_in_progress`.
WorkBuddy's `@skill` picker is unreliable; use the fully typed command. Local
WorkBuddy Desktop fork is unsupported. Claude Code's latest lifecycle round was
skipped after earlier provider quota/access failures. See
[sharing support](SUPPORT.md#sharing-a-conversation) for these boundaries.

## Platforms

| System | Architecture |
| --- | --- |
| macOS | Apple Silicon / ARM64 or Intel / x64 |
| Linux or WSL | x64 or ARM64 |
| Windows | x64 or ARM64 |

No separately installed Go, Node.js, Python, or SQLite is required. Claude Code
on Windows additionally needs its supported command shell. Conversation capture requires a local client
session that runs the plugin's Hooks; Cursor Cloud Agents are not supported.
Native executables are unsigned, so macOS or Windows may ask you to approve them.

## Rules and memories import

The prepared import increment lets an authorized plugin collect eligible
user-level rules and locally cached memories from Cursor, Claude Code, Codex,
and WorkBuddy into its Hipo Project. It excludes project-level stores, old
conversation directories, generated Cursor memories, and team rules. Cursor
account User Rules use the current local Cursor login through a read-only
request to Cursor. Credentials never upload to Hipo and are never refreshed
by the plugin. If the private endpoint is unavailable, the import reports the
coverage gap and continues with local sources. Local WorkBuddy sources
may cover multiple readable accounts. One import selects up to 200 files; later
source edits do not synchronize automatically.

Open the Project's connection manager and choose its app/instance. Each
app/configuration instance has an independent connection and a matching short
label in local `auth-status`. Keep the host's configuration metadata and
persistent data directory when running diagnostic commands outside the client.
A pending authorization request grants no file access; complete its existing
Allow step before import starts. All app connections share the Project's one
active import slot.

The manager shows file progress, empty results, source-coverage limitations,
and published Memory with Evidence. Stop prevents new import work while
already submitted content may still finish. A temporarily absent plugin keeps
its original task and selection for recovery. For WorkBuddy, resume a task
with Hipohipo enabled; opening the desktop alone does not promise collection.

WorkBuddy has a distinct host package and shares the authorized background
document-capture policy. Native installation, conversation fidelity, document upload, and
platform support require the separate host acceptance record; cross-compilation
and synthetic process checks alone do not establish those capabilities.

## Retained data and removal

Reinstallation preserves local data and credentials; reuse valid authorization
through the unified guide. Keep only one active Hipohipo installation per client.

Logout removes local credentials and stops authorized uploads. Remote grant
revocation is best effort and cannot block logout or the next login. Local
collection continues while Hooks are enabled. Disable the plugin's Hooks to stop collection.
Uninstalling does not erase local history or credentials, or delete data already
uploaded to Hipohipo. See [Privacy](PRIVACY.md) before removing local data.

[Support](SUPPORT.md) · [Privacy](PRIVACY.md) · [Changelog](CHANGELOG.md)

Client documentation: [Cursor plugins](https://cursor.com/docs/reference/plugins),
[Claude Code plugins](https://code.claude.com/docs/en/discover-plugins), and
[Codex plugins](https://developers.openai.com/codex/plugins).
