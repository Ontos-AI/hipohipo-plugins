# Changelog

## 0.6.106

- Approve Cursor document-transfer and background parse through the existing grant and bound original bytes, and send session, turn and captureReason with each Source so a later ready file can be linked to that turn.

## 0.6.105

- Check the shared package at `packages/hipohipo` during release verification so 0.6.104 isolation can publish.

## 0.6.104

- Fix WorkBuddy startup compile so the 0.6.103 marketplace isolation can publish.

## 0.6.103

- Keep WorkBuddy's marketplace `plugins/` directory to the WorkBuddy package only, and remove leftover `hipohipo@hipohipo-plugins` and `hipohipo@inline` enabled-plugin keys on WorkBuddy startup, so the shared Cursor/Claude package is not loaded as a second Hipo MCP.
- Inject the recoverable-session hint on WorkBuddy, Codex and Claude Code SessionStart, and mark capture batches with `handoffDisabled` when the local privacy switch is on so fallback synthesis stays off.

## 0.6.102

- Publish a private session snapshot after each completed turn, not only when the host window closes, so another agent can resume without waiting for session end.
- Observe WorkBuddy assistant replies and same-generation tool records from the persisted transcript when the user turn has no shared request id, so capture fallback and native snapshots keep the assistant text.

## 0.6.101

- Reject rollback snapshots invalidated by a later archive reinstall, preserving the replacement package and update preferences. Prompt only for loading when an installed intermediate version resolves a notice but the current MCP process remains affected.

- Add optional server-activated major-update and end-of-support notices to native tool results and supported session/prompt Hooks. Keep business results non-blocking, preserve the original installation route and defer updates until the current operation finishes. Add independent update-notice status/enable/disable controls; disabling ignores new and cached notices entirely.
- Recheck the effective installed version for each notice decision, distinguish it from the running MCP version, suppress duplicate actions and request loading only when the package is already current. Bound cached notices and support server withdrawal without restarting the plugin. Matching Web/API and Gateway deployments are required before activating a campaign.
- Add complete-package automatic updates for installer-claimed Cursor Local installations. Bind update authority to the canonical installation root in an external archive-channel receipt; skip marketplace, unknown, redirected and mismatched installations. Preserve authorization, instance identity, configuration and capture/history.
- Stage and verify stable release archives/provenance, prepare the pinned runtime, then atomically switch every component through versioned manifest paths. Retain previous packages for rollback, serialize concurrent installers/updates and rate-limit background startup checks. Add update status/check/apply/enable/disable/rollback CLI controls; rollback disables background updates.
- Make Cursor installation archive-first with optional CLI marketplace registration. Keep English/Chinese website and distribution guides aligned, use stable CLI/API operations only and explain the optional user-selected Cursor-managed marketplace channel.

## 0.6.100

- Use a native Cursor installation tool only when it supports the selected GitHub marketplace. Continue directly through Customize when a tool supports only public-marketplace entries, explain the required UI action when it cannot be automated, and avoid private database/source inspection or unsupported command discovery merely to find an installer. Preserve existing channels and authorization.

## 0.6.99

- Prefer Cursor native marketplace installation for first setup so Cursor can manage later upgrades. Limit archive fallback to a real marketplace blocker, explain manual updates for local installs, and preserve existing channels, profiles, scopes, authorization and history. Keep English and Chinese website/distribution guides identical and distinguish marketplace source refresh from installed-plugin and MCP upgrade evidence.

## 0.6.98

- Automatically publish a private recoverable session at session end from the native snapshot when the host is adapted, and list a Memento text fallback when native read fails or the host is not yet adapted.
- Add `handoff.list` and `handoff.read` plus a `resume-session` Skill so another agent on the same account can resume exactly one prior session. Create `handoff-disabled` in the plugin state directory to turn automatic produce off.

## 0.6.97

- Preserve same-key immutable replays after ready, failed or expired outcomes. Retain path-to-operation recovery references before PUT, rebuild missing upload history from completed transfer records, and keep expired permits unusable. Reuse the original operation while its upload acknowledgement is still pending. Recheck authorization after persistence and roll back only a newly created, unsent attempt when the grant changes.

- Capture completed standalone plans, reports and design files before final delivery. Keep drafts, repeated reads, ongoing edits and later revisions out of automatic recapture; do not create files from chat text only for capture. Align the shared Skill, WorkBuddy mirror, Cursor rule, MCP entry instructions and generated plugin metadata.
- Persist successful original-file uploads in a private local SQLite index scoped to the service, Account, Project and normalized absolute path. A new background attempt for a previously uploaded path returns `confirmation_required` before Source creation. Ask whether to parse again and use ordinary `source.create` only after explicit agreement; different paths remain independent.
- Preserve pending-operation retry identities, current authorization and immutable original-byte transfer. Record both foreground and background uploads without waiting for parse completion. No Knowhere document-update integration, server schema change or backend deployment is included.

## 0.6.96

- Remove background authorization polling from receipt subscriptions. Established notification streams may finish after an external login or logout; subsequent operations and reconnects still use current authorization.
- Reuse cached receipt subscriptions only for the same authorization and a live stream. Reauthorize changed grants with the server, preserve stable-grant token refresh, and stop reconnecting when local authorization is missing.
- Advance the request order when reusing a receipt subscription, so delayed requests from another account cannot cancel a stream reused after switching back. Older requests for the same grant cannot rewind that order.

## 0.6.94

- Normalize source package, MCP catalog, launcher verification, and embedded document picker formatting without changing entry point arguments or picker behavior.
- Regenerate bundled Brain descriptions from the server catalog and keep generated JSON formatted. Preserve tool names, input fields, validation rules, and permissions.

## 0.6.93

- Preserve original tool calls and retained tool results from WorkBuddy, Claude Code, Codex, Cursor Desktop and Cursor CLI in version 2 shared snapshots. Keep reasoning, system messages, native bookkeeping and owned sharing turns excluded; never open referenced workspace files.
- Show tool name, call/result phase and expandable literal payloads on the sharing page. Preserve tool identity across pagination, JSON downloads, Markdown downloads and private continuation context. Continue accepting immutable version 1 snapshots.
- Deploy the matching Hipo Web/API before publishing this plugin version. Existing servers reject version 2 snapshots; native-client end-to-end acceptance remains separate from parser, browser and local persistence contracts.

## 0.6.92

- Decode one JSON string layer in WorkBuddy sharing picker paths before comparing them with the successful Skill's exact path. Preserve literal references, plugin and request ownership checks, and exclusion of verified sharing turns from later snapshots.
- Describe an unmatched WorkBuddy sharing request as a recognition failure instead of claiming that the request was not persisted. Retain the existing error code.

## 0.6.91

