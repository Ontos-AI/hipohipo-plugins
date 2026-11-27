---
name: hipohipo-status
description: Check whether Hipohipo is connected
---

Use this command only when the user explicitly asks whether Hipohipo is
connected. Read local authorization with `auth.status`. If MCP cannot check
authorization, run `scripts/run.cmd auth-status --host HOST` from this
command's installed plugin directory, using the active host (`cursor` in
Cursor). In a POSIX shell, use `sh scripts/run.cmd`.

Reply in the user's language with only the connection result and the login
instruction when needed.

- If the top-level status is `authorized`, say Hipohipo is connected.
- If authorization was checked and Hipohipo is not connected, say it is
  disconnected and tell the user to run `/hipohipo-login` to connect.
- If neither method can check authorization, say the connection could not be
  checked.

Do not start login, query capture or runtime diagnostics, or include raw tool
output or metadata in the reply.
