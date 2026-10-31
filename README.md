# Hipohipo

Search Hipohipo memory and documents from Cursor, Claude Code, Codex or WorkBuddy.
The plugin can capture conversations for memory extraction and save documents
under the connection's authorization.

## Install and update

Follow the [installation and update guide](https://hipohipo.ai/install/README.md)
or its [Chinese version](https://hipohipo.ai/install/README.zh-CN.md).
Choose the active client's first-install or update route, preserve its existing
configuration and authorization, then verify the actual MCP connection.

Give your Agent this instruction:

> Read https://hipohipo.ai/install/README.md and install or update Hipohipo in this client.

Cursor Local updates use the installed Hipohipo CLI. Marketplace installations
use their client's plugin manager; future updates depend on the source and client
settings described in the guide. Do not switch installation channels, clear
history or log out solely to upgrade. Keep one active Hipohipo entry per client.

No separately installed Go, Node.js, Python or SQLite is required. The package
selects the native program for the current system. For an actual installation
or download error, consult [Support](SUPPORT.md).

## Connect

Reuse valid authorization, including read-only access. When sign-in is needed,
use the exposed `auth.login` tool or the installed CLI described in the guide.
Confirm the account, destination Project and permissions during consent.
Uploads require write access; do not replace a valid read-only grant merely to
finish installation.

Use the current MCP's `auth.status` to observe authorization and the responding
plugin version. A CLI status result does not prove that the host has loaded MCP.
If login is pending, continue the same flow. Do not start parallel logins or
retry after refusal or cancellation without a new request.

## Conversation capture

Conversation capture is enabled by default, including local collection before
login. Authorized uploads require the relevant permission. Collection depends
on a supported local client session with the plugin's Hooks enabled; it does
not scan unopened historical conversations. Memory extraction is asynchronous
and may produce no reusable memory.

Disable Hooks to stop local collection. Logout stops authorized uploads while
local collection continues if Hooks remain enabled. Pending uploads use the
currently authorized destination, so confirm the account and Project before
reconnecting. See [Privacy](PRIVACY.md) for collection and retention details.

## Documents

The document-capture Skill saves eligible supplied documents and completed
file deliverables when the connection permits background saving. Drafts,
intermediate edits, installation guides, Agent instructions, source code and
configuration are excluded unless the user explicitly asks to save them.

If the background-save tool is unavailable or denied, the Agent continues the
original task without saving. Explicit save requests use the exposed save tool.
Uploading another version of an already-saved file may require confirmation.
Report the actual upload/parse result; an asynchronous receipt does not promise
that processing has finished. Local reading can proceed independently of saving.

## Share a conversation

Use the sharing command in the supported local conversation you want to share:

| Client | Command |
| --- | --- |
| Cursor Desktop or CLI | `/hipo-share` |
| Claude Code | `/hipohipo:share` |
| Codex CLI | `$hipohipo:hipo-share` |
| WorkBuddy Desktop | Type `/hipo-share` in full |

Sharing creates a fixed snapshot of the selected conversation branch. Anyone
holding its link can read it; the link can be revoked in Hipo. Attachments and
an executable native session are not transferred. Availability and recovery
vary by client; see [sharing support](SUPPORT.md#sharing-a-conversation) when a
command is unavailable or the result is pending.

## Rules and memories import

In the Project's connection manager, choose the connected app and start an
import. The default selection is the current app; other supported apps can be
selected during confirmation. Import uses the authorized Project and requires
the displayed approval before reading sources.

Import covers eligible user-level rules and locally cached memories. Coverage
varies by client. Project-level stores, unopened historical conversations,
generated Cursor memories and team rules are excluded. One import selects up
to 200 files; later source edits do not synchronize automatically. The manager
reports progress, empty results and coverage gaps.

For WorkBuddy, keep a task with Hipohipo enabled available while local collection
is needed. Opening the app alone does not establish plugin availability. Stop
prevents new import work; already submitted content may still finish.

## Platforms

| System | Architecture |
| --- | --- |
| macOS | Apple Silicon / ARM64 or Intel / x64 |
| Linux or WSL | x64 or ARM64 |
| Windows | x64 or ARM64 |

Claude Code on Windows additionally needs its supported command shell, such as
Git Bash. Conversation capture requires a local client session that runs the
plugin's Hooks; Cursor Cloud Agents are not supported. Native executables are
unsigned, so macOS or Windows may ask you to approve them.

## Diagnostics and privacy controls

Use the installed CLI or exposed status tools only when diagnostics are needed;
keep the same client configuration as MCP. [Support](SUPPORT.md) describes proxy,
program preparation, update preferences, rollback and client-specific recovery.
Never paste credentials into chat or diagnostic reports.

Operational telemetry is enabled by default. It sends sampled timing traces and
warning/error diagnostics through Hipo to Logfire, excluding conversation text,
MCP arguments/results, credentials, URLs and local paths. Use the installed CLI's
`telemetry disable` command with the same client context to opt out, or set
`HIPO_TELEMETRY_ENABLED=false`. See [telemetry controls](SUPPORT.md#telemetry-controls).

## Retained data and removal

Keep the same entry, source, scope and valid authorization during ordinary updates;
do not disable or uninstall it first. Preserve retained Hipo data. Follow Support
before changing a custom data location.

Authorization may be shared between Hipohipo plugin clients on the same OS
profile; reconnecting or logging out can affect those clients. Independently
authorized HTTP MCP connections are separate.

Logout removes local credentials and stops authorized uploads; remote revocation
is best effort. Disable Hooks to stop collection. Uninstalling does not delete
data already uploaded to Hipohipo. See [Privacy](PRIVACY.md) before removing any
local data, and preserve existing history when using the client's plugin manager.

[Support](SUPPORT.md) · [Privacy](PRIVACY.md) · [Changelog](CHANGELOG.md)