- Recognize equivalent Windows path separators in WorkBuddy sharing Skill results, picker references and dedicated runner commands. Preserve canonical path, plugin ownership and request ancestry checks.
- Recognize Codex desktop sharing Skill links through the enabled native Skill registry, exact Hipohipo plugin ownership and the current private tool binding. Retain the existing native CLI invocation format.
- Retain the dedicated Codex runner command in its private PreToolUse binding so current sharing does not depend on an executing command already appearing in persisted native history. Validate sharing and retry arguments against the requested operation.
- Exclude verified prior desktop sharing requests and receipts across updates within the same registered plugin cache, while preserving ordinary mentions and unrelated paths.

## 0.6.90

- Recognize WorkBuddy's dedicated skill picker when it quotes the exact installed `SKILL.md` path and persists same-request reasoning before the Skill call. Preserve the bound runner, successful Skill result, request, ancestry and plugin-path checks.
- Exclude recognized prior picker requests and their receipts from later shared snapshots, along with internal reasoning and tool output.

## 0.6.89

- Dispatch prepared Windows Git Bash Hooks through the checksum-verified native runtime, avoiding emulated PowerShell startup delays while preserving original stdin, runtime leases and existing authorization checks.
- Reuse that native runtime for ready-status queries. Keep cold help and unprepared-runtime handling on their existing bootstrap paths.

## 0.6.88

- Use `HipoHipo` as the WorkBuddy plugin identity and marketplace entry so its Plugins card renders the capitalized product name. Keep `hipohipo` as the identity for Cursor, Claude Code and Codex, and retain all host runtime, MCP server, authorization and skill contracts.
- Recognize the renamed WorkBuddy namespace in sharing ownership checks and background document permission Hooks while retaining legacy names and the existing grant, operation and request checks.
- Document the native transition from the legacy WorkBuddy identity: disable the old installation, install the renamed package in the same profile and scope, and retain the old package and data for rollback. WorkBuddy's generated letter icon and skill discovery behavior are outside this change.

## 0.6.87

- Retain source-less Hook events without repeatedly collecting them during Worker or MCP startup recovery. Resume through the existing bounded recovery path when the host supplies a transcript path; keep known-path late-file recovery unchanged.
- Preserve all pending Hook text, receipts, digests and source work beyond the old 30-day tentative expiry. Protect unreconciled legacy history during cache cleanup while retaining cleanup of completed history.
- Derive waiting status and recovery eligibility from the same durable source evidence. Keep the existing status protocol and SQLite schema; do not infer background task types from prompt content or missing paths.

## 0.6.86

- Accept an absolute local file path for both Source creation and authorized background parsing. Derive original metadata and durable retry identities in the plugin; retain local paths in private operation records. Return commands containing only the launcher, host and operation ID, while preserving legacy explicit-file retries.
- Infer supported file formats from the shared Hipo mapping for filename-only HTTP permits. Return storage-provided upload headers and retain safe original extensions and determined MIME types through completion. Keep the direct PUT protocol and existing URL, inline and explicit metadata inputs.
- Distinguish foreground write permission and normal host review from background parsing permission in the existing transfer and approval paths. Preserve trigger scope, authorization binding, immutable byte checks and operation receipts. Deploy Web/API, then Gateway, then the plugin after separate approval; this version is prepared only.

## 0.6.85

- Preserve explicit capture deferral codes for waiting on a transcript, unsettled sources and read budgets instead of collapsing them into operation failures. Keep unknown diagnostic values redacted.
- Suppress unchanged capture warnings across MCP and worker restarts with a bounded, private notification cache. Re-arm notifications after actual capture progress; preserve genuine failures and all local diagnostic records.
- Keep notification metadata separate from pending capture events, source recovery and immutable uploads. Verify concurrent processes and later source recovery without discarding unconfirmed content.

## 0.6.84

- Identify CLI authentication results with `observedVia: "cli"` and explain that their process version does not verify the current chat's MCP connection. Preserve all existing status, continuation, version and identity fields.
- Cover a still-running older MCP process alongside a newer CLI, retaining the same valid read-only legacy grant and instance. Apply the same output boundary to uninitialized status, login results and setup failures; keep MCP responses and installation guides unchanged.

## 0.6.83

- Serialize transfer-ticket preparation with the original transfer operation. Concurrent admission retries preserve the ticket and completed marker instead of rewriting active operations.

- Prepare the existing scoped Codex, Claude Code and WorkBuddy document permission candidate, including the current WorkBuddy entry instructions and bounded authorization retry. Preserve authorization binding and native review settings.
- Accept the plugin-local original file path for dedicated background parsing permits, validate it before Source admission, and return a complete transfer command. Strip the local path before remote dispatch, bind it to the immutable original and existing grant, and retain compatibility with prior transfer tickets.
- Document the local path and complete command in document-capture step 4. Keep existing trigger scope, explicit opt-outs and other workflow steps.
- Coordinate with the Web/API and Gateway fix for authorized Source reuse during status waits. Preserve the original operation receipt and connection/project revocation checks; deploy the application contract before the Gateway. Plugin publication and native-client acceptance are separate.

## 0.6.82

- Finish installation with a brief reply in the conversation's language: confirm readiness and describe available capabilities, or give only the needed new-conversation or normal-restart action. Do not ask users to repeat prompts or verify the connection themselves.
- Keep technical evidence in existing tool output, explain actual failures plainly, and use only status responses for setup verification without business-tool probes. Synchronize both fixed guides, their distribution copies and Support; preserve loading checks, authorization reuse, native protections and legacy instances.
- Use a normal Cursor quit/reopen for loading guidance instead of developer-menu instructions.
- Keep main-flow configuration guidance to preserving the host's effective configuration and environment. Retain WorkBuddy override names and wrong-profile troubleshooting in Support.

## 0.6.81

- Recognize WorkBuddy sharing invocations when same-request reasoning records appear between the native Skill result and its bound runner. Follow only earlier parent records and preserve the existing Skill, request, tool and plugin-path ownership checks.
- Keep reasoning and prior sharing controls out of the shared snapshot. Reject unrelated requests, missing ancestry, cycles and intervening messages or tools.

## 0.6.80

- Prefer WorkBuddy's native update action for a known existing installation, retaining the direct install route for first setup. Put the update example before the first-install example in both fixed guides and their distribution copies.
- Keep existing source, scope, authorization, package verification and host-protection requirements. This guidance change does not alter runtime behavior or claim to fix WorkBuddy's lock cleanup.

## 0.6.79

- Put WorkBuddy host CLI invocation guidance beside the installation route. Identify the bundled plugin-management entry explicitly and show child-only removal of host service variables for help, marketplace, install and update calls. Preserve profile, proxy, runtime and bundle-selection settings.
- Keep the English and Chinese fixed guides and distribution copies aligned, with executable command-example regression coverage.

