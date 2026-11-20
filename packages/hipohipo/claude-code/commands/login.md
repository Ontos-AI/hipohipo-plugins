---
name: login
description: Connect or reconnect Hipohipo in the browser
---

Use this plugin's `auth.status` first and reuse `authorized`. Call `auth.login`
to prepare and start or join sign-in. If MCP is unavailable or stale, continue
in this conversation through the installed `${CLAUDE_PLUGIN_ROOT}/scripts/run.cmd`
with `auth-status` and `login` (invoke the script with `sh` in POSIX/Git Bash).

Resolve this installed package from native installation/launch metadata and
pass `--host claude-code`. The program resolves host locations and persistent
state; do not find or supply configuration roots or `--state-dir` for normal
login. Profiles of the same host share authorization and local account selection.
Cursor uses the Claude Code host area. Each Hipo account retains its own history
and upload queue. Switching accounts selects that account's retained data.
Never inspect credentials.

Tell the user before opening the browser, then wait for the same login invocation
with a budget below the host tool's actual limit. Follow returned actions and
logs as evidence, adapting to actual errors; no fixed help/status sequence is
required. Reuse pending consent; status only observes. After denial, cancellation
or terminal failure, wait for a new login request. Device mode is available when
needed and its returned full link and public code must be shown immediately.

Confirm same-instance `authorized`; existing and read-only grants count.
Full access is required only for uploads. Report host MCP access separately,
using supported enable/reload controls. CLI sign-in does not prove MCP loading.
Other local host areas and independently authorized HTTP MCP connections have
separate grants. Never paste credentials into chat or configuration. Local history
remains with its Hipo account across login and logout.
