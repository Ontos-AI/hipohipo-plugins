# Changelog

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