## 0.6.78

- Default rules and Memory imports to the authorized app. Offer all supported apps explicitly and select the current app before applying the shared 200-file limit. Preserve the source choice across authorization, retries and local recovery.
- Require source-scope-capable collectors for new imports, retain legacy task selection, and reject foreign-app manifest entries for current-app tasks. This increment requires the matching Hipo Web/API contract and migration before plugin publication.

- Keep cross-app project exclusions when narrowing discovery, including native links, formal imports and restart recovery. Preserve released-collector login and legacy import-request replays during the server-first rollout.

## 0.6.77

- Require a verified client identity before resolving CLI command state. Missing `--host` no longer treats another client's configuration root as Cursor or creates a wrong-client instance. Preserve explicit host/environment identity, frozen instance descriptors and native Cursor launch compatibility.
- Reject the legacy Cursor fallback when another client's profile environment or native cache identifies a competing profile, including default Claude Code and Codex installations without configuration overrides. Unverifiable caches still require explicit identity; retain existing cache ownership checks and frozen-instance reuse.
- Keep missing profile markers, unusable registrations and Claude directory launches from falling through to Cursor, including Bash tool commands without `CLAUDE_PLUGIN_ROOT`. Treat Claude subprocess markers as conflicting identity evidence, not a profile selection. Preserve verified local Cursor packages, matching cache profiles and aliases without weakening native profile validation.
- Pass explicit Cursor identity from native MCP, Hook and package command entries, including local installers and release packaging. Inheriting another client's configuration variables no longer blocks those native launches or changes their existing profile binding.
- Add explicit-host capture status examples to shared CLI help and both fixed installation guides. Keep diagnostics optional and preserve existing authorization, profile and shared-cache/symlink validation.

## 0.6.75

- Replace the mandatory MCP loading delay with brief discovery/status retries and the host's normal loading flow. Preserve the WorkBuddy ready-first new-conversation path, existing authorization and package/profile checks.
- Keep Hook trust troubleshooting in Support only when the host displays an actual review prompt. Synchronize the fixed English/Chinese guides and distribution copies without adding an installation check or changing native trust policy.

## 0.6.76

- Extend grant-checked document approval and the bound original-file transfer command to Claude Code and WorkBuddy. Use Claude Code PermissionRequest and WorkBuddy PreToolUse with native tool names and event schemas. Preserve document scope, explicit opt-outs, server authorization and global approval settings.

## 0.6.74

- Add an opt-in Codex PermissionRequest Hook that verifies existing background parsing authorization and the current destination before deciding a scoped document request. Users review and trust the installed Hook through Codex; global approval policy is unchanged.
- Bind Codex original-file transfers to private server-issued operation tickets, immutable file size and SHA-256, and the original authorization and Project. Recheck permission before transfer, freeze the original bytes, suppress duplicate completed transfers, and reject redirects. Retain admitted Source identifiers when local preparation fails.
- Expose the dedicated transfer command in parsing results and document-capture. Preserve existing document scope, server enforcement, ordinary tool approvals and other hosts.
- Request native per-command review for the exact Codex transfer command before execution, allowing the trusted permission handler to run before sandbox-protected runtime state is accessed.

## 0.6.73

- Show CLI help before runtime preparation or instance resolution, including cold installations. Share one help text between the native binary and POSIX/PowerShell launchers, and explain missing host, configuration-root and option values without changing identity validation or legacy instance reuse.
- Add explicit-host status and login examples to both fixed installation guides, retaining their short setup path and identical distribution copies.

## 0.6.72

- Clarify document-capture step 1: when the background parsing tool is available, continue the existing workflow through normal host review before completing the reading task. Reading the Skill, discovering the tool or reading local bytes does not complete parsing. Preserve trigger scope, explicit opt-outs, authorization checks and unavailable or denied behavior.

## 0.6.71

- Serve the canonical English and Chinese installation Markdown through uncached website entries. Point homepage, app-opening and package guide links to the website and request a direct full-document read. Continue native installation through authorization and current MCP verification without mandatory inventory queries; preserve host protection, legacy instances and loading recovery.
- Make the Cursor first-install route download, verify and install the official stable package directly. Reuse a marketplace channel only for a confirmed active installation in the current profile; historical caches alone are not an active installation. Preserve existing channels, integrity checks, legacy authorization and loading recovery, with deeper investigation reserved for actual blockers.

## 0.6.70

- Put the document workflow and engineering exclusions first in plugin MCP instructions, and require a separate Skill read before document actions. Preserve the existing capture scope, Skill body, parsing flow and authorization checks.
- Clarify the plugin background parsing tool's metadata-only, inline and URL effects. Classify Library listing and parse status as bounded reads, and background parsing as a non-destructive write with external URL support. Keep server contracts and host approval settings unchanged.

## 0.6.69

- Make normal first installation in both fixed guides proceed directly through the client's official stable package download, verification and installation route. Reserve deeper cache, private-database and installer-source investigation for actual blockers. Preserve existing channels, integrity checks, authorization reuse, legacy instances and loading recovery.

## 0.6.68

- Clarify document-capture selection for ordinary reading and summarization requests, including local file references. Put the existing before-reading loading requirement in the Skill description; preserve its body, scope, parsing flow and authorization checks.

## 0.6.67

- Rename the permission-gated background document tool to `source.parse_background` and describe the existing document-capture workflow as trying Hipohipo parsing. Preserve trigger timing, original-byte transfer, parsing and storage, independent authorization, retries and passive failure behavior. Do not add Hooks, pre-call announcements or host approval changes.
- Keep the existing persisted staging operation and request fingerprints so the public rename does not invalidate admitted requests. Retain application dispatch compatibility for the old tool name without advertising it in the new catalog.

## 0.6.66

- Resolve the active host configuration before inspecting installation state. Keep first WorkBuddy marketplace installation separate from other profiles while preserving existing sources, authorization and host protections.
- Prefer a new WorkBuddy conversation after the host reports MCP ready, with normal app restart as a fallback when MCP cannot start or the new conversation still lacks the current tools. Keep Support consistent with the fixed installation guides. Preserve completed sign-in and the single loading wait.
- Document native Codex recovery for legacy marketplace metadata and stale background-server sign-in. Runtime behavior, identity validation and legacy instance reuse are unchanged.

## 0.6.65

- Prefer the existing direct-upload permit and a streamed PUT of original local file bytes in document-capture step 4, avoiding Base64 reconstruction in generated tool arguments. Retain existing triggers, background authorization, retry identities and host approval settings; skip saving when either call is denied.

## 0.6.64

- Describe `source.create_background` as attempting document parsing with Hipohipo, retaining its upload/storage disclosure, authorization requirement and retry contract. Existing document triggers, permission enforcement, tool inputs and host approval settings are unchanged.

