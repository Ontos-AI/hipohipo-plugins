# Support and diagnostics

Report issues in [Ontos-AI/hipohipo-plugins](https://github.com/Ontos-AI/hipohipo-plugins/issues).
Include the plugin version, client and client version, OS/CPU, installation
route, safe `status` output, and a minimal synthetic reproduction. Do not attach
credentials, SQLite files, real transcripts, or screenshots with private content.
Agents use supported CLI/API operations and explain required UI actions to the
user instead of operating the interface.

## Cursor display names

The plugin card uses **Hipo Hipo**. Its installation
identifier remains `hipohipo`. Refresh the marketplace and update through the
original installation route if the card still shows `hipohipo`.

The **Ontos Ai Hipohipo Plugins** section heading is a separate Cursor
marketplace display name. If the user wants to change it, ask them to open
**Manage**, select that marketplace, edit its name to **Hipo Hipo**, and save.
Do not automate the interface. This label does not affect plugin functionality.
Keep the repository URL and identifiers unchanged. Reinstalling the plugin,
renaming its identifier or clearing credentials is unnecessary.

## Archive verification and safe extraction

Before running a downloaded package, verify its complete filename against the
published SHA256 checksum. For WorkBuddy, also verify the size and SHA256 in the
official domestic release index. Extract into a new directory and reject absolute
paths, directory traversal, symbolic or hard links, and special files. Confirm
`release.json` version and `sourceCommit` match the selected official release's
provenance. Do not execute an archive that fails these checks.

## Connection and login

### Installation errors

Use the independent installer's result and `repair` command with the same host
and verified configuration root. A native command can fail after changing some
state; the installer reports actual selection, preserves recovery evidence and
never claims current MCP loading from exit zero alone. Unknown source ownership,
modified backups, busy unknown locks and unsupported native capabilities require
inspection. Avoid editing private registries or using uninstall/reinstall to
repair a partially applied installation.

Preserve the actual sandbox or host approval failure. Use the host's supported
per-command approval when available; do not change global protection settings.
An absent PATH entry is not proof that the app is uninstalled. Preserve the
selected profile and the qualified CLI; do not substitute standalone CodeBuddy
for WorkBuddy. A timeout stops only this invocation's child process tree.

### WorkBuddy native recovery

If the independent installer fails, preserve its error, operation ID, and
actual exit status. Resolve the running WorkBuddy application's bundled plugin
CLI and runtime from the desktop installation and its CLI package's `bin`
entry. For a custom Windows installation, use the confirmed desktop executable
path, such as the target of the WorkBuddy shortcut. Its internal CLI name may
be `codebuddy`. Keep the verified active profile,
including `WORKBUDDY_CONFIG_DIR` and `CODEBUDDY_CONFIG_DIR` when set. Both must
refer to the same directory. Remove `SERVER__PORT` and `SERVER__HOST` from every
CLI child, including help and inventory. Preserve the parent's environment.
Use the application's bundled runtime if the entry is a script. For the
bundled Electron entry, set `ELECTRON_RUN_AS_NODE=1` and
`CODEBUDDY_FORCE_LITE_WB_BUNDLE=1` in the child and use Node-style argument
parsing (`process.defaultApp = true`).

Inspect the native state before choosing an action. The commands below are
arguments to that verified WorkBuddy CLI. Retain complete local stdout/stderr
and exit status, even if the tool output is summarized.

```text
plugin marketplace list
plugin list --json
```

If the official plugin is already enabled at the expected version, continue
with the connection check below. Preserve a disabled selection, another
scope, or a conflicting source and report it. When the installer reports a
pending or conflicting registration, preserve its evidence and use the
installer's repair flow before changing the registered marketplace.

For a fresh install, read the [official OSS release index](https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/releases/latest.json).
Check schema version 1, the stable version, and `sourceCommit`. Download
`marketplace.url` from the same OSS origin under that version's release path.
Verify the size and SHA-256 before extracting. Use a persistent writable
directory in the selected profile outside the host-managed plugin cache.
Keep the complete marketplace, reject absolute paths, directory traversal,
symbolic or hard links, and special files, and match `release.json` to the
index. Require `.codebuddy-plugin/marketplace.json` and the
`plugins/hipohipo-workbuddy/` package. Use this verified source to install:

```text
plugin marketplace add <absolute-path-to-verified-marketplace>
plugin install HipoHipo@hipohipo-plugins --scope user
plugin list --json
```

Reuse a verified matching marketplace if it is already registered. For an
existing official Git marketplace, use its native update with the current
source. For a user-managed local OSS marketplace, verify and stage the new
complete archive as above. Back up the verified original directory, refresh
its contents at the same registered path, then run
`plugin marketplace update hipohipo-plugins`. Keep the backup until the update
is confirmed. For an installer-managed versioned source, use installer repair
to prepare the replacement. Preserve the immutable source and native cache.

Once the selected source exposes the target version, run:

```text
plugin update HipoHipo@hipohipo-plugins --scope user
plugin list --json
```

If WorkBuddy denies a command, use its supported per-command approval or
[desktop plugin interface](https://www.workbuddy.cn/docs/workbuddy/Plugins).
Keep the active profile and the original source. After any failure, read
inventory before another mutation. A standalone native fallback installs
the plugin through the host. Hipo automatic update enrollment is confirmed
separately by the installer.

Confirm the source, user scope, enabled state and installed version, then use
the normal host loading flow. Call the current conversation's Hipo MCP
`auth.status` to confirm the responding version and authorization. Reuse
existing authorization where available.

### Codex host recovery

If the default Codex UI requests sign-in despite `codex login status` confirming
the existing account, check the active profile and redacted native diagnostics
(`codex doctor --json` when available). For a stale background server, use the
supported daemon restart, for example `codex app-server daemon restart` when exposed
by this installation's help, then reopen normally and verify MCP.
Do not replace credentials. A successful daemon-bypass launch does not establish
that the app will connect when opened normally.

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
- **Cursor says Disabled:** ask the user to enable Hipohipo's MCP in Customize
  if no supported CLI/API is available. A remembered
  disabled setting can survive replacement of the plugin directory; reinstalling
  does not establish that the switch is enabled. The setting alone cannot show
  who changed it or whether uninstall caused it. Use supported controls, not
  private database edits. Rediscover tools in the current conversation first.
- **The required login tool is not exposed:** if sign-in is needed, use the installed
  package's `login` and `auth-status` with the exact same host/profile/data binding,
  even when other MCP tools are available. A refusal, cancellation or permission
  restriction is not a missing tool; do not use CLI to bypass it. Continue
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
- **Reuse authorization on another client:** install the selected target through
  the independent installer. The plugin-owned business command
  `login --host TARGET --configuration-root TARGET_ROOT --reuse-auth-from HOST --source-configuration-root SOURCE_ROOT`
  derives an independent grant from the verified source without opening a browser.
  `login --reuse-only` reports a needed login instead of opening consent. Do not copy
  credential files. Each client keeps its own `connectionId` and refresh token.
  A revoked or logged-out source client cannot approve another client.
- **CLI and MCP disagree about login:** use the same installed package, `--host`
  and verified active configuration environment. Do not substitute the default home directory
  or another profile's installation. The plugin resolves the shared
  instance binding; do not find or guess `--state-dir`. Preserve `CODEX_HOME`,
  `CLAUDE_CONFIG_DIR`, `WORKBUDDY_CONFIG_DIR`/`CODEBUDDY_CONFIG_DIR` and explicit
  Hipo overrides when present.
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

### Installation diagnostics

Use the installed entry with the verified active client's `HOST` and existing
configuration environment. These status commands do not start login:

```sh
hipohipo-installer status --host HOST --configuration-root PROFILE
./hipohipo status --host HOST
./hipohipo --help
```

Retain stdout/stderr and the actual exit code before summarizing a failure.

### Confirm the current connection

After completed sign-in or verified authorization reuse, check the current MCP.
If tools are missing or outdated, briefly retry tool discovery/status a few times
while the host finishes loading. Continue any pending setup action; retries alone
do not prove loading. If still unavailable or outdated, use the client flow below.

- WorkBuddy: once the host reports MCP ready, verify in a new conversation first.
  If MCP cannot start or the new conversation still has no tools or an old version,
  quit and reopen the app normally.
- Cursor: tell the user to quit and reopen the app normally if the new version is not loaded; do not operate the interface yourself.

Do not require a search for an unverified reload/reconnect control.
Enable MCP only when disabled. Claude Code and Codex use their current documented loading
flow, continuing in a fresh client session when the existing session cannot load it.

Compare the responding MCP version before confirming readiness.
Reuse authorization; do not reinstall, repeat login, clear state or change host
protection solely to load the plugin.

If the host displays a Hook trust prompt, review the packaged commands through
its native UI (Codex CLI: `/hooks`, when available). Do not bypass that review.
`hipohipo trust --host HOST` can converge packaged Hook trust after installation or
login when the host still shows that prompt.

Use the installed manifest for the package version and current MCP status for
the responding process's `serverVersion`. Verified `host` and `localInstanceId`
identify its local instance; `instanceId` identifies the authorization binding.
`runtimeVersion` may describe a preparation target rather than a running process.
CLI status establishes CLI state, not MCP loading. Missing version or identity fields leave
that detail unconfirmed; they do not justify discarding a valid grant or forcing
a new login. Retain diagnostic IDs and logs when results disagree.

For a Skills or Hooks loading problem, inspect Hipohipo in the current client's
native plugin inventory and hook view or diagnostics. Skills must be exposed and
the original hooks loaded. Existing native event records can establish execution;
installed files or installer historical observations do not establish
current-session loading or execution. Report unavailable evidence as unconfirmed.
This diagnostic inspection is not a mandatory step in ordinary installation.

Use only necessary status responses for verification; do not call business tools,
upload anything or run Skills/Hooks or capture tests. Keep loading unconfirmed
until verified.

Give a friendly final reply in the conversation's language, usually 1–3 sentences.
Once the connection is verified, confirm readiness and briefly describe finding documents and
recalling memories within the current grant, without example questions.
For a new conversation or normal app restart, state what is complete and that
loading remains unconfirmed. Give only the required loading action; do not
promise readiness after restarting, and do not ask the user to paste prompts, verify or report back.
For actual failures, explain the issue and next step without claiming readiness.
Keep technical details (versions, paths, checksums and diagnostic IDs)
in existing tool output unless requested or needed for support.

### Preparation and rejected credentials

Retained lock files are not evidence that preparation is still running.
Use the returned status and logs to diagnose it. Directory deletion is not
required to prepare, retry or write diagnostics. Do not
rename/delete locks, disable a host safety shim, manually download a runtime or
invoke internal publication commands to work around an error.

Downloads continue from the stored offset only after a matching HTTP 206 range
response. `download_resume_unsupported` and `download_range_invalid` are terminal;
inspect the download service or intermediary before an explicit retry. Network
failures are counted across calls (at most three); a normal 30-second call expiry
is not a network failure. An attempt's 600-second limit never resets during
continuation. Archive and executable verification must finish before `ready` is
reported. `inspect_error` identifies identity, local storage, permission or
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
identity are not reused. The final digest must still match before use; no
manual downloads, lock cleanup or timeout override is needed.

Explicit login reuses a valid grant and refreshes an expired one. Only
`invalid_grant`/`invalid_client` invalidates the old credential for this instance
and continues once to new authorization. Status remains observational. New
consent denial/cancellation/expiry returns `request_login_retry`; network,
credential-store and service errors return `inspect_error` without replacing a
valid grant. Do not clear another instance's credentials or a retained legacy
shared grant to repair one installation.

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
is still running. An explicit login call continues an active attempt or replaces
one interrupted attempt. If the replacement also exits, inspect the reported
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
  commands with the same verified `--host` and profile as MCP to diagnose
  authorization, network errors, and write permission.
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

- **Cursor Desktop immediately after edit/resubmit rewind:** sharing may return
  `share_generation_in_progress`. Do not claim a share was created or substitute
  another conversation's history. Retain the error for support.
- **WorkBuddy command selection:** use fully typed
  `/hipo-share`. Its `@skill` picker can pass unresolved placeholders and return
  `share_binding_missing`; that path is unreliable.
- **WorkBuddy Desktop fork:** local Desktop fork is unsupported. A bundled CLI
  or cloud fork is a separate capability.
- **Interrupted upload:** use the returned retry instruction in the same host
  and account. Retry retains the frozen original snapshot. An account change or
  an unrelated ordinary turn can prevent retry in the old command context.

## Documents and receipt updates

- **No document confirmation form:** saving is now chosen during connection
  authorization. Proactive saves use `source.parse_background`, which is hidden
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
is not included. Use each host's native declarations and the installer's reported shared entry.

For an ordinary update, keep the same entry, source and scope; do not disable or
uninstall it first. Keep one Hipohipo entry enabled in each client and follow
the [installation and update guide](https://hipohipo.ai/install/README.md) for
that source's update and loading flow. Preserve existing update preferences,
authorization and history.

Use the independent installer for package updates and migration. Preserve a
qualified native marketplace's update authority. Cursor and the default Claude
profile share one compatible installed entry; changing its enabled state or
removing it can affect both. Other profiles and host installations remain separate.
Retained native programs and active runtime leases must remain usable during
updates; deliberately cleaning old data is a separate operation.

Uninstalling does not delete data already uploaded to Hipohipo. To retain local
history when deliberately removing a plugin, use the client's supported keep-data
option when available and preserve existing Hipo data. Native uninstall behavior
depends on the client; do not assume every host-managed data directory is retained.
See [Privacy](PRIVACY.md) before logging out or deleting data.

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

Use `--host claude-code` for Claude Code or `--host cursor` for Cursor. Preserve
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

## Setup diagnostics

CLI and MCP authentication results can include `journeyId`, `diagnosticId`,
`logPath` and `hasPreservedState`. Include the returned identifiers and safe status
output in a support request. Inspect the indicated local log for the original
failure, omitting private content from reports. `hasPreservedState` means older
state was retained; it does not establish that its history moved into a new
account or grant. Missing remote diagnostics alone do not establish failure.

## Major-update notices

Hipohipo can announce a major update or an upcoming end of support in a tool
result or supported session/prompt Hook. These notices are advisory and do not
interrupt business operations, including after an announced support date.
Finish the current operation before following the installation/update guide.

Use the installed `hipohipo update-notice status --host <client>` with the active
profile to inspect notice response. The supported client values are `cursor`,
`claude-code`, `codex` and `workbuddy`. Notice response is enabled by default;
`update-notice disable` ignores both new and cached notices completely, and
`update-notice enable` enables it again. Add the same `--host` argument to each
command. Windows uses `hipohipo.cmd`. Change this preference only when requested.
It does not change the host's automatic-update setting or installer-owned background
checks; manual updates remain available.

Status rereads the effective installation when a notice is active. Its
`runningVersion` belongs to that CLI invocation, not another running MCP process.
An already-updated package requires verifying the current MCP and, if necessary,
normal host loading rather than another installation. Unknown or conflicting
installed versions require checking the host's supported installation information;
old package/cache directories are not proof of the active version. Preserve the
existing channel, scope, profile, authorization and history. Do not automatically
restart the host or retry a failed notice-driven update.

## Independent installer diagnostics and recovery

Use the independent installer returned as `installerEntry`, keeping the verified
active host and absolute configuration root:

```sh
hipohipo-installer status --host HOST --configuration-root PROFILE
hipohipo-installer update --host HOST --configuration-root PROFILE
hipohipo-installer repair --host HOST --configuration-root PROFILE
```

Use `.exe` on Windows. `status` is passive. Manual `update` and `repair` bypass
the automatic interval and return after a bounded attempt and verification.
Retain the returned operation ID, source/scope, update owner, installed version,
runtime state, error code, diagnostic path and actual exit status. A telemetry
queue or exporter failure does not turn successful package activation into a
failed update. The invoking agent decides how to explain the facts and continue.

The installer verifies official metadata, size, SHA256, provenance and runtime
pins before selecting an immutable package. Failed preparation preserves the
previous selection. A same-version repair uses a fresh complete path. Native
CLI failure preserves native authority; it never silently switches to direct
cache writes. Unknown publishers, source changes, ambiguous scopes or modified
recovery backups require inspection. Do not delete unknown locks or backups,
copy credentials, turn off host protections, or enable another Hipo copy.

Old Cursor Local installations stay usable until the new installer migrates
them. Migration prepares the shared replacement, drains the old writer locks,
retires Local discovery and updater admission, and preserves retained executable
paths, authorization, capture state and disable choices. Manual repair accepts
verified historical component-version disagreement, including a newer outer
manifest with an older MCP/Hook selection. The original bytes remain diagnostic
and rollback evidence; a damaged snapshot is not described as healthy.

Installer-owned checks run on invocation, with one hour between successful
remote checks and bounded retry after failure. Manual checks bypass those
limits. The installer also checks its independent release feed; a failure keeps
the current usable installer. There is no permanent updater daemon. Claude Code
and Codex native schedules remain host-owned. Shared Cursor/Claude native
updates preserve an explicit existing auto-update disable.

Every failure is recorded locally and offered remotely without INFO sampling.
Normal INFO is sampled, deduplicated and rate limited. The bounded queue retries
on later invocations. Explicit telemetry opt-outs remain effective. A Hook's
installer-launch failure is local immediately and deferred for remote reporting
until a later MCP startup; absence of MCP or unavailable ingestion can prevent
delivery. Remote diagnostic attributes exclude paths, command output, credentials
and conversation content.

Source refresh, installed bytes and this conversation's loaded MCP are separate.
Use the current MCP's `auth.status` after the host's normal loading flow before
claiming the new version or authorization is active. Keep a valid read-only grant.
If the installer reports sign-in required, continue through `auth.login` without
copying tokens or starting parallel login attempts.
