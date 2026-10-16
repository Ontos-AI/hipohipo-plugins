---
name: hipohipo-login
description: Connect or reconnect Hipohipo in the browser
---

Call this plugin's `auth.login` tool. It starts login and returns while the user
completes authorization in the browser. Explain that Full access is required
for uploads. After login, business tools become available and `auth.status`
is hidden; use business tools directly without a status preflight. If login
is incomplete or fails, use `auth.status` only when it remains available.
Never claim success just because the flow started. Do not poll or repeatedly
retry a failed flow without the user's request.

If the tool is unavailable, run `scripts/run.cmd login` from this command's
installed plugin directory. Resolve that directory from the command's source
location, without searching credentials or old conversations. If the installed
path is unavailable, direct the user to the login wrapper in their extracted
package. Use `scripts/run.cmd auth-status` to check the result. In Codex, append
`--host codex` to both commands: `scripts/run.cmd login --host codex` and
`scripts/run.cmd auth-status --host codex`.

Reconnect this plugin's MCP only if the client does not refresh its tools after
login. A remote HTTP MCP's authentication action is a separate login flow.
Reconnecting preserves pending history, which uploads under current
authorization. Other Hipohipo plugin clients may share the system-stored grant.
Never paste credentials into chat or configuration.