## 0.6.63

- Shorten the fixed English and Chinese installation guides around native installation/update, authorization reuse and current MCP verification. Wait once for 30 seconds after sign-in when tools are missing or still run the previous version before requesting client loading actions.
- Use documented or observed client loading routes, retain target-version context across normal restarts, and move detailed native installation recovery to Support. Preserve download integrity, host protection, active profiles and legacy authorization; runtime behavior is unchanged.

## 0.6.62

- Allow up to ten seconds for an already-authorized background-save policy response during tool discovery. Slower networks no longer hide `source.create_background` after two seconds; denied, expired, unavailable and cancelled policy checks still fail closed without login or credential refresh.

## 0.6.61

- Preserve the installed target version when setup resumes in a new conversation. Explain that a shared MCP connection can remain on the old version, resume the installation conversation after a normal restart, and compare the current connection before confirming readiness.

## 0.6.60

- Simplify both fixed installation guides around installation, sign-in and current MCP loading. Cover missing tools after a first installation and supported loading without a returned reload hint; retain existing authorization across normal reloads or restarts.
- Allow summarized or filtered command display while retaining diagnostic output and the installer's actual result. Keep detailed instance and runtime diagnostics in Support without changing integrity checks, host protections, authentication or legacy instance compatibility.

## 0.6.59

- Recover WorkBuddy native CLI errors through supported plugin management controls. Check installed state after a failure, reuse a verified matching package, and preserve host locks and safety protections while confirming sign-in and actual MCP loading separately.

## 0.6.58

- Restore supplied-document saving before reading or analysis through the existing Skill, Cursor Rule and MCP instructions. Replace the old offer step with permission-gated background upload while retaining explicit opt-outs and passive failure behavior.
- Remove the additional WorkBuddy document-routing Hook and its helper; preserve the existing conversation-capture Hooks.

## 0.6.57

- Put the native CLI installation receipt requirement before client routes: invoke install/update directly without output filters, retain complete stdout/stderr and the real exit status, and summarize only after completion.

## 0.6.56

- Load WorkBuddy document-reading policy through a synchronous, runtime-independent prompt Hook, so ordinary reading requests reach the shared document-capture Skill. Keep authorization, scope and background-save decisions in the Skill and server.
- Validate the packaged routing helper and its context-only output without permission overrides, runtime preparation, user-text reflection or local state changes.

## 0.6.55

- Route WorkBuddy's product entry to the fixed domestic Markdown guide and keep all client copy/app links consistent. Align both guide languages around native installation, supported reloads and direct completion evidence.
- Publish one canonical checksum for all eight host archives, retaining the matching six-entry host checksum for compatibility.
- Return installed version, location and separate login arguments from archive installers. Expose the responding server version and validated local instance identity in passive authentication and ready MCP status without changing legacy grants or recovery behavior.

## 0.6.54

- Trigger document capture for ordinary reading and analysis requests without requiring users to mention saving or Hipohipo. Keep read-only requests in the authorized background branch, respect explicit no-upload instructions, and retain engineering-file exclusions.

## 0.6.53

- Resolve Claude Code project/local installations from an exact native registration when user settings are absent, retaining shared-cache and symlink ownership checks.
- Recover missed first-use observations from commit-owned binding correlation; keep unknown legacy grants separate from pending consent without changing authorization identity or adding a state machine.
- Persist inherited telemetry opt-out before publishing a new or replacement instance, so interrupted setup cannot re-enable telemetry. Reuse never replays old preferences over a user's later choice.

- Resolve one persistent Hipo-managed instance across CLI, MCP, Hooks and sharing without requiring Agents to locate host data directories. Reuse healthy existing identities in place; preserve damaged state and authorize a replacement when recovery requires it.
- Keep setup status passive and return local diagnostic and cross-process journey identifiers, including failures before instance resolution.
- Correlate bounded setup, consent, activation, credential commit and first executed MCP tool milestones through privacy-filtered, unsampled lifecycle events. Web/API telemetry support must deploy before this plugin.
- Let client Agents choose supported native installation and recovery routes, with portable argument/environment examples and separate installation, login and MCP results.
- Respect custom Cursor ancestors and frozen helper identities; preserve legacy telemetry opt-out during recovery. Share credential metadata locking and validation, fence superseded login observations, and keep new-consent first use and refreshed client metadata independent of milestone deduplication.
- Require verified profile metadata when Claude relocates its plugin cache or setup uses an unbound state override. Persist new-instance authorization isolation in the first atomic descriptor write, including when initialization is interrupted; retain existing legacy migration policies.
- Reject plugin/cache directory symlinks that redirect cached profile discovery outside the selected profile. Validate each parent traversal before subsequent package aliases can conceal a profile change; preserve whole-profile aliases, safe parent segments and verified legacy instances.
- Initialize isolated native release-verification instances explicitly before exercising MCP, Hooks, installation and Codex capture. Keep authentication status passive and retain production identity checks.

## 0.6.52

- Allow up to ten seconds for the independent permission check on an actual
  background document save or companion read. Keep discovery bounded at two
  seconds and preserve noninteractive, fail-closed authorization.
- Preserve the original grant and request identity while allowing ordinary
  network latency instead of rejecting a valid passive Library read too early.

## 0.6.51

- Add `source.create_background` for proactive document saves, available only
  with write access and the connection's independent background-save permission.
  Check that permission again before issuing staging permits and accepting work.
- Let users choose automatic document saving during browser and device consent,
  enabled by default. Existing connections retain the enabled default.
- Replace document offers, native confirmation forms and WorkBuddy chat offers
  with one shared document-capture policy. Explicit saves continue using
  `source.create`; disabled background saves never fall back to that tool.
- Keep companion Library and Source-status reads noninteractive through the
  optional `isBackground` flag, including cold-start and expired credentials.
- Keep document reading independent of saving, preserve real-folder selection
  and upload retry identities, and exclude engineering files and drafts from
  proactive capture.

## 0.6.50

- Keep explicit CLI browser login in the foreground with one configurable total
  deadline, preserving the callback listener while the user approves consent.
- Return saved device prompts immediately with a complete public-code link and
  the reason for automatic browser-open or callback-listener fallback; resume
  the same code without another page launch.
- Explain foreground waiting, host tool budgets and alternative device consent
  in installation and login guides while reporting MCP availability separately.

## 0.6.49

- Resume an eligible partial runtime download after an explicitly requested retry, with a new bounded attempt and complete artifact verification.
- Continue the same device authorization code after the polling process stops; bounded CLI calls resume private instance-scoped polling without requiring another browser approval.

