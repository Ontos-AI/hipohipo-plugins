---
name: hipohipo-login
description: Connect or reconnect Hipohipo in the browser
---

Use this plugin's `auth.status` to reuse valid authorization, then `auth.login`
to prepare and start or join sign-in. If MCP is unavailable or stale, continue
in this conversation with the installed plugin's `scripts/run.cmd auth-status`
and `scripts/run.cmd login` (use `sh scripts/run.cmd` in a POSIX shell).

Resolve the installed directory from this command's source or native inventory.
Pass the verified `--host` and preserve the active client's configuration
context. The plugin resolves or creates its own persistent instance: do not
search for or invent `--state-dir`. Healthy old instances stay in place; repair
can preserve damaged state and create a replacement requiring new consent.
If the active configuration is unknown, resolve it from host evidence; advanced
`--configuration-root` can select that verified profile. Do not inspect credentials.

Capture complete JSON and the real exit code; do not pipe these commands
through `head` or `tail`. `instance_identity_unresolved` or `inspect_error`
requires resolving the reported metadata, storage or service problem.

Normal browser login is recommended. Before CLI login, tell the user a browser
will open and give the host command enough execution time. `login` waits in the
foreground for authorization, with a default total budget of 600 seconds;
`--timeout-seconds <1..600>` includes startup, preparation, refresh and consent.
Choose a budget below the actual host tool limit and leave time to return the result. Wait for the same
running invocation, without a parallel login. Progress is on stderr; stdout is
one complete result.

Preparation advances for at most 30 seconds. `continue_setup` means repeat the
same login. MCP calls and continued device polling remain bounded to 30 seconds.
Exit zero can mean pending; only `authorized` confirms completion. Status calls
only observe. A preparation failure requires an explicit `runtime-retry` request.
Do not manually download/publish runtimes, remove locks or loop retries.
An explicitly rejected old credential is replaced once for this instance during
the current login request. New consent cancellation, denial or expiry requires
a new request; a service/storage/network error requires diagnosis.

Device mode (`login --device`) is an alternative for SSH or another computer.
Browser-open or callback-listener failure also falls back to device. The first
device result returns immediately after saving the authorization. Explain any
`fallbackReason`; show `deviceAuthorization.verificationUriComplete`, with
`userCode` and `verificationUri` as backup. The full link avoids code entry but
still requires code, account, Project and permission confirmation. A local
explicit device call tries to open it once; SSH/headless execution or a failed
browser launch returns the link instead. After approval, continue the same
instance's `login` to redeem the existing code. Do not issue another code or
reopen the browser. A successfully opened browser followed by denial, timeout or
a page error does not cause automatic fallback.

Confirm `authorized` for this same instance. Existing and read-only grants count;
Full access is required only for uploads. Check host MCP availability separately,
using supported enable/reload controls where available. CLI sign-in does not
establish MCP loading, and opening another conversation is not a login prerequisite.

A separately configured HTTP MCP has its own authorization. Independent
installations use separate grants; pending local history is retained across login
and logout. Never paste credentials into chat or configuration.
