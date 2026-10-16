---
name: login
description: Connect or reconnect Hipohipo in the browser
---

Call this plugin's `auth.login` when available. Otherwise run:

```sh
"${CLAUDE_PLUGIN_ROOT}/scripts/login.sh"
```

The command starts login and returns while the user completes browser
authorization. Full access is required for uploads. After login, business tools
become available and `auth.status` is hidden; use business tools directly.
Use `auth.status` only for an incomplete login or authorization problem when
it remains available. Do not poll. Starting login is not evidence of success.
If tools do not refresh, reconnect this plugin's MCP. Do not repeatedly retry
without the user's request or use a separately configured HTTP MCP's
authentication action.

The script uses this installation's persistent state directory. Pending history
is retained and uploads under current authorization. Other Hipohipo plugin
clients may share the system-stored grant. Never paste tokens into chat or read
the credential store to perform login.
