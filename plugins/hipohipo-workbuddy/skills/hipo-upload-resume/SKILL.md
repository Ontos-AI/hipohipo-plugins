---
name: hipo-upload-resume
description: Resume Hipo file uploads in this conversation before the pause ends
disable-model-invocation: true
---

Type `/hipo-upload-resume` on its own in the current local conversation. The
Hipohipo UserPromptSubmit hook handles it. It resumes Hipo file uploads in this conversation and blocks the message,
so it does not reach the model.

If this command reaches the model, ask the user to type the command directly
and enable or reload the Hipohipo hook. Report that uploads were not resumed.
