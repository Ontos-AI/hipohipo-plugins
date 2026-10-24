---
description: Publish a fixed snapshot of this conversation and return its Hipo link
allowed-tools: Bash
argument-hint: [retry operation-id]
---

Native arguments: `$ARGUMENTS`. If they are exactly `retry <operationId>` for a
retained UUID, run the retry command below instead of the normal share command.
Do not interpolate an arbitrary argument string into the shell.

Run this exact Bash command once, after native command persistence. Do not use
dynamic preprocessing, override the environment, select a session, read files,
reconstruct conversation messages, or upload text through another tool:

```sh
"${CLAUDE_PLUGIN_ROOT}/scripts/run.cmd" share --host claude-code --session-id "${CLAUDE_SESSION_ID}"
```

The native command substitutes the plugin root, current session identity and
persistent plugin data directory. Keep the exact state argument so the command
reads the same native Hook binding.
The executable binds the corresponding native tool Hook, reads the selected
branch and freezes original user messages and visible replies before login or
upload. Wait for the previous reply to finish before sharing.

Return the published `shareUrl` only after the executable confirms publication.
If login is required, use this plugin's existing login flow. Retain the returned
operation ID, then invoke `/hipohipo:share retry <operationId>` and run:

```sh
"${CLAUDE_PLUGIN_ROOT}/scripts/run.cmd" share-retry --host claude-code --session-id "${CLAUDE_SESSION_ID}" --operation-id <returned-operationId>
```

Do not repeat `share` to recover from login or network errors. Report failures
truthfully; a tool call or a frozen snapshot alone is not publication.

Retry within an ordinary mixed conversation turn is refused; retain its ordinary
user text and unrelated answers. Never mark that mixed turn as a sharing control.
