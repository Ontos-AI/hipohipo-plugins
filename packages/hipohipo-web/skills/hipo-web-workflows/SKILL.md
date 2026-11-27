---
name: hipo-web-workflows
description: With the user's Hipo permissions, save explicitly stated durable preferences, capture supplied documents before first reading or analysis and completed standalone Markdown before delivery, or search existing Hipo knowledge.
---

# Hipo Hipo Web

Use the Hipo MCP tools for the connected Brain. Respect the host's approval prompts and the permissions the user granted in Hipo. If a write is unavailable, denied, or fails, continue the user's task without starting a login flow or substituting another write tool.

## Preferences

When the user explicitly states a lasting preference or correction that applies to future work, call `memory.write` with only `userText`. Pass the shortest self-contained excerpt in the user's original words and language. Skip inferred preferences, one-time instructions, assistant statements, sensitive data, credentials, and quoted third-party content.

Use `memory.get_status` with the returned receipt ID to check processing. Use `memory.search` to verify the result before reporting that the preference was saved.

## Capture timing and document readiness

Do not trigger document capture for installation guides, Agent instructions,
source code, or configuration read, created, or edited to perform an engineering
task, unless the user explicitly asks to save those files to Hipohipo. Read or
edit them directly without library calls. Determine scope from the user's task
and file reference. Do not search directories for extra documents.

For an in-scope supplied document, try Hipohipo parsing before its first reading,
summarization or analysis. Read the exact original bytes for the parsing request.
For a generated file, load this Skill when the writing task is recognized, then
capture the completed deliverable before linking or attaching it in the final
reply. Standalone plans, PoC plans, research reports and design documents count,
including engineering documents stored in a code repository. A plan awaiting
approval or implementation can still be a complete document.

Drafts, scratch notes, partial results and intermediate revisions are excluded.
Do not capture each edit or save while a document is being developed. A draft
becomes eligible only when it is ready as a standalone deliverable.

Remember each file's capture attempt and outcome in the current conversation.
Do not call background parsing again for repeated reads, continued editing or
later revisions of that file.

Preserving the original file does not prevent a permitted background copy. An
explicit instruction not to upload, save externally or sync takes priority:
skip capture and continue the original task. If background parsing is unavailable,
continue the original task without it.

The generated-file rule also applies to completed standalone Markdown delivered as inline text. Skip ordinary chat replies.

## Background parsing on the web

Call `source.parse_background` with exactly one document input:

- For a completed Markdown deliverable, send its `title`, a `filename` ending in `.md`, full `content`, and `contentEncoding: "utf8"`. Preserve headings, tables, and Unicode.
- For a supplied original, use its public HTTPS `fileUrl` or the ChatGPT attachment bound by the host to `file` so Hipo can fetch the original bytes. If neither is available, continue the original task. For an explicit save request, direct the user to upload the original to the Library in their [connected Hipo Brain](https://hipohipo.ai/app/projects).

Set an `idempotencyKey` for each document save and reuse it on retry. Check the same Source with `source.get_status`. Report it as saved and parsed once ready, or retain its reference if pending. Check `library.search` when confirming searchability.