- Resume runtime preparation in bounded foreground calls using retained kernel locks, validated HTTP ranges and a single persisted 600-second attempt. Directory deletion and detached-process survival are no longer installation prerequisites.
- Preserve WorkBuddy's mainland mirror preference and one network fallback without discarding partial bytes, resetting deadlines or renewing the network retry budget.
- Isolate explicitly rejected legacy credentials per instance and continue an explicit login request into one new consent flow, without invalidating other hosts or reviving delayed authorization.
- Recover interrupted login helpers using kernel ownership and attempt fencing, without duplicating live consent or looping after another interruption.
- Require native instance data paths, distinguish pending consent from startup, and report actionable structured errors with complete command output and real exit status.
- Keep cold status observational and report installation/sign-in separately from host MCP availability.

## 0.6.48

- Mirror pinned runtimes and verified installation artifacts to mainland OSS during each release; activate the mainland version index only after stable publication.
- Prefer OSS runtime downloads in WorkBuddy, with bounded network fallback, unchanged digest verification and clean partial-download handling.
- Provide a Chinese WorkBuddy installation guide using a verified local marketplace and the current app's native installer.

## 0.6.47

- Complete installation sign-in through the installed CLI when host MCP tools are unavailable, retaining the same app/profile/instance binding.
- Add bounded `runtime-prepare` and structured CLI continuation; keep authentication status passive on cold installations and preserve explicit preparation retries.
- Share foreground login, existing-authorization reuse, refresh and pending consent behavior between CLI and MCP, including device login.
- Report host MCP enablement and loading separately from authorization, without private host registry edits or mandatory conversation changes.

## 0.6.46

- Consolidate installation, loading and sign-in into one shorter guide shared by all host READMEs and installer success messages.
- Identify the packaged install command as Cursor-only and document WorkBuddy child environment handling in Windows PowerShell.
- Distinguish installed updates from older live MCP connections, preserve newer installations and report version mismatches before sign-in.

## 0.6.45

- Use the verified Cursor release package for fresh local installations and keep upgrades on their existing installation channel.
- Make WorkBuddy installation an ordered bundled-CLI flow with child-environment handling before every call, native installation commands and explicit timeout recovery without manual registry writes.
- Distinguish installation approval blocks, cancelled invocations and command failures, and continue required approvals through the host's native flow.
- Complete setup when the loaded plugin confirms sign-in; remove separate Skills, Hooks and runtime readiness checks from installation acceptance.

## 0.6.44

- Document child-only removal of inherited session-server variables when invoking the bundled WorkBuddy CLI for plugin management.
- Clarify preservation of the current launcher, runtime, bundle selection, profile and proxy settings, and verification after startup queries recover.

## 0.6.43

- Use the remaining preparation budget when publishing verified runtimes, avoiding a separate two-second timeout on slower machines.
- Record publication failure stages and elapsed time, and retain bounded local publisher errors for diagnosis.
- Verify lock contention, expired attempts, failure diagnostics and successful retry on native platforms.

## 0.6.42

- Adapt installation and upgrades to the current app, execution environment and profile, with six evidence-based readiness checks.
- Preserve existing local Cursor packages when staging fails and avoid unconditional reload instructions.
- Return explicit setup continuation actions, reuse valid authorization and pending consent, and avoid recommending login for unrelated service failures.

## 0.6.41

- Shorten WorkBuddy setup to existing-install reuse and native installation steps.
- Use the installed application's bundled CLI and current WorkBuddy profile.

## 0.6.40

- Define an installation, preparation/login and readiness flow with host-specific
  installation entries and links to official guidance.
- Wait for installation and pending setup attempts to finish, and confirm runtime
  readiness, authorization and host-loaded components before reporting Ready.
- Report incomplete setup and concrete continuation steps when user action is needed.
- Provide a new-chat continuation prompt, reuse confirmed authorization, and include
  an optional memory-search example after setup.

## 0.6.39

- Require installation or reuse before checking loaded components, and reserve
  the waiting-for-loading status for an installed plugin.
- Allow available host-supported installation tools, CLI commands or plugin UI;
  distinguish these from directly launching a plugin runtime outside the host.
- Report an installation error or a required user action separately from loading.

## 0.6.38

- Reduce installation guidance to the official plugin name and repository, while
  retaining component checks, runtime preparation, browser login and completion
  reporting. Plugin inventory queries are no longer installation prerequisites.
- Retire the WorkBuddy installation helper and its bundled-CLI adapters. The web
  installation panel now provides the official repository for WorkBuddy.
- Preserve plugin runtime launchers, MCP, Skills, Hooks and existing user state.
- Remove retired helper restrictions from packaged documentation and document
  the x64/ARM64 runtime artifacts for macOS, Linux and Windows consistently.
- Keep Codex Desktop installation separate from optional CLI instructions.
- Publish WorkBuddy skill paths as an array and validate every directory during
  packaging, preserving compatibility with array-only manifest validators.

## 0.6.37

- Select the native Windows runtime consistently when Git Bash starts PowerShell
  under x64 emulation on ARM64, reusing the prepared native runtime for Hooks.

## 0.6.36

- Correct native release verification for supported Intel Macs and Windows path
  fixtures, and use executable suffixes on both Windows architectures.
- Retain the platform-neutral installation guide, cross-platform installers,
  consistent branding and document-capture scope from the preceding candidates.

## 0.6.35

- Read installation guides, Agent instructions, source code, and configuration for engineering tasks without document-save confirmation or Library lookup.
- Keep explicit requests to save those files in the existing consent flow, and retain ordinary supplied-document and completed-deliverable capture.
- Apply the same scope to Skill descriptions and bodies, Cursor rules, native MCP catalogs, and generated cold-start package instructions and consent-tool descriptions.

## 0.6.34

- Keep the shared installation rules platform-neutral and describe WorkBuddy
  helper behavior only in its own installation section.

## 0.6.33

- Keep the Hipo Hipo display name and the same 512-pixel brand icon across
  Cursor, Claude Code, Codex and WorkBuddy packages, including standalone archives.
- Declare native icon fields for each host and reject missing, changed or
  inconsistent branding during marketplace verification.

## 0.6.32

- Resolve WorkBuddy's bundled runtime and product-owned profile across macOS,
  Windows and Linux, including regional editions and custom application paths.
- Provide native Windows installation commands for Cursor and WorkBuddy.
- Publish Intel Mac and Windows ARM64 runtimes alongside existing artifacts,
  and select Windows runtimes using the native OS architecture.

- Allow the WorkBuddy installer to check native CLI compatibility after app
  upgrades instead of requiring WorkBuddy AI 5.8.4. Preserve product, profile,
  official-source and installation checks.
- Remove the installer OS/architecture whitelist and the fixed app version and
  platform restrictions from the shared guide and web installation text.

## 0.6.31

