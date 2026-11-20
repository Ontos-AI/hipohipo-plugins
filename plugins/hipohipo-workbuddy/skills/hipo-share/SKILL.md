---
name: hipo-share
description: Publish a fixed snapshot of this local WorkBuddy conversation
disable-model-invocation: true
---

Type `/hipo-share` on its own in the current local conversation. For a retained
operation, type `/hipo-share retry <operationId>`. The Hipohipo UserPromptSubmit
hook selects the current branch and publishes the snapshot.

If the share request reaches the model, ask the user to type the command
directly and enable or reload the Hipohipo hook. Report that no share was published.
