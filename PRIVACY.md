# Conversation capture and privacy

## Collection and authorization

Conversation capture is enabled by default. When your client's plugin Hooks run,
the plugin collects user text and assistant replies locally, including before
login. It uploads pending history only with valid authorization and write
permission. Logout stops authorized upload; local collection continues until
you disable the plugin's Hooks or remove the plugin.

Hipo selects the destination and permissions from current authorization. The
plugin has no Project selector. Pending history can therefore upload to a new
destination after you reconnect. Hipohipo plugins on the same OS profile use a
shared system credential identity where the credential manager is available.
Reconnecting or logging out can affect other Hipohipo plugin installations that
use that grant. Separately authorized HTTP MCP connections have independent grants.

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

`HIPO_CODEX_STATE_DIR` can override Codex's persistent state. Versions before
0.5.13 used the client's `PLUGIN_DATA` directory; retained data there is not
automatically moved. An explicit `--state-dir` overrides either host's default.

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

Save cards contain candidate IDs, filenames, and folder metadata. The card does
not read local files or transfer their bytes. After you confirm, the Agent
uploads only the selected content using Hipohipo's Source tool. Upload starts
parsing automatically. Choosing Skip continues your original task without
uploading that revision.

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