- Share a fixed snapshot of the current conversation through host-native commands,
  with selected-branch readers for Cursor Desktop, Cursor CLI, Claude Code,
  Codex CLI and WorkBuddy Desktop.
- Freeze original user and visible assistant text before login or upload; resume
  interrupted private uploads without recapturing or mixing accounts.
- Keep Codex share Skills under a host-specific marketplace path and preserve
  each host's native command identity and plugin data directory.
- Reject unsupported or uncertain branch shapes explicitly. Cursor Desktop's
  immediate share after edit/resubmit rewind remains unaccepted; WorkBuddy's
  accepted entry is the fully typed `/hipo-share`, with local Desktop fork
  unsupported and its `@skill` picker unreliable.

- Validate native Windows paths and platform file metadata with host-appropriate
  fixtures, and keep concurrent Cursor database tests faithful to native WAL stores.

## 0.6.30

- Unpublished Shared Conversation candidate, superseded by 0.6.31. Its source tag
  remains unchanged.

## 0.6.29

- Keep the plugin tool catalog available before preparation and authorization,
  with foreground login and refresh that can continue in the same conversation.
- Make discovery and status passive; retain terminal cancellation/logout stops
  and prevent an abandoned operation from executing after recovery.
- Bound complete preparation attempts, including publication, to 600 seconds.
- Add a guarded WorkBuddy AI 5.8.4 macOS ARM64 installer using its bundled CLI,
  plus one shared installation guide with existing-install reuse and component evidence.


## 0.6.28

- Resolve the effective Windows Cursor profile from its native ancestor process
  when the host does not expose its configuration directory through environment
  variables. Establish the local instance required for import consent instead of
  silently continuing with legacy authorization.
- Verify native profile propagation with paths containing spaces and Unicode;
  reject conflicting arguments, unrelated processes and reused parent IDs.

## 0.6.27

- Explicitly select Cursor's MCP configuration in the shared plugin package so
  Claude Code's configuration cannot supply Cursor's host or state directory.
- Reject missing or foreign Cursor MCP paths and launch parameters during
  marketplace verification, including packages containing both MCP files.

## 0.6.26

- Open the Cursor account credential database with a valid Windows SQLite file
  URI. Drive-letter paths remain local, read-only and correctly escaped, allowing
  account-rule collection and recovery to reach the existing reader contract.

## 0.6.25

- Import Cursor account User Rules through a bounded, read-only request using
  the current local Cursor login. Credentials stay between the device and Cursor;
  the plugin never refreshes a Cursor session.
- Freeze returned rule bodies once per import and retain source provenance through
  the existing private upload and Memory capture pipeline. Interrupted account
  reads report incomplete coverage without silently replacing a task's sources.
- Distinguish missing login, rejected credentials, account changes, unsupported
  responses, and limited account coverage while continuing eligible local sources.

## 0.6.24

- Import eligible user-level rules and local memories from Cursor, Claude Code, Codex, and WorkBuddy into the authorized Hipo Project, including best-effort formal file references and local WorkBuddy account caches.
- Keep one active import per Project, immutable file selection and resumable uploads, bounded file concurrency, Stop and revocation cutoffs, file progress, and source Evidence.
- Bind each app/configuration instance to its own authorization and carry a browser-selected authorization/import request through the existing Allow flow without collecting files before independent activation.
- Prepare a distinct WorkBuddy host package with transcript-backed conversation capture and conversational document consent; native host/platform acceptance is recorded separately.
- Add instance-bound device authorization for SSH and headless login, including a public verification URL/code in login status and explicit CLI/MCP device mode.
- Preserve prior credentials when login fails, and cancel pending device login during explicit logout. Existing independent authorization remains in place until explicit logout.
- Revoke staged instance grants after local logout when server activation completed before its response was canceled, and retain a clear diagnostic if remote revocation cannot be confirmed.


## 0.6.23

- Handle MCP process SIGINT and SIGTERM through normal cleanup, cancelling admitted requests and allowing the existing bounded telemetry flush and runtime lease release to run. Preserve ordinary stdin EOF draining and short Hook behavior.

## 0.6.22

- Correlate each capture upload span and warning/error log with its durable submission key, delivery attempt, and acknowledged receipt. Preserve independent error logs when traces are not sampled.
- Add opt-in sustained telemetry failure and live restart acceptance fixtures. Verify bounded memory, business responses, recovery and shutdown across collector failures.
- Provide a verified schema-5 rollback-copy tool that preserves work admitted after schema-6 upgrade; retain the original store and trace metadata.

## 0.6.21

- Add sampled OpenTelemetry traces and independent warning/error logs through the trusted Hipo ingestion endpoint. Retain local JSONL diagnostics and exclude conversation content, MCP arguments/results, credentials, URLs and filesystem paths from exported records.
- Preserve request trace context across concurrent MCP requests and durable capture delivery retries. Add optional trace context columns in local schema version 6 without changing queued payloads or idempotency keys.
- Keep short Hook processes free of exporters and network flushes. Bound in-memory queues, export batches and shutdown time; telemetry failure never changes business delivery.
- Enable telemetry by default, with `telemetry status`, `telemetry enable` and `telemetry disable` commands; `HIPO_TELEMETRY_ENABLED=false` overrides the local preference.

## 0.6.20

- Cancel the temporary MCP shutdown timer without triggering a macOS system-shell signal race. Preserve the native runtime's existing graceful-exit and escalation windows.

- Keep Cursor, Claude Code and Codex Hooks limited to durable notification recording and background-worker handoff. Read transcripts, reconcile message versions and upload in the bounded worker; recover retained notifications after failed launch or shutdown without extending host deadlines.

- Open an already migrated local capture store without rerunning migration writes, avoiding unnecessary writer contention with detached workers. Preserve serialized migration and future-schema rejection.
- Show the server-verified Hipo Account ID, email, Project and verification time on explicit authentication status requests. Preserve the last verified identity for offline display with an explicit historical label.
- Bind the private identity cache to the credential lifecycle, discard replies that race account changes, and invalidate cached identity on logout or confirmed authorization rejection. Identity lookup and cache failures do not block collection or upload.
- Include the client-reported runtime version as optional upload metadata. Existing queued request bodies and idempotency keys remain unchanged.
- Requires the additive Hipo identity endpoint for online identity display; older servers and offline requests retain ordinary authentication status. No local capture schema migration is required.

## 0.6.19

- Separate terminal notification handling from durable source follow-up across Codex, Claude Code, and Cursor. Recheck supplied sources on later plugin activity without requiring another Hook from the same conversation, adding a daemon, or expiring late-write follow-up.
- Preserve aborted and error outcomes across restart. Use unambiguous native Codex abort ranges to resolve legacy interruption receipts and cancelled unconfirmed prompts, without uploading tentative Hook text or matching an earlier identical prompt.
- Expose `followUpSources` separately from unresolved Hooks, known source gaps, queued message versions, and upload parts. Preserve existing capture identities and immutable upload requests through local schema version 5.
- Add terminal lifecycle, late-write, restart, migration, and transaction rollback regressions, plus compiled recovery and native producer checks. Document the collection architecture and approved recovery policy.

