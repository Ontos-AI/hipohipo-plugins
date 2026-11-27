---
name: resume-session
description: Continue work from a prior Hipohipo agent session on this account. Use when the user asks to resume the last session, continue from another agent, migrate from A to B, pick up prior work that is not in this conversation, or otherwise continue an earlier recoverable session.
---

Resume exactly one prior session. Do not reconstruct transcripts from memory, local files, or SHARE links.

1. Call `handoff.list`. Compare the user's request with each item's title and summary.
2. Resume **one** session only when a single item is a high-confidence match, or when the user clearly points at one item. Clear pointing is a strong match signal.
3. If more than one item fits, or confidence is low: show the titles and summaries and ask the user to choose. If none fit, do not resume.
4. After choosing, call `handoff.read` with that `handoffId`. Load the original transcript page plus the summary as prior context, then continue the work. Follow `nextCursor` if the page is incomplete.

Do not resume more than one session in the same turn. Do not guess. This is an agent resume, not a web Ask continuation.
