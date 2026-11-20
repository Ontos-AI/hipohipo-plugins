---
name: hipo-share
description: Publish a fixed snapshot of the current Codex conversation
disable-model-invocation: true
---

Submit this skill on its own with `$hipohipo:hipo-share`. For a retained
operation, use `$hipohipo:hipo-share retry <operationId>`. The Hipohipo
UserPromptSubmit hook selects the current branch and publishes the snapshot.

If this skill reaches the model, ask the user to review and trust the
Hipohipo hook in `/hooks`. Report that no share was published.
