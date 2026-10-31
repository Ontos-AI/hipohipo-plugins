# Conversation capture and privacy

## Collection and authorization

Conversation capture is enabled by default. When your client's plugin Hooks run,
the plugin collects user text and assistant replies locally, including before
login. It uploads pending history only with valid authorization and write
permission. Logout stops authorized upload; local collection continues until
you disable the plugin's Hooks or remove the plugin.

Hipo selects the destination and permissions from current authorization. The
plugin has no Project selector. Pending history can therefore upload to a new
destination after you reconnect. Root-aware plugin instances use independent
grants and account-specific credential slots. An instance identifies one app
and its effective configuration root; its installation cache is not its identity.
Authorizing or logging out of one independently authorized instance does not
replace another instance's grant. Older installations can retain a legacy
shared grant until they complete the existing Allow flow; migration preserves
that grant for installations still using it. A migrated instance does not fall
back to the legacy grant after logout or credential loss.

Logout removes local credentials even if remote revocation fails. Status reports
an unconfirmed remote closure separately; deleting a local credential does not
prove that the server connection was revoked.

## One-time rules and memories import

An authorized connection can request a one-time import into its Hipo Project.
After independent authorization, imports default to eligible user-level sources
from the authorized app on that OS account. The connection manager also offers
all supported apps: Cursor, Claude Code, Codex, and WorkBuddy. In that mode,
files from the authorized app are selected first within the 200-file limit. WorkBuddy
sources can include multiple readable local account caches. Project-level
stores and historical transcripts are excluded.
Formal file references are collected when available; missing references do
not block the import. The selected source inventory is capped at 200 files.

When the chosen scope includes Cursor, account User Rules are read once using the current local Cursor access
token, directly from Cursor's official service. The plugin opens only the known
Cursor login database in read-only mode; it does not read refresh credentials,
renew the session, or upload login credentials to Hipo. Account and rule IDs are
hashed for provenance. This private Cursor endpoint can change without notice;
unavailable, interrupted, or limited account coverage is shown separately, and
local source collection continues. Generated Cursor memories and team rules
are excluded. A task resumes frozen rule snapshots without another account read.

Selected files upload through private storage. Hipo prepares their text for
the existing Memory capture service and retains source provenance in Evidence.
Each task keeps its original Account, Project, connection, and selected-file
identities during recovery. Reconnecting cannot redirect it. Later local file
changes or deletions do not update or retract imported Memory.

Only one import task runs in a Project at a time. Stop prevents further import;
already submitted content can still finish processing and produce Memory.
Waiting for a plugin, failed recovery, empty extraction, and incomplete source
coverage are reported separately from completed file progress.

## What is captured

The collector uses the active session's Hook events and, when available, its
readable transcript to reconcile user text and assistant replies. It does not
scan unopened historical conversations. Explicit reasoning blocks, tool blocks,
raw attachment contents, and separately identified subagent conversations are
excluded. Text you or the assistant include in a message remains conversation
text, including excerpts from documents.

Capture depends on the events and transcript format supplied by the client.
Missing or unrecognized records can result in an incomplete history. Coverage
diagnostics record known gaps. The collector cannot reliably classify private
content that the client supplies as ordinary untagged message text.

The first reliable capture of an active conversation queues all verifiable
supported history. Later captures queue new message occurrences and complete
changed message versions, including persisted replies from interrupted turns.
A later reply may repeat its associated user message as context. An unchanged
message version does not create another request; distinct verified messages
with identical text remain eligible. Progress records durable local queueing,
independently of network delivery.

When history is incomplete, capture queues only verifiable supported messages
with a gap marker and can collect missing history when the supplied transcript
recovers. Hook text without evidence of an accepted conversation message stays
tentative locally. Rewinding does not retract old captures or cancel old queued
uploads. Unsupported or permanently unavailable history can remain missing.
Upgrading from the older turn-based collector can replay readable history once
because its retained keys do not prove which message versions were captured.

## Local storage

The plugin embeds SQLite and stores history outside its versioned installation.
The database is not separately encrypted. Unix directory permissions and the
Windows user profile ACL protect access.

| Client | Persistent state |
| --- | --- |
| Cursor on macOS | `~/Library/Application Support/Hipohipo/cursor-plugin` |
| Cursor on Linux / WSL | `$XDG_DATA_HOME/hipohipo/cursor-plugin`, or `~/.local/share/hipohipo/cursor-plugin` |
| Cursor on Windows | `%AppData%/Hipohipo/cursor-plugin` |
| Claude Code | The client's `CLAUDE_PLUGIN_DATA` directory; `HIPO_CLAUDE_STATE_DIR` can override it |
| Codex on macOS | `~/Library/Application Support/Hipohipo/codex` |
| Codex on Linux / WSL | `$XDG_DATA_HOME/hipohipo/codex`, or `~/.local/share/hipohipo/codex` |
| Codex on Windows | `%AppData%/Hipohipo/codex` |
| WorkBuddy | The client's `CODEBUDDY_PLUGIN_DATA` directory |

`HIPO_CODEX_STATE_DIR` can override Codex's persistent state. Versions before
0.5.13 used the client's `PLUGIN_DATA` directory; retained data there is not
automatically moved. An explicit `--state-dir` overrides the host's default.
Root-aware state is partitioned beneath that base directory by its stable
instance descriptor. Complete configuration paths remain local; connection
management shows a short instance label.

