---
name: document-capture
description: MUST load before reading supplied documents (MD/TXT too) or writing finished plan/report/design files. Skip engineering code/config, Agent instructions/install guides, drafts and repeated reads/edits unless asked to save.
---

Do not trigger document capture for installation guides, Agent instructions,
source code, or configuration read, created, or edited to perform an engineering
task, unless the user explicitly asks to save those files to Hipohipo. Read or
edit them directly without library calls. Determine scope from the user's task
and file reference. Do not search directories for extra documents.

document-capture is only for supplied documents and finished Agent-generated
standalone documents. Skill packs use skill.push. Memory files such as
AGENTS.md use memory-import. Do not send those through source.parse_background
or source.create.

When calling source.parse_background or source.create, set captureReason:
- supplied: the user asked to read or provided the file
- generated: the Agent wrote a finished plan, report, or design

## Capture timing and document readiness

For an in-scope supplied document, try Hipohipo parsing before its first reading,
summarization or analysis. Read the exact original bytes for the parsing request.
For a generated file, load this Skill when the writing task is recognized, then
capture the completed deliverable before linking or attaching it in the final
reply. Standalone plans, PoC plans, research reports and design documents count,
including engineering documents stored in a code repository. A plan awaiting
approval or implementation can still be a complete document.

Drafts, scratch notes, partial results and intermediate revisions are excluded.
Do not capture each edit or save while a document is being developed. A draft
becomes eligible only when it is ready as a standalone deliverable. Handle only
existing document files; do not create a file from chat text just for capture.

Remember each file's capture attempt and outcome in the current conversation.
Do not call background parsing again for repeated reads, continued editing or
later revisions of that file. Use **Explicit saves** for a user-requested save
or reparse. Resume an existing pending operation instead of creating a new one.
A different complete path, including a renamed file, is a new candidate; do not
track renames or compare contents to merge file identities.

Preserving the original file does not prevent a permitted background copy. An
explicit instruction not to upload, save externally or sync takes priority:
skip capture and continue the original task. If background parsing is unavailable,
continue the original task without it.

## Background parsing

1. For an in-scope document without an explicit opt-out, resolve
   `source.parse_background` in the host's advertised tools. When it is available,
   continue through steps 2-5 before completing the first reading task or
   delivering the generated file, subject to
   normal host review. Loading this Skill, discovering the tool or reading local
   bytes does not complete the background parsing workflow. Availability reflects
   the current connection's background save permission and write access. If the
   tool is absent, denied or unavailable, skip and continue the original task.
   Do not start login, preparation or extra prompts; never fall back to
   `source.create` for a proactive save.
   A result with `status: "confirmation_required"` means the plugin remembers
   an earlier upload of this path to the current Project; no new Source or upload
   was created. Ask whether the user wants to parse the current version again.
   Only their explicit agreement permits the **Explicit saves** workflow below.
   If they decline or have not answered, continue the original task without
   another save attempt or repeated question. Do not retry background parsing,
   change the path, title or folder, or invent a retry key to bypass this result.
   This question applies only to that result, never to an absent, denied or
   unavailable background tool.
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
4. For an accessible local file, call `source.parse_background` with only
   `localFilePath` set to the absolute original file path, plus the chosen
   `folderId` when applicable and `captureReason` (`supplied` or `generated`).
   The plugin derives filename, size, SHA-256, MIME
   and a persisted retry identity. Do not calculate metadata, encode content,
   or generate an idempotency key. The path remains local. When `transferCommand`
   is returned, execute that complete command unchanged; its operation record
   already binds the original path and bytes. Do not append `--file` or other
   arguments. When `transferSandboxPermissions` is returned, pass that value as
   `exec_command.sandbox_permissions` for normal host review. The existing
   approval Hook checks the current background grant and original file.
   Retain Source, receipt and transfer operation identifiers for recovery.
   If `transferUnavailable` is true or a call is denied, continue the original
   task without another transfer method or replacement Source.
   For a remotely reachable document, provide `fileUrl`. For a direct HTTP file
   upload, provide only `filename`, then PUT original file bytes to the returned
   `uploadUrl` using the returned `uploadHeaders`. Never interpret a local path
   as a remotely reachable URL. Do not restart an uncertain operation.

5. Use `source.get_status` with `{isBackground: true}` to establish actual
   outcomes. If a companion read is unavailable, do not retry it as an ordinary
   foreground read. Retain the Source and operation identifiers and continue
   the original task without login or preparation. Uploaded bytes do not
   prove parsing succeeded. Retain identifiers when a bounded wait ends pending;
   stop on terminal results. Report failures without silently changing upload
   methods or creating replacement Sources. Do not claim a skipped save
   succeeded or interrupt the original task to obtain more permissions.

## Explicit saves and authorization

For an explicit user request to save or reparse a file, including agreement to
the repeat-upload question above, use `source.create` with the same
minimal file inputs and transfer workflow above. Normal host approval and write
permission apply; independent background permission is not required. Follow the
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
