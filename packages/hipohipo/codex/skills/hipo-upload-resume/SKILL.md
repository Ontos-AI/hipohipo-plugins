---
name: hipo-upload-resume
description: Resume Hipo file uploads in this conversation before the pause ends
disable-model-invocation: true
---

Submit this skill on its own with `$hipohipo:hipo-upload-resume`. The Hipohipo
UserPromptSubmit hook handles it. It resumes Hipo file uploads in this conversation and blocks the message,
so it does not reach the model.

If this skill reaches the model, ask the user to review and trust the
Hipohipo hook in `/hooks`. Report that uploads were not resumed.
