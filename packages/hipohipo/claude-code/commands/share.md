---
description: Publish a fixed snapshot of this conversation and return its Hipo link
argument-hint: [retry operation-id]
---

The Hipohipo UserPromptSubmit hook handles the exact `/hipohipo:share`
command and publishes a snapshot of the current branch through a local
status link. Open that link within two minutes to reach the published share.
When Hipo supplies a retry command, use the same operation ID.

If this command reaches the model, ask the user to enable or reload the
Hipohipo hook. Report that no share was published.
