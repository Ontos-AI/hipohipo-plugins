---
name: document-capture
description: Use for supplied documents to read or analyze, completed document deliverables, or explicit requests to save files to Hipohipo. Exclude installation guides, Agent instructions, source code, and configuration used in engineering tasks unless the user explicitly asks to save them to Hipohipo.
---

Do not trigger document capture for installation guides, Agent instructions,
source code, or configuration read, created, or edited to perform an engineering
task, unless the user explicitly asks to save those files to Hipohipo. Read or
edit them directly without library calls. Determine scope from the user's task
and file reference. Do not search directories for extra documents.

For documents within scope, save supplied documents before reading or analyzing
them for the user's task, and completed generated documents when ready. Follow
**Background saves** under existing authorization; a reading request does not
request a foreground save. Reading exact bytes to preserve and upload the
immutable revision is part of the save step. Do not defer saving until after
answering the reading request.

A generated document may be ready based on your judgment; drafts, scratch
notes, partial results and intermediate revisions are excluded. Preserving the
original file does not prevent a permitted background copy. An explicit
instruction not to upload, save externally or sync takes priority: skip saving
and continue the original task. If background saving is unavailable, continue
the original task without saving.

## Background saves

1. Use `source.create_background` only when it is advertised in the available
   tools. Availability reflects the current connection's background save
   permission and write access. If absent, denied or unavailable, skip the save
   and continue the original task. Do not start login, preparation or extra
   prompts; never fall back to `source.create` for a proactive save.
2. Retain each document's exact accessible reference and immutable revision,
   and the account and Project destination under current authorization. Do not
   infer a Project from local paths or previous conversations. If an admitted
   request's destination or document revision changes, do not retry it under
   a new identity or silently create a replacement Source.
3. Choose a matching existing folder using `library.list` with
   `{isBackground: true}` when available, and follow `nextCursor` with the same
   hint to resolve it. Use its real `folderId`; otherwise use
   Library root with null or omitted `folderId`. Do not ask a folder question,
   invent an ID or create a folder automatically. If listing is unavailable,
   use root without an extra login or preparation attempt.
4. Follow `source.create_background`'s upload contract: inline base64 within
   its limit, a direct-upload permit and PUT of the real bytes, or a remotely
   reachable URL. A local path is not a remotely readable URL. Upload starts
   parsing automatically. Create and retain an idempotency key before the first
   upload. Preserve the same immutable bytes, upload permit,
   idempotency key and returned Source and operation identifiers for retries.
   An uncertain submission must not create a duplicate Source. Resume or check
   the admitted operation rather than submitting again.
5. Use `source.get_status` with `{isBackground: true}` to establish actual
   outcomes. If a companion read is unavailable, do not retry it as an ordinary
   foreground read. Retain the Source and operation identifiers and continue
   the original task without login or preparation. Uploaded bytes do not
   prove parsing succeeded. Retain identifiers when a bounded wait ends pending;
   stop on terminal results. Report failures without silently changing upload
   methods or creating replacement Sources. Do not claim a skipped save
   succeeded or interrupt the original task to obtain more permissions.

## Explicit saves and authorization

For an explicit user request to save a file, use `source.create`. Follow the
user's specified destination; otherwise choose a matching existing folder or
root. Preserve immutable revision, destination, idempotency and operation
identities, and check status as above. User-explicit folder listing and status
reads omit `isBackground`; their ordinary foreground authorization behavior
remains available.

Ordinary business tools remain discoverable offline. Their foreground calls can
prepare the runtime and obtain or refresh authorization. `auth.status` is passive.
Use `auth.login` for a retry after a terminal stop only when explicitly requested.
This foreground setup behavior does not apply to proactive background saves.
Do not add another MCP connection or inspect credentials or the capture database.
Hooks capture conversation history; do not reconstruct it with `memory.write`.
