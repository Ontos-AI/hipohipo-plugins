---
name: document-capture
description: Use before reading or parsing a supplied document, or when a generated document is ready for use. Offer Hipohipo native document confirmation and upload only the user's confirmed selection.
---

Offer relevant documents from the current conversation. A generated document
may be ready based on your judgment; a draft, scratch note, partial result, or
intermediate revision is not ready. Readiness permits an offer, not upload.

For a supplied document, derive its filename from the user's reference and
request native confirmation before reading its contents. Do not open, summarize, or parse
its bytes to prepare the offer or while waiting for confirmation. After
confirmation, read the selected content for upload, then continue the original
task, including unselected documents when the task requires them. After Skip,
continue the original task without uploading.

## Offer and wait

1. Keep a mapping of candidate IDs to exact accessible references and revisions,
   including generated content. Offer at most 10 candidates at a time. Pass IDs
   and filenames to `document_offer`; never pass local paths, document content,
   credentials, or a Project choice. Do not search directories for more files.
2. Use `library.list` to obtain existing folders under current authorization.
   Follow `nextCursor` and pass real `folderId` values as `folderRef`. Include
   parent names to distinguish identically named folders. The form always
   includes library root, represented by null. If listing fails, explain and
   offer root; do not invent folders. If more than 100 folders are available,
   ask which destinations to include. Do not create folders or choose a Project.
   Recommend one existing destination using only filenames, the current task
   and explicit user instructions. Pass its exact `folderRef` as
   `recommendedFolderRef`. Omit it or pass null when no folder clearly matches;
   this recommends Library. Never read file contents to make the recommendation.
3. Call `document_offer` with the metadata and `interaction: "elicitation"`.
   Document confirmation currently uses native form elicitation only; MCP Apps
   are temporarily disabled, even when the client declares App support. An
   elicitation may remain inside the tool call until answered. Do not run
   parallel file reads while confirmation is pending. The bridge asks one
   question at a time: one file goes directly to saving at the recommended
   destination; multiple files are selected first. On compatible clients the
   choices are All files, Other - choose files, and Don't save. Other opens a
   native text question for numbers such as `1,3` or exact filenames, one per
   line. The bridge validates this input, summarizes the selected files and
   destination, and handles location changes. Do not ask these questions again,
   interpret partial selections yourself, or upload before final confirmation.
   - `confirmed`: handle the validated selection returned by the tool.
   - `skipped`: continue the original task without uploading.
   - `unavailable`: explain the native confirmation limitation and continue the
     original task without uploading. Never substitute conversational approval.
4. Do not request an App card or call `document_selection`. Do not poll or retry
   after silence. Expired offers or changed document revisions require a new
   explicit offer. A client without form elicitation cannot confirm an upload.

## Handle the selection

5. Match the returned `offerId`, `revision`, candidate IDs, and folder to your offer. If the
   mapping is missing, the selection is not recognized, or the revision changed,
   explain and obtain a new selection. Do not guess which content to save.
   Retain Source and operation identifiers for each offer, revision and candidate. If a
   confirmation repeats, report or resume that operation instead of creating
   another Source. Changing files or destination after creation requires a new
   explicit offer; do not move or replace an admitted Source silently.
6. On Confirm, upload only the selected candidates. Pass `folderRef` as
   `source.create`'s `folderId`, or null for root. Follow the tool's actual upload
   contract: base64 inline content within its limit, a direct-upload permit and
   PUT of real bytes, or a reachable file URL. A local path is not a remotely
   readable URL. Upload automatically starts parsing; there is no separate
   plugin parse or confirmation step. Preserve operation identifiers and reuse
   an idempotency key only when retrying the same request.
7. Use `source.get_status` to report actual per-file outcomes. Uploaded bytes
   do not mean parsing succeeded. Stop on a terminal result. If a bounded wait
   ends before completion, report pending and retain the identifiers for later
   checks. Report terminal failures without silently changing upload methods
   or creating replacement Sources.
8. On Skip, create no Source and complete the original task. Do not proactively
   offer the same revision again in this conversation. A changed revision or
   later explicit save request may trigger another offer.

## Authorization and memory

Use available business tools directly without an authorization preflight.
`auth.status` is hidden after login; use it only for incomplete login or an
authorization problem when it is available. Offer `auth.login` when needed.
Retry a failed login only when the user requests it. The user
completes authorization in the browser. Do not add another MCP connection or
read credentials or the capture database. Conversation history is captured by
Hooks; do not call `memory.write` to reconstruct automatic history capture.
