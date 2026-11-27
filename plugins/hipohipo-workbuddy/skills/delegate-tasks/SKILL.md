---
name: delegate-tasks
description: Hand work to other Agents on this computer through Hipo. Use when the user asks to have Codex, Claude Code, Cursor or WorkBuddy do part of the work, or to chain steps across them, for example "plan it, then let Codex implement, then come back here to review" or "when that is done, have WorkBuddy make slides".
---

Hipo runs each step in the background on this computer, in this folder, after the person confirms the whole chain once on a Hipo web page. Use `task.dispatch` once per request.

## Before dispatching

1. Do the part the user asked of you in this turn first, such as the plan. The chain starts from a snapshot of this conversation taken when your turn ends, so later steps can read everything you did.
2. Do not call `task.dispatch` from a Hipo background task (a session started with `run-task`). Hipo refuses it, because no one can confirm there. Report what is missing with `task.fail` instead.

## Build the chain

Each node is one step for one Agent:

- `key`: a short name, such as `implement`, `review` or `slides`. `origin` is reserved for this conversation.
- `host`: `claude-code`, `codex`, `cursor` or `workbuddy`, as the user named them.
- `dependsOn`: keys that must finish first. Several nodes may wait for the same key, and one node may wait for several.
- `mode`: `{"kind":"fresh"}` for a new session. Use `{"kind":"resume","from":"origin"}` when the user wants the work to come back to this conversation, or `from` an earlier key to continue that step's session; that key must be among the steps this one waits for, directly or indirectly. When that session belongs to the same host, Claude Code and WorkBuddy continue in a copy of it; otherwise, and always for Codex and Cursor, the step starts a new session that reads the earlier steps' summaries and this conversation's hand-off.
- `profile`: `read_only` for review, analysis or questions; `workspace_write` when the step edits files or produces files such as slides. Cursor cannot be limited to reading, and the confirmation page tells the person so.
- `brief`: write for an Agent that has not seen this conversation.
  - `goal`: the outcome, not the steps.
  - `context`: why, and the decisions already made.
  - `done`: what already exists, such as the plan's path.
  - `openQuestions`: what is still undecided.
  - `paths`: the files that matter.
  - `acceptance`: how the step knows it is done.

Pass a `nonce` you generate for this call: about 16 random letters and digits, never reused or copied from an example.

For "plan here, Codex implements, back here to review, then WorkBuddy makes slides", after writing the plan:

```json
{
  "nonce": "<your new random value>",
  "nodes": [
    {"key": "implement", "host": "codex", "dependsOn": [], "mode": {"kind": "fresh"}, "profile": "workspace_write",
     "brief": {"goal": "Implement the plan in docs/export-plan.md", "context": "The user approved this plan.", "done": ["Plan written"], "openQuestions": [], "paths": ["docs/export-plan.md"], "acceptance": ["Tests pass"]}},
    {"key": "review", "host": "claude-code", "dependsOn": ["implement"], "mode": {"kind": "resume", "from": "origin"}, "profile": "read_only",
     "brief": {"goal": "Review the implementation against the plan", "context": "Codex implemented the plan written in this conversation.", "done": ["Implemented"], "openQuestions": [], "paths": ["docs/export-plan.md"], "acceptance": ["Every plan item checked"]}},
    {"key": "slides", "host": "workbuddy", "dependsOn": ["review"], "mode": {"kind": "fresh"}, "profile": "workspace_write",
     "brief": {"goal": "Make a short slide deck of what was built", "context": "For the team update.", "done": ["Implemented and reviewed"], "openQuestions": [], "paths": ["docs/export-plan.md"], "acceptance": ["A .pptx in the folder"]}}
  ]
}
```

## After dispatching

- On success, tell the person that the confirmation page opened, or give them `approvalUrl` when the result asks you to. The chain starts after they approve and your turn ends, and this computer shows a notification if a step fails or when the whole chain finishes. Then end your turn: do not do the dispatched steps yourself, wait for them, or dispatch again.
- `invalid_graph` or `validation`: fix the chain as the message says and call again with a new nonce.
- Any other error, such as `session_unavailable` or `handoff_disabled`: tell the person what the message says and stop. Do not try another way to run the steps.
- If the person rejects the chain, nothing runs. Do not dispatch it again unless they ask.
- When the person later asks how the work is going, call `task.status` with the `graphId` from the dispatch result, or without it to list every chain still waiting or running.
