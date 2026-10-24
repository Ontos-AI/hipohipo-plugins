# Support and diagnostics

Report issues in [Ontos-AI/hipohipo-plugins](https://github.com/Ontos-AI/hipohipo-plugins/issues).
Include the plugin version, client and client version, OS/CPU, installation
route, safe `status` output, and a minimal synthetic reproduction. Do not attach
credentials, SQLite files, real transcripts, or screenshots with private content.

## Cursor display names

The plugin card uses **Hipo Hipo** from version 0.6.14. Its installation
identifier remains `hipohipo`. Refresh the marketplace and update through the
original installation route if the card still shows `hipohipo`.

The **Ontos Ai Hipohipo Plugins** section heading is a separate Cursor
marketplace display name. Open **Manage**, select that marketplace, edit its
marketplace name to **Hipo Hipo**, and save. Cursor stores this display name in
its marketplace management record; the plugin manifest cannot override it.
Keep the repository URL and identifiers unchanged. Reinstalling the plugin,
renaming its identifier or clearing credentials is unnecessary.

## Connection and login

### Native installation errors

An error can occur after package state was written, even with exit zero. Check
native inventory and the installed manifest first. If the target version is
installed and enabled, continue loading and sign-in instead of reinstalling.
For a host lock or file-operation failure, use the native plugin manager. Some
WorkBuddy layouts expose Skills → Installed → plugin details → Update; use the
actual available UI and refresh a changed marketplace source when needed. A Skill
upload does not install the complete plugin. Retain the original failure and
explain the action if only the user can perform it. Do not delete locks, edit
private registries, disable protections or rerun outside the guarded host.

PATH absence does not prove the app is missing. Resolve the current app's bundled
CLI/runtime from installation metadata, retaining its profile. Healthy setup
does not require private database queries or reading implementation scripts to
infer parameters. Do not repeat unsupported commands. On timeout stop only this
invocation's child tree, preserving the actual cause and next action.

### Login and runtime preparation

- **Program download failed or is still preparing:** `runtime_status` observes
  state without starting work. Operations start or join a shared attempt with a
  600-second deadline. A pending response means the operation was not executed.
  After failure, request `runtime_prepare` explicitly, or run `runtime-retry`
  using the installed launcher. Neither status nor a reconnect retries a
  terminal failure. Use the local log path for diagnostics.

- **Tools are missing:** distinguish a disabled MCP, a startup failure, an unloaded
  or outdated package, and an unknown host state. Current packages expose their
  catalog before preparation and login; a slow download does not by itself
  explain missing tools. Check native controls and startup logs. Do not infer
  the cause from a missing tool list.
- **Cursor says Disabled:** enable Hipohipo's MCP in Customize. A remembered
  disabled setting can survive replacement of the plugin directory; reinstalling
  does not establish that the switch is enabled. The setting alone cannot show
  who changed it or whether uninstall caused it. Use supported controls, not
  private database edits. Rediscover tools in the current conversation first.
- **MCP cannot load in this conversation:** use the installed package's `login`
  and `auth-status` with the exact same host/profile/data binding. Continue
  sign-in here, then check MCP separately. A new conversation or app restart is
  needed only when the host's supported loading flow requires it. Do not register
  another MCP or change host trust policy to work around unavailable tools.
- **CLI setup is pending:** `login` prepares and then signs in; `runtime-prepare`
  only prepares. Preparation advances for at most 30 seconds; ordinary CLI browser
  login stays in the foreground until completion within its total budget (default
  600 seconds, configurable with `--timeout-seconds <1..600>`). `continue_setup`
  means repeat the same command; `complete_browser_consent` means finish the
  existing consent and continue login. Exit code zero also covers pending work;
  only `authorized` confirms sign-in. `runtime-status` and `auth-status` never
  initiate preparation or login. Terminal setup failures return nonzero;
  observing a failed state returns zero. Inspect `lastErrorCode`, `logPath`,
  `attemptId`, `phase`, `downloadedBytes` and the attempt deadline. Each foreground
  call advances the same attempt; it does not require a surviving background
  process. Partial files and the deadline survive interruption. A pending result
  means repeat `login` or `runtime-prepare`, not `runtime-retry`. Retain diagnostic
  stdout/stderr and the command's actual exit status before summarizing or filtering
  displayed output. A filter's exit status is not the command's result.
- **CLI and MCP disagree about login:** use the same installed package, `--host`
  and verified active configuration environment. The plugin resolves the shared
  instance binding; do not find or guess `--state-dir`. Preserve `CODEX_HOME`,
  `CLAUDE_CONFIG_DIR`, `WORKBUDDY_CONFIG_DIR`/`CODEBUDDY_CONFIG_DIR` and explicit
  Hipo overrides when present. Native plugin data is only a legacy-discovery hint.
  Use `--configuration-root` for a profile verified from host evidence when needed.
  Status observes; login repairs recoverable metadata or preserves old state and
  creates a separately authorized replacement. `hasPreservedState` distinguishes
  that result from recovered historical work. Keep `diagnosticId`, `journeyId`
  and `logPath` for support; never inspect credentials to identify the instance.
- **The browser did not open or the callback listener failed:** normal login
  automatically returns `authorizationMode: device` with `fallbackReason`
  (`browser_open_failed` or `callback_listener_failed`). Show the returned
  `deviceAuthorization.verificationUriComplete` immediately, plus `userCode`
  and `verificationUri` as backup. The full link contains only the public code.
  The user must still confirm the code, account, Project and permissions.
  Explicit `login --device` is also available, retaining the same host/root/state.
  A local desktop tries to open the full link once; SSH/headless execution or
  a failed browser launch returns it without another attempt. Failure to open
  the device page does not invalidate the saved code. Unsupported device service
  or creation failure is an inspection error, not an endless mode switch. The plugin
  polls for completion on its own machine; no callback needs to reach that
  machine from the browser. Never paste a stored access token or refresh token.
  A failed or cancelled attempt requires an explicit new login request.
- **Credential manager unavailable:** the plugin uses a private filesystem
  fallback. If that location is not writable, fix its permissions and retry
  login. Never print or paste the stored tokens.
- **A manual command shows a different queue:** preserve the active host/profile
  and any intentionally chosen state override. The default CLI, MCP and Hooks
  share one binding. Old background work retains its original instance; replacing
  a damaged instance does not transfer its history to the newly selected account.

### Confirm the current connection

After completed sign-in or verified authorization reuse, check the current MCP.
If tools are missing or still run the previous version, wait once for 30 seconds,
rediscover tools and check again. Skip the wait when already loaded; it does not
replace a pending setup action. If still unloaded, use the client flow below.

WorkBuddy acceptance confirmed normal app quit/reopen followed by resuming the
installation conversation. A new conversation retained an old shared connection;
the CLI's suggested `/reload-plugins` was absent from the desktop command menu and
did not reload it. Do not require a search for an unverified reload/reconnect control.
For Cursor local plugins, the [official loading guide](https://cursor.com/docs/plugins#test-plugins-locally)
documents `Developer: Reload Window` or a normal restart. Use that command only
when exposed in the current interface; otherwise restart normally. Enable MCP
only when disabled. Claude Code and Codex use their current documented loading
flow, continuing in a fresh client session when the existing session cannot load it.

Resume the installation conversation after restart. When another conversation is
required, provide a short follow-up carrying the installed target version and
completed steps. Compare the responding MCP version before confirming readiness.
Reuse authorization; do not reinstall, repeat login, repeat the loading wait,
clear state or change host protection solely to load the plugin.

Use the installed manifest for the package version and current MCP status for
the responding process's `serverVersion`. Verified `host` and `localInstanceId`
identify its local instance; `instanceId` identifies the authorization binding.
`runtimeVersion` may describe a preparation target rather than a running process.
CLI status establishes CLI state, not MCP loading. Missing legacy fields leave
that detail unconfirmed; they do not justify discarding a valid grant or forcing
a new login. Retain diagnostic IDs and logs when results disagree.

### Preparation and rejected credentials

Preparation owns retained kernel lock files; release occurs when the owner exits.
Old directory locks are ignored by the new protocol and can remain untouched.
Directory deletion is not required to prepare, retry or write diagnostics. Do not
rename/delete locks, disable a host safety shim, manually download a runtime or
invoke internal publication commands to work around an error.

Downloads continue from the stored offset only after a matching HTTP 206 range
response. `download_resume_unsupported` and `download_range_invalid` are terminal;
inspect the download service or intermediary before an explicit retry. Network
failures are counted across calls (at most three); a normal 30-second call expiry
is not a network failure. An attempt's 600-second limit never resets during
continuation. Archive verification, executable verification and atomic publication
must finish before `ready` is reported. Publication shares the call's remaining
wait budget. `inspect_error` identifies identity, local storage, permission or
service failures requiring diagnosis; it is not a prompt to retry indefinitely.

WorkBuddy prefers the pinned mainland mirror; other hosts prefer the primary
source. One network fallback preserves the same partial artifact, deadline and
cumulative failure count. The persisted source survives later calls. Range and
integrity failures stop instead of trying another source. A stalled transport
can time out before the call budget, while healthy slow progress can continue.

After timeout or network failure, an explicitly requested `runtime-retry` creates
a new attempt and can resume the retained archive when version, platform, full
digest and size match. The new attempt has its own bounded deadline and network
budget. Integrity/Range failures, unsafe files and unknown or mismatched artifact
identity are not reused. Final digest verification still gates publication; no
manual downloads, lock cleanup or timeout override is needed.

Explicit login reuses a valid grant and refreshes an expired one. Only
`invalid_grant`/`invalid_client` invalidates the old credential and continues once
to new authorization. An unmigrated instance records
`hasRejectedLegacyCredential` and stops reading or updating the shared legacy
credential; that shared credential remains available to other instances. A
migrated instance never falls back to it. Status remains observational. New
consent denial/cancellation/expiry returns `request_login_retry`; network,
credential-store and service errors return `inspect_error` without replacing a
valid grant. Do not clear shared credentials to repair one installation.

Device creation persists continuation and returns immediately without polling.
Later calls poll for at most 30 seconds, limited by the call budget and original
code expiry. They do not open another page or issue another code.
For device login, a successful browser page confirms consent, not local token
redemption. Repeat `login` with the same instance arguments: it continues the
original code in bounded foreground calls after the previous process exits, preserving
expiry and polling backoff. `auth-status` only reads local state; an unchanged
`updatedAt` does not prove the server is still pending. If the code has expired,
wait for a new explicit login request. Private continuation records and tokens
must never be attached to bug reports.

A stopped login from a version that did not save private continuation cannot
recover its original device code. `authorization_interrupted` explains this
case: wait for the code to expire, then explicitly request login again. Discarding
it sooner requires an explicit logout request; do not clear credentials or start
another flow automatically. Service or storage errors preserve recoverable device
state and return `inspect_error`; after resolving the cause, continue `login`
with the same instance arguments.

Explicit CLI browser login owns its callback listener in the current process.
Announce the browser before the call, then wait for that invocation. WorkBuddy
should use `login --timeout-seconds 570` with a 600-second tool timeout. If a host
has a smaller limit, reduce the CLI budget and leave return time; do not change
host defenses. One deadline starts at the outer launcher and covers preparation,
refresh and consent. Preparation has its own 30-second slice; completing it does
not restrict subsequent browser consent to that slice. A joined consent retains
its original deadline. Timeout returns nonzero and `request_login_retry`; it does
not silently switch to device. Successful browser launch followed by page error,
denial or cancellation also does not trigger fallback. If the host kills the
command before its deadline, inspect that interruption rather than claim consent
is still running. MCP login and Hooks keep their existing execution model.

For browser-callback login, persisted pending status alone does not mean consent
is still running. An explicit login call checks kernel ownership, joins a live
helper or replaces one interrupted attempt. A delayed helper cannot reuse
an obsolete reservation. If the replacement also exits, inspect the reported
error before another explicit request; do not loop or launch parallel logins.

### Resolve the CLI instance

Read the installed package's MCP launch definition and the active host's native
installation/profile metadata. These inputs describe different directories:
the plugin directory contains `hipohipo`/`hipohipo.cmd`; the configuration root
identifies the host profile; the state directory contains Hipohipo's local data.
Do not substitute the package/cache directory for either of the latter two.

| Host argument | Configuration-root evidence |
| --- | --- |
| `cursor` | Active Cursor launch metadata, including `--user-data-dir`; when supplied by that launch, `VSCODE_PORTABLE` plus `user-data`, or `VSCODE_APPDATA` plus `Cursor`. |
| `workbuddy` | `WORKBUDDY_CONFIG_DIR` or `CODEBUDDY_CONFIG_DIR` supplied by the active app. If both exist, they must resolve to the same directory. |
| `codex` | The active app's `CODEX_HOME` or verified native profile metadata. |
| `claude-code` | The active app's `CLAUDE_CONFIG_DIR` or verified native profile metadata. |

An existing `plugin-instance.json` is non-secret metadata: its `host`,
`configurationRoot` and `stateDirectory` can confirm an already resolved
installation. Use that exact state directory, not a newly constructed sibling.
For a fresh instance, preserve the verified MCP data argument/environment,
including WorkBuddy's `CODEBUDDY_PLUGIN_DATA` or Claude's `CLAUDE_PLUGIN_DATA`.
Absence of an environment variable is not evidence that a default profile is
active. If metadata is still missing or conflicting, report which binding is
unresolved and pause login only; retain completed installation work.

## Rules and memories import

Use the Project's connection manager to import eligible user-level sources.
Each app/configuration instance has its own connection and short instance label.
Imports require an active independent connection with write permission. If the
selected older installation needs authorization, the manager waits for that
instance to prepare the existing Allow flow; no files are read while waiting.
An expired or cancelled request does not start later in the background.

All connections in a Project share its one active import slot. Wait for the
current task to settle before requesting another. Finished-file counts do not
measure Memory output: a successfully processed file can produce no Memory,
and source coverage can remain incomplete. Check the displayed results and
Evidence for the original source and import task.

An import waiting for WorkBuddy resumes when Hipohipo actually runs in a
WorkBuddy task. Opening the desktop alone does not establish availability.
Already submitted work can continue on Hipo while the plugin is absent.

## Conversation capture

- **No history is collected:** enable plugin Hooks and use a local Agent
  conversation. Start a new conversation after loading the plugin. Cursor may
  not attach newly loaded Hooks to an already-running session. Codex Hook
  settings depend on the client version; enable and trust the packaged Hooks
  through the client before testing capture.
  Claude Code on Windows needs its supported command shell, such as Git Bash.
- **Switching chats did not upload:** chat switching and window closing do not
  reliably signal session completion. Hooks trigger checks for unread messages;
  `sessionEnd` is not required. Later activity retries pending requests.
- **Pending or paused uploads:** use the bundled `auth-status` and `status`
  commands to diagnose authorization, network errors, and write permission.
  Reconnect with Full access when required. Logout does not disable collection
  or erase pending history; disable Hooks to stop collecting.
- **Capture remains pending while uploads succeed:** `pendingParts` and
  `pausedParts` describe actual upload work. `pendingCaptureEvents` counts
  retained Hook receipts, partitioned into `waitingForSourceEvents` (no supplied
  transcript path), `awaitingConfirmationEvents` (Hook correspondence is not
  yet established), and `recoveryEvents` (retained source/freshness evidence).
  These are event counts, not missing-message counts. `recoveryEvents` is the
  retained-Hook source/freshness category; `recoverySources` separately counts
  durable source-recovery tasks, including tasks whose Hooks are reconciled.
  `followUpSources` counts supplied sources retained for possible late writes
  after close, interruption, or error. A handled notification can retain this
  follow-up; it does not itself establish missing messages. Follow-up survives
  restart and tentative-text expiry, and runs on later plugin activity without
  a permanent background process. There is no deadline-based abandonment.
  Recovery continues from previously supplied paths without requiring another
  Hook. Do not add source counts to event counts. `queuedMessageVersions`
  counts versions durably handled by the local queue, including explicit
  truncation outcomes; `pendingMessageVersions` counts verified text that still
  lacks a representable user association. Continuous Codex raw history can
  advance across context compaction; only incomplete, sparse or unaligned
  observations retain the reliable full-history `offset`. A missing path
  requires later host evidence; the plugin does not discover other histories.
- **An older completion remains unconfirmed:** Claude requires an explicit
  native `prompt_id` for older-reply confirmation. Older clients that omit it
  do not gain an inferred association from the newest prompt. Cursor needs a
  previously corroborated `beforeSubmitPrompt` generation/prompt association;
  repeated prompts, reused generation IDs and rewritten anonymous sources
  remain conservative. A text-free Cursor Stop additionally requires its
  observed successful terminal record. Updated status does not imply the
  installed host delivers these fields; verify the affected client version.
- **Upload accepted but no memory:** admission and extraction are separate.
  Extraction is asynchronous and can fail or produce no reusable memory. Use
  the available Memory tools to check actual state instead of assuming success.

## Sharing a conversation

Use the sharing command from the conversation you intend to share. The helper
requires native session and selected-branch evidence; it refuses uncertain
history instead of guessing another session or uploading a file tail.

- **Cursor Desktop immediately after edit/resubmit rewind:** this case remains
  unaccepted. The retained candidate attempt returned
  `share_generation_in_progress`; the guard remains in place.
- **WorkBuddy command selection:** the accepted entry is fully typed
  `/hipo-share`. Its `@skill` picker can pass unresolved placeholders and return
  `share_binding_missing`; that path is unreliable.
- **WorkBuddy Desktop fork:** local Desktop fork is unsupported. A bundled CLI
  or cloud fork is a separate capability.
- **Claude Code:** the latest package lifecycle round was skipped after earlier
  provider quota/access failures. Earlier acquisition results do not establish
  acceptance of this release candidate.
- **Interrupted upload:** use the returned retry instruction in the same host
  and account. Retry retains the frozen original snapshot. An account change or
  an unrelated ordinary turn can prevent retry in the old command context.

The 2026-10-22 native lifecycle results belong to unpublished `0.6.26`
candidates. They do not establish fresh native acceptance of `0.6.30`, production
server availability, publication or an installed-client upgrade.

## Documents and receipt updates

- **No document confirmation form:** saving is now chosen during connection
  authorization. Proactive saves use `source.create_background`, which is hidden
  without verified background-save permission and write access. Refresh the tool
  list after authorization. A missing or denied tool means skip proactive
  saving; do not use `source.create` as a substitute. Explicit save requests
  continue to use `source.create`.
- **Source parsing failed:** report the original Source and error. Do not create
  another Source using a different upload mode merely to repeat a terminal parse
  failure. `knowhere_http_409` can mean parsing admission failed even when byte
  upload succeeded.
- **No response after a receipt update:** the plugin forwards updates for
  subscribed MCP receipts, but the client controls subscription, resource
  rereading, and whether another Agent turn runs. A receipt update is not a
  promise of automatic continuation. Hook uploads do not have MCP receipts.

## Platforms, updates, and removal

The packages provide native programs for macOS, Linux and Windows on x64 and
ARM64. Conversation capture requires a local client; Cursor Cloud Agent capture
is not included. Each client has a separate installation entry; use its own package.

Update through the original route and restart or reload. Keep one Hipohipo
entry enabled in each client. Remove a legacy platform-specific entry before
installing the unified `hipohipo` entry. Renaming the entry may change its data
directory; the old queue is retained but is not automatically moved. Do not
remove state or revoke access solely to update.

For low-bandwidth networks, use the client-specific archives from
[Releases](https://github.com/Ontos-AI/hipohipo-plugins/releases), verify the
matching checksum file, and follow that client's local-plugin installation
instructions. Cursor's extracted package also provides `hipohipo install`.
Local Cursor installation keeps versioned executables; close the client and
plugin processes before deliberately removing old local runtimes.

Uninstalling does not erase local state or uploaded data. Independently
authorized app/root instances keep separate grants. Older installations may
retain a legacy shared grant until authorization migration completes. See
[Privacy](PRIVACY.md) before logging out or deleting data.

WorkBuddy package and runtime checks are recorded separately from installed
host acceptance. Do not infer Linux, Windows, WSL, or another edition's native
behavior from the macOS WorkBuddy AI 5.8.4 research baseline. See the release
verification record for each offered host/platform capability.

Official client documentation: [Cursor plugins](https://cursor.com/docs/reference/plugins),
[Claude Code plugins](https://code.claude.com/docs/en/discover-plugins), and
[Codex plugins](https://developers.openai.com/codex/plugins).

## Telemetry controls

Run the bundled launcher with the same host/state directory as the plugin:

```sh
sh scripts/run.cmd telemetry status --host codex
sh scripts/run.cmd telemetry disable --host codex
sh scripts/run.cmd telemetry enable --host codex
```

Use `--host claude-code` for Claude Code; omit `--host` for Cursor. Preserve
any state-directory override used by your client. On Windows, invoke
`scripts/run.cmd` directly. `HIPO_TELEMETRY_ENABLED=false` overrides enable;
restart existing client/plugin processes after changing their environment.
The saved disable preference is checked by running native processes.

Telemetry failures do not stop MCP calls or capture delivery. Local runtime
JSONL diagnostics remain available when export is disabled or offline. A missing
trace can reflect sampling, queue limits or shutdown; error/warning logs use an
independent pipeline. Never send real conversation or credential files for support.

## Portable WorkBuddy CLI child calls

Choose the installed app's supported command and arguments from current evidence.
These are invocation templates, not an inventory or installation checklist.
Resolve the runtime, CLI entry, required runtime arguments, working directory and
active profile once. Preserve proxy and profile environment. Set the enclosing
host tool's execution budget for the actual operation; help success is not install
evidence. Stop only the current child tree on timeout, never the host application.

In POSIX shells, use separate positional arguments. This also avoids zsh's
single-string expansion behavior and keeps paths with spaces or quotes intact:

```sh
invokeWorkBuddyCli() (
  unset SERVER__PORT SERVER__HOST
  cd -- "$cliWorkingDirectory" || exit 1
  "$runtimePath" "$cliPath" "$@"
)
# Pass the already selected native command as separate tokens.
invocationExitCode=0
invokeWorkBuddyCli "$commandGroup" "$commandAction" "$pluginSelector" || invocationExitCode=$?
printf 'WorkBuddy CLI exit code: %s\n' "$invocationExitCode" >&2
```

If the runtime requires additional launch arguments, supply them as individual
positional arguments or a shell array, retaining their verified order. Let stdout
and stderr reach the caller in full, or capture both without truncation or a
pipeline that hides the exit code. Use the enclosing tool's process-tree timeout;
when managing a process yourself, retain that child/group identity for cleanup.

Windows PowerShell 5.1 needs a native argument-string encoder because its
`ProcessStartInfo` lacks `ArgumentList`. Preserve the verified runtime arguments
in `$nativeArguments`; include the CLI entry and chosen command tokens as separate
array elements. This encoder preserves embedded quotes and trailing backslashes:

```powershell
function ConvertTo-NativeArgument([string] $value) {
    if ($value.Length -gt 0 -and $value -notmatch '[\s"]') { return $value }
    $escaped = [regex]::Replace($value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}
$start = New-Object System.Diagnostics.ProcessStartInfo
$start.FileName = $runtimePath
$start.Arguments = ($nativeArguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' '
$start.WorkingDirectory = $cliWorkingDirectory
$start.UseShellExecute = $false
$start.EnvironmentVariables.Remove('SERVER__PORT')
$start.EnvironmentVariables.Remove('SERVER__HOST')
$process = [System.Diagnostics.Process]::Start($start)
if (-not $process.WaitForExit($timeoutMilliseconds)) {
    taskkill.exe /PID $process.Id /T /F
    throw 'This WorkBuddy CLI invocation timed out; inspect its output and child environment.'
}
$invocationExitCode = $process.ExitCode
$process.Dispose()
[Console]::Error.WriteLine("WorkBuddy CLI exit code: $invocationExitCode")
```

The child inherits complete output streams and the parent's remaining environment.
A nonzero exit or a host approval block needs the actual returned explanation;
never change protection settings or replace the app with standalone CodeBuddy.

## Setup journey diagnostics

CLI and MCP authentication results can include `journeyId`, `diagnosticId`,
`logPath` and `hasPreservedState`. The journey survives process restarts and
joins the server's authorization-attempt ID. The diagnostic ID identifies the
current invocation. A replacement instance preserves older state without moving
its queue into the new account or grant. Passive status creates no journey.

Lifecycle milestones distinguish browser approval, server activation, local
credential commit, MCP initialization and the first executed business-tool result.
Initialization, tool discovery and preparation-pending responses are not first
business success. No observed first use is normal until the user invokes a tool.
Offline delivery, opt-out and bounded queues leave observation gaps; a missing
remote event does not prove failure. Safe local logs remain available. Follow
[the operations runbook](https://github.com/Ontos-AI/hipo/blob/main/docs/plugin-setup-observability.md)
for deployment owners; users need only provide returned diagnostic identifiers.
