---
description: Pause Hipo file uploads in this conversation (two hours by default)
disable-model-invocation: true
---

The Hipohipo UserPromptSubmit hook handles the exact `/hipohipo:upload-pause`
command. It pauses Hipo file uploads in this conversation and blocks the message,
so it does not reach the model.

If this command reaches the model, ask the user to enable or reload the
Hipohipo hook. Report that uploads were not paused.
