---
name: hipo-upload-pause
description: Pause Hipo file uploads in this conversation (two hours by default)
disable-model-invocation: true
---

Type `/hipo-upload-pause` on its own in the current local conversation. The
Hipohipo UserPromptSubmit hook handles it. It pauses Hipo file uploads in this conversation and blocks the message,
so it does not reach the model.

If this command reaches the model, ask the user to type the command directly
and enable or reload the Hipohipo hook. Report that uploads were not paused.
