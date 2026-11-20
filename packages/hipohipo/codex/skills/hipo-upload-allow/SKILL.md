---
name: hipo-upload-allow
description: Upload the files your last over-limit instruction named, past the Hipo upload limit
disable-model-invocation: true
---

Submit this skill on its own with `$hipohipo:hipo-upload-allow`. The Hipohipo
UserPromptSubmit hook handles it. It lifts the Hipo upload limit for this turn and adds the paths the last
instruction over the limit named to the context. Upload the uploadable files under those paths
with the document-capture skill. When the Hipo context says nothing is waiting
or uploads are paused, tell the user and upload nothing.

If no Hipo context about this skill is present, ask the user to review and trust the
Hipohipo hook in `/hooks`. Upload nothing.