The `status` command reports the active state directory, queue counts, message
offsets, initialization state and pending recovery without conversation text.
Pending recovery includes conservative checks for delayed transcript writes;
it does not imply that an upload failed. Manual commands must use the same state
directory as the installed plugin to inspect its queue.

Credentials use macOS Keychain, Linux Secret Service, or Windows Credential
Manager when available. If the system manager is unavailable, the plugin stores
credentials in a private `credentials.json` in its state directory. Unix uses
`0700` directory and `0600` file permissions; Windows relies on the profile ACL.
The file fallback is less isolated than a system credential manager. Tokens are
not stored in SQLite or ordinary status output.

## Upload and retention

Hooks durably record events and attempt bounded local collection before starting
background workers. They return without waiting for upload or memory extraction.
The plugin does not run a permanent uploader. Later client activity and MCP
startup can recover recorded capture work; closing the client is not a flush guarantee.
Network errors retain requests and permission errors pause them. A server
acknowledgement marks admission, not successful memory extraction. Automatic
history uploads are internal submissions, without MCP operation receipts.
Hipohipo forwards history to Memento for deduplication and memory extraction.
Not every conversation produces a reusable memory.

History is divided into complete-turn batches below 5,000,000 logical bytes.
An oversized turn retains its beginning and truncates the excess suffix with an
explicit marker and omitted-byte metadata. Large requests may use gzip.
Delivered request payloads are cleared from the local upload queue. Unconfirmed
Hook text expires after 30 inactive days; fingerprints and unresolved gap
records remain. Verified pending message text and pending or paused uploads
remain across updates, reinstallation, and logout. Cleanup runs during later
plugin activity. Text-free occurrence identities, version outcomes and ordered
baselines survive text-cache cleanup. Without stable native identity or reliable
ordered alignment, a rewind followed by an identical submission can be
indistinguishable from an unchanged conversation. Ambiguous history recovery
can repeat content rather than suppress a potentially new message.

Terminal events without reply text retain a recovery receipt because reaching
the end of a file cannot prove the client finished writing it. Sparse sources
also retain recovery independently of whether their Hook prompt was accepted.
Later runtime activity revisits supplied paths within bounded passes; it does
not poll continuously. These recovery receipts may remain after all known
messages have uploaded.

## Documents and deletion

Browser and device authorization offer a per-connection choice to let the
Agent save relevant supplied documents and completed deliverables proactively.
This choice defaults on with Full access, and existing connections receive the
enabled default. `source.parse_background` checks that permission and write
access before accepting a save. First-time background capture does not ask a
per-document save question. A repeated uploaded path requires the Agent to ask
whether the user wants to parse its current version again; only explicit
agreement permits a foreground save.
When disabled, the Agent skips proactive saving; explicit user-requested saves
still use `source.create`. Both upload paths start parsing automatically. Local
reading and the original task can continue independently of saving.

A separate `document-history.sqlite` in the local plugin instance's state stores
the service identity, Account and Project IDs, normalized absolute original-file
paths, Source references and upload timestamps. Before byte transfer it also
retains the path-to-operation association needed to recover a later failed
history write; that association alone is not evidence of a successful upload.
The successful-upload index records byte transfers, not parsing success, and
survives conversations, restarts and logout.
Paths remain local; the plugin does not scan for other documents, compare file
contents to track renames, or share this index across devices. Different paths
are independent. Existing upload journals retain recovery for uncertain requests.

Disabling Hooks stops future collection. Logout removes local credentials and
suppresses automatic login without erasing local history. It also attempts to
revoke the old remote grant for up to three seconds; failed remote cleanup does
not prevent local logout. To remove local history, log out, close the client
and its plugin processes, then deliberately
remove the active state directory. Do not delete data while a collector is
using it. Uninstalling the plugin does not erase its external state or delete
history, memories, or documents already uploaded to Hipohipo.

Do not share credential files, capture databases, or real transcripts for
support. Use a synthetic reproduction and redacted diagnostics.

## Operational telemetry

Operational telemetry is enabled by default independently of conversation upload
authorization. The plugin sends sampled operation timing and warning/error
diagnostics to Hipo, which forwards sanitized records to Logfire. Records may
include plugin version, environment, operation category, HTTP status, attempt
count, random trace IDs and bounded function names/line numbers at the error
capture boundary. Raw error messages are replaced with safe failure categories.
Conversation text, MCP arguments/results, filenames, filesystem paths, URL
queries, access tokens and account identity are excluded. Local JSONL diagnostics
remain available.

Run `telemetry disable` using the same host and state directory as the plugin to
stop export, or set `HIPO_TELEMETRY_ENABLED=false` before starting the client.
`telemetry enable` restores the local preference; the environment opt-out wins.
`telemetry status` shows the effective setting. Logout does not disable telemetry.
These controls do not change conversation collection or authorized upload.

Telemetry queues are bounded and memory-only. Offline/full queues drop records;
there is no telemetry database or deferred telemetry upload. Hook processes do
not export telemetry. Random W3C trace context is retained beside business
notifications and pending uploads so later delivery attempts can be correlated.
Disabling telemetry suppresses new context and propagation. Already exported
telemetry is not removed by disabling the plugin.
