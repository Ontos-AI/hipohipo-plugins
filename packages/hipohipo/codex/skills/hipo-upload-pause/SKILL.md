---
name: hipo-upload-pause
description: Pause Hipo file uploads in this conversation (two hours by default)
disable-model-invocation: true
---

Submit this skill on its own with `$hipohipo:hipo-upload-pause`. The Hipohipo
UserPromptSubmit hook handles it. It pauses Hipo file uploads in this conversation and blocks the message,
so it does not reach the model.

If this skill reaches the model, ask the user to review and trust the
Hipohipo hook in `/hooks`. Report that uploads were not paused.