## 0.6.18

- Recognize Codex inter-agent scheduling metadata without creating false source-recovery tasks, and exclude inter-agent model input from displayed assistant replies while preserving legacy assistant events.
- Correlate native completion and Hook text after Codex removes Memory citation markup for display. Preserve original message versions, queued payloads, and native task evidence; mismatched visible replies remain pending.
- Preserve the original prompt across compaction during a turn while requiring a new assistant reply after the boundary. Verify first/resumed/compacted native CLI rollouts with a raw Memory citation and its rendered completion.

## 0.6.17

- Confirm delayed Codex completion Hooks from unambiguous persisted task boundaries and canonical final replies, including replies already queued before the Hook or followed by later turns. Reused turn IDs, missing completion evidence, and replies changed after completion retain recovery.
- Support native completions without optional message IDs or phase, exclude explicitly marked internal compaction output from conversation, and require fresh user association after an in-turn compaction boundary. Verify actual Codex 0.163.0 first/resumed/compacted rollouts against an isolated loopback model and compiled capture process.
- Confirm older Claude replies using an explicit native prompt ID, and Cursor replies using a durable generation-to-prompt association in a continuous supplied source. Retain ambiguous, reused or missing associations; never infer a missing Claude Stop ID from the newest prompt. Exclude native generated API/control replies during Claude resume.
- Separate confirmed Hooks from durable per-source recovery tasks. Continue recovery without another Hook, preserve queues during local schema version 4 migration, and report independent `recoverySources` alongside retained Hook and message-version counters. Continuous Codex raw history can advance across context compaction; genuinely incomplete or rewritten sources retain recovery.

## 0.6.16

- Complete local logout even when the old remote authorization cannot be revoked; retain pending history and suppress automatic login.
- Save new login credentials before attempting bounded cleanup of the previous grant; preserve the previous credentials when authorization is canceled or saving fails.
- Retry a temporary refresh failure once, require explicit login for terminal refresh errors, and retain credentials on network failures.
- Restore executable fallback scripts and select Codex host state explicitly in recovery commands.

## 0.6.15

- Confirm a single document and its recommended destination with one answer; ask further questions only when changing the location.
- Select multiple documents before confirmation using All files, Other, or Don't save; validate manual file numbers or filenames inside the native form.
- Show real filenames in each relevant question, preserve the original task after skipping, and protect each confirmation step against stale or concurrent submissions.

## 0.6.14

- Display the Cursor plugin as Hipo Hipo while preserving the hipohipo installation identifier, commands and persistent data.
- Document how to rename Cursor's separately managed marketplace title without changing repository or plugin identifiers.

## 0.6.13

- Retry temporary public runtime download 404s after immutable uploads for up to two minutes per platform, including recovery when the upload response is lost.
- Preserve checksum and pinned URL validation, avoid duplicate uploads, and report public-read attempts and visibility timeouts during publication.
- Include the incremental conversation capture and display name changes prepared in 0.6.11 and 0.6.12, whose publication did not complete.

## 0.6.12

- Display the plugin as Hipo Hipo in Codex and Claude Code while retaining the hipohipo identifier for installation, updates, commands and persistent data.

## 0.6.11

- Capture new message occurrences and complete changed versions, including interrupted replies, with progress committed atomically to the local upload queue.
- Preserve captured history across rewinds and retain recovery evidence for sparse sources, delayed writes and host exits; keep unconfirmed Hook text tentative.
- Collect Claude failure and Codex interruption events, retain Codex environment context, and report message offsets and pending recovery in local diagnostics.

## 0.6.10

- Read Claude Code transcripts to retain earlier user turns and intermediate assistant text, with bounded retries and Hook-only fallback for unavailable history.
- Upload all available history on the first durable capture, then only the latest completed user turn across Claude Code, Cursor, and Codex; repeated completion Hooks send no additional request.
- Preserve completion identities after cached text expires, migrate available legacy fallback identities, and keep retry payloads and idempotency keys unchanged.
- Align Codex history to the completed Hook turn, avoid concurrent SQLite startup failures, and recognize Claude resume mode metadata without reporting a false history gap.

## 0.6.9

- Verify disabled App discovery and cached resource rejection in the compiled native MCP checks, including modern discovery-first clients.
- Automatically request verified publication when a stable plugin version increase is merged into Hipo main, preserving existing tags and recovering interrupted dispatches.
- Include the form-only document confirmation and authenticated status-discovery changes prepared in 0.6.8, whose release was blocked by the outdated App check.

## 0.6.8

- Temporarily disable MCP Apps and use native form elicitation for document confirmation across all clients.
- Hide App tool metadata, UI resources and the App-only selection tool; reject cached App requests while disabled.
- Hide `auth.status` from authenticated tool catalogs and guide Agents to use business tools without status preflights.
- Preserve status recovery before login and manual diagnostics, with updated plugin instructions and protocol contracts.

## 0.6.7

- Keep cold MCP connections alive with immediate discovery and temporary `runtime_prepare` and `runtime_status` tools instead of exiting during downloads.
- Bound each preparation tool wait to 30 seconds, keep ping and cancellation responsive, and retry failures automatically after three minutes while connected.
- Initialize the verified runtime and refresh business tools over the same connection, preserving authorization and document-confirmation instructions.
- Share downloads across Hooks, tools and connections, recover incomplete preparation locks, and preserve Unicode request IDs on Windows.
- Verify slow downloads, cooldown recovery and the same-connection transition with the actual Go runtime on native platforms.

## 0.6.6

- Replace four bundled native Go launchers with system shell and PowerShell scripts; keep the full Go program in the verified, versioned user cache.
- Preserve background preparation, fast Hook fallback, the eight-second MCP wait, manual retry, proxy settings, runtime leases and cache cleanup.
- Resume interrupted downloads within a configurable ten-minute preparation budget, verify both archive and executable digests, and recover abandoned preparation locks.
- Verify cold preparation over HTTPS and actual Codex plugin discovery on native platforms, including Windows pipe isolation and filtered MCP environments.

## 0.6.5

- Share one self-contained plugin directory across Cursor, Claude Code and Codex, with one copy of each platform launcher and shared resource.
- Publish a single root commit and atomically move all public release tags to that snapshot, keeping historical release attachments and pinned runtime downloads.
- Preserve client-specific Hook and MCP declarations, including Cursor archive installation with its manifest-selected Hook file.

