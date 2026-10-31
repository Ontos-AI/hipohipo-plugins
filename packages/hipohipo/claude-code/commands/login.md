---
name: login
description: Connect or reconnect Hipohipo in the browser
---

Use this plugin's `auth.status` first and reuse `authorized`. Call `auth.login`
to prepare and start or join sign-in. If MCP is unavailable or stale, continue
in this conversation through the installed `${CLAUDE_PLUGIN_ROOT}/scripts/run.cmd`
with `auth-status` and `login` (invoke the script with `sh` in POSIX/Git Bash).

Resolve this installed package from native installation/launch metadata and
pass `--host claude-code`, preserving the active configuration environment.
The plugin manages instance paths; do not find or supply `--state-dir` for normal
login. Healthy existing state is reused. Unrecoverable old state is preserved
while a replacement can continue through fresh user consent. If the profile is
unknown, establish it from current host evidence or explicitly select the
verified configuration with `--configuration-root`; never inspect credentials.

Tell the user before opening the browser, then wait for the same login invocation
with a budget below the host tool's actual limit. Follow returned actions and
logs as evidence, adapting to actual errors; no fixed help/status sequence is
required. Reuse pending consent; status only observes. After denial, cancellation
or terminal failure, wait for a new login request. Device mode is available when
needed and its returned full link and public code must be shown immediately.

Confirm same-instance `authorized`; existing and read-only grants count.
Full access is required only for uploads. Report host MCP access separately,
using supported enable/reload controls. CLI sign-in does not prove MCP loading.
Other host/profile instances have separate grants. Never paste credentials into
chat or configuration. Local history is retained across login and logout.
