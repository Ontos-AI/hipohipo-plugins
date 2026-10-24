---
name: hipo-share
description: Publish a fixed snapshot of this local WorkBuddy conversation
disable-model-invocation: true
---

For a retained operation, invoke `/hipo-share retry <operationId>`. If this
registered invocation has those retry arguments, run the executable with
the retry command below instead of `share`.
Retry within an ordinary mixed turn is refused; preserve its ordinary text and
unrelated replies. Never recapture the conversation for a retry.

Share this current local WorkBuddy Desktop conversation. Wait for the previous
reply to finish. Cloud conversations and local Desktop forks are outside this
release scope.

Resolve this installed plugin's root from the native Skill base directory
(two directories above this skill directory), then run one Bash call:

```sh
"<installed-plugin-root>/scripts/run.cmd" share --host workbuddy
```

The native Skill loader substitutes its persistent plugin data directory above.
Keep that exact state argument so the command reads its native Hook binding.
Use the native environment without session arguments or environment overrides.
Do not read files, reconstruct conversation messages, call MCP uploads or send
conversation text through another tool. The executable binds the native current
request to its corresponding transcript occurrence and freezes the selected
branch before login or upload.

Return `shareUrl` only when the executable confirms publication. If login or
network access fails, retain the operation ID, complete this plugin's existing
login flow if needed, then invoke `/hipo-share retry <returned-operationId>` and run:

```sh
"<installed-plugin-root>/scripts/run.cmd" share-retry --host workbuddy --operation-id <returned-operationId>
```

Do not repeat `share` for a retry. Report failure truthfully and never claim a successful link from an
acknowledgement or a local snapshot alone.
