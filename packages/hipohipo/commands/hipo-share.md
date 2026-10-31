---
name: hipo-share
description: Publish a fixed snapshot of this conversation and return its Hipo link
---

Share the current conversation using this plugin's native executable. Do not
read conversation files, reconstruct messages, or upload text through model tools.

For a retained operation, invoke `/hipo-share retry <operationId>`. Retry within
an ordinary mixed turn is refused; preserve that turn. Never recapture for retry.

For Cursor Desktop, the native before-submit Hook supplies `HIPO_SHARE_FROZEN`.
If its status is `frozen`, run exactly one Shell command:

```sh
"${CURSOR_PLUGIN_ROOT}/scripts/run.cmd" share-retry --host cursor --operation-id <operationId-from-HIPO_SHARE_FROZEN>
```

If the Hook reports failure, report that failure and stop. Never select another
conversation or fall back to a transcript. The operation is already frozen.

For Cursor CLI, where no Desktop Hook result is supplied, run exactly once:

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
