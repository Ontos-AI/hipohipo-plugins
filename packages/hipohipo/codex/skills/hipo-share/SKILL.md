---
name: hipo-share
description: Publish a fixed snapshot of the current Codex CLI conversation
disable-model-invocation: true
---

For a retained operation, invoke `$hipohipo:hipo-share retry <operationId>`. If this
registered invocation has those retry arguments, run the executable with
`share-retry --host codex --operation-id <operationId>` instead of `share`.
Retry within an ordinary mixed turn is refused; preserve its ordinary text and
unrelated replies. Never recapture the conversation for a retry.

This user-invoked skill shares original user messages and visible Agent replies
from the current Codex CLI thread. Codex Desktop is outside this release scope.
Wait for the previous reply to finish before sharing.

Resolve this installed plugin's root from this skill's native source location:
remove the suffix `codex/skills/hipo-share/SKILL.md` in the unified package, or
`skills/hipo-share/SKILL.md` in a standalone Codex package. Start exactly one publisher process using that absolute plugin root:

```sh
"<installed-plugin-root>/scripts/run.cmd" share --host codex
```

Wait for that process to finish. When using `exec_command`, set
`yield_time_ms: 30000` for the initial call and retain its complete result,
including `session_id`. If a session is still running, poll that same session
with `write_stdin` until it exits. Do not discard the session handle by printing
only `result.output`, and do not start another sharing process while it runs.
If orchestration itself yields a running cell, wait for that cell as well.

The executable emits an intermediate `status: frozen` record before network
work. This confirms the local retry snapshot only; it is neither publication
nor a reason to suggest retry while the process is running. Inspect the complete
output after exit. When its final record has `status: published`, return that
record's `shareUrl` to the user. Suggest retry only after an actual failed exit
or an explicit authorization/network failure, preserving the same operation ID.

Use the native environment. Do not supply a thread ID, change environment
variables, read files yourself, reconstruct messages or upload conversation
text through another tool. The executable binds the actual native tool Hook,
reads history through read-only native APIs and freezes bytes before upload.

Return `shareUrl` only after publication succeeds. On login or network errors,
retain the operation ID, complete this plugin's existing login flow if needed,
then invoke `$hipohipo:hipo-share retry <returned-operationId>`. Never run `share` again for a retry. Report failure if
the executable fails, and never invent a successful link.
