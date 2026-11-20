---
name: hipo-upload-resume
description: Resume Hipo file uploads in this conversation before the pause ends
---

The Hipohipo before-submit Hook handles the exact `/hipo-upload-resume` command.
It resumes Hipo file uploads in this conversation and blocks the message, so
it does not reach the model.

If this command reaches the model, tell the user to enable or reload the
Hipohipo Hook. Report that uploads were not resumed.
