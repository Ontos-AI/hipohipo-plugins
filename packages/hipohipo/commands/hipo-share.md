---
name: hipo-share
description: Publish a fixed snapshot of this conversation and return its Hipo link
---

Share the current conversation using this plugin's native executable. Do not
read conversation files, reconstruct messages, or upload text through model tools.

For a retained operation, invoke `/hipo-share retry <operationId>`. Retry within
an ordinary mixed turn is refused; preserve that turn. Never recapture for retry.

Cursor Desktop handles this command directly in the installed before-submit
Hook. If a Desktop conversation reaches the model with this command, tell the
user to enable or reload the Hipohipo Hook. Do not attempt a separate publish.

In the native Cursor CLI, run exactly once:

```sh
"${CURSOR_PLUGIN_ROOT}/scripts/run.cmd" share --host cursor
```

If this registered Cursor CLI invocation includes `retry <operationId>`, run
exactly once instead:

```sh
"${CURSOR_PLUGIN_ROOT}/scripts/run.cmd" share-retry --host cursor --operation-id <operationId>
```

Cursor substitutes the installed plugin directory in these commands before
providing them. Use that path directly without searching for plugin directories.

Use the native Shell environment without session arguments or environment
overrides. The executable selects the current native conversation and freezes
the snapshot before authentication or network work. Wait for the previous reply
to finish before sharing. Native Shell approval may be required.

Return only the published `shareUrl` after success. On login or network failure,
retain the returned operation ID, complete the existing Hipo login flow when
needed, and invoke `/hipo-share retry <same-operationId>`.
Never run `share` again as a retry or claim success without a published URL.
