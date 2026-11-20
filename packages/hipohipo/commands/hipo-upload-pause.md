---
name: hipo-upload-pause
description: Pause Hipo file uploads in this conversation (two hours by default)
---

The Hipohipo before-submit Hook handles the exact `/hipo-upload-pause` command.
It pauses Hipo file uploads in this conversation and blocks the message, so
it does not reach the model.

If this command reaches the model, tell the user to enable or reload the
Hipohipo Hook. Report that uploads were not paused.