## 0.6.4

- Prefer MCP Apps for document confirmation and use native form elicitation when Apps are unavailable and the client supports forms.
- Support legacy callbacks and modern request continuations; continue without uploading when native confirmation is unavailable, skipped or cancelled.
- Bind confirmation to its identity, revision, expiry and credentials, and reject superseded cards after an explicit form retry.

## 0.6.3

- Resolve Cursor Hook scripts from the installed plugin root so capture can finish when Stop runs from the workspace directory.
- Forward Codex's explicitly configured runtime cache and host state directories to its MCP process, keeping MCP and Hooks on the same configuration.

## 0.6.2

- Keep the installed MCP configuration on the package-root launcher, matching the Hook entrypoint across hosts.

## 0.6.1

- Use the installed root launcher as the MCP entrypoint so host-specific platform paths remain internal to the launcher.

## 0.6.0

- Download and verify only the matching platform program from public Vercel
  Blob storage; plugin packages contain native launchers instead of full
  all-platform programs.
- Reuse verified downloads across clients with fixed version binding, bounded
  preparation retries, explicit retry/status and download proxy controls.
- Keep preparation and capture diagnostics locally with bounded rotation;
  protect running versions during automatic cache cleanup.

## 0.5.14

- Publish the cross-platform Codex client verification fixes and keep release
  validation reliable on isolated Windows, Linux, and macOS environments.

## 0.5.13

- Use a package-relative Codex MCP command and working directory instead of
  unsupported legacy MCP placeholders.
- Keep Codex MCP, Hooks, workers, and manual commands on the same persistent
  OS application-data directory, with an optional `HIPO_CODEX_STATE_DIR` override.
- Remove the unsupported top-level version field from Codex Hooks configuration.
- Verify Codex package loading with the actual client, alongside native process
  contracts; retain the existing Cursor and Claude Code connection paths.

## 0.5.12

- Support discovery-first MCP clients using protocol revision 2026-07-28.
- Return revision-correct document, authentication, and resource results, including
  required result discriminants, cache hints, and plugin server identity.
- Include plugin instructions in both modern discovery and legacy initialization.
- Deliver local authorization tool-list changes through modern stdio subscriptions.
- Preserve legacy resource subscriptions and existing remote HTTP MCP forwarding.

## 0.5.11

- Describe memory search, library search, automatic capture, and document selection
  consistently across Cursor, Claude Code, and Codex.
- Clarify browser authorization, shared plugin grants, local collection, and retention.
- Explain card confirmation as an Agent upload request and distinguish upload,
  parsing, memory extraction, and receipt notification states.
- Include privacy and support information in every client package.

## 0.5.10

- Bridge host resource subscriptions to authenticated remote receipt streams.
- Recover missed receipt updates through reconnect invalidation and fresh reads.
- Cancel streams on unsubscribe, authorization changes, and MCP process exit.
- Keep Hook upload acknowledgements separate from MCP operation receipts; Hooks
  do not wait for memory extraction.
- Preserve ordinary HTTP MCP tool/resource forwarding and plugin-owned OAuth.

## 0.5.9

- Pass the WSL browser URL through PowerShell UTF-16LE `-EncodedCommand` instead
  of Linux environment variables, which are not inherited by Windows programs.
- Verify URL delimiters and Unicode against real Windows PowerShell when
  running tests in WSL.

## 0.5.8

- Prefer Windows PowerShell `Start-Process` in WSL when `wslview` is not
  installed, before falling back to `cmd.exe`.
- Name the Claude Code command `login`, producing `/hipohipo:login` without a
  duplicated plugin prefix.

## 0.5.7

- Open OAuth in the Windows browser from WSL through `wslview` or `cmd.exe`
  when no Linux browser is installed.
- Keep ordinary Linux and macOS browser launch behavior unchanged.

## 0.5.6

- Use the system credential manager when available and a private filesystem
  credential file on any supported platform when its manager is unavailable.
- Keep MCP, Hooks, login, logout and workers on the same state-directory-backed
  credential adapter.

## 0.5.5

- Use the same local stdio MCP transport in Cursor, Claude Code and Codex.
- Let Claude Code start the packaged Go MCP process directly, sharing the
  plugin-owned credential store and state directory with its Hooks.
- Keep the existing remote HTTP MCP unchanged for web and legacy integrations.

## 0.5.4

- Publish one `hipohipo` entry per client; Claude Code and Codex automatically select the native program, matching Cursor's installation experience.
- Include macOS ARM64, Linux AMD64/ARM64 and Windows AMD64 programs in each host-specific package without downloads at startup.
- Keep separate host indices and manifests; verify the unified launch commands and binary provenance in CI.
- Replace 0.5.3 platform-labelled entries. Remove the old entry in the affected client before installing `hipohipo`, without deleting persistent data or revoking shared credentials.

## 0.5.3

- Publish separate Cursor, Claude Code, and Codex marketplace indices in the same public repository.
- Include complete platform-specific Claude Code and Codex plugin directories for repository installation, with their native MCP, Hooks, executable, and document-capture Skill.
- Verify public repository entries and native programs in the release pipeline; preserve the existing Cursor entry and HTTP MCP behavior.

## 0.5.2

- Accept the UTF-8 BOM added by Windows PowerShell to Cursor Hook input, restoring conversation capture without changing the capture API.
- Verify installed Windows Hooks through Cursor's temp-file/PowerShell pipeline rather than only a direct stdin pipe.

## 0.5.1

- Preserve intermediate assistant commentary when Cursor Hooks supply only the final reply; align exact message boundaries without accepting arbitrary text suffixes.

## 0.5.0

- One `hipohipo` plugin entry automatically selects macOS ARM64, Linux x64/ARM64 or Windows x64.
- Shared Shell/CMD Hooks entry without Node.js, Python or Git Bash dependencies.
- Unified release archives and native verification of exact marketplace launch commands.
- Local installation retains direct native MCP launch and versioned runtimes.
- Existing credentials, history and remote HTTP MCP behavior remain compatible.

## 0.4.0

- Complete native Cursor plugin packages for macOS ARM64, Linux x64/ARM64 and Windows x64.
- System credential storage, platform browser opening, process locks and detached delivery.
- Cursor authentication tool aliases remain callable before login.
- Direct native MCP launch without Node.js or a user-installed Go runtime.
- Versioned local runtime installation and persistent external capture state.
- Capability-based plugin descriptions, installation guides, privacy and support documentation.
- Native platform verification and reproducible multi-platform publishing through CI/CD.

## 0.3.0

- Embedded MCP App for document selection with real library folders.
- Agent Rule and Skill for supplied files and completed documents.
- Confirmation resumes existing Source creation/upload; Skip continues the original task.
- Stable Apple Silicon package published through CI/CD.
