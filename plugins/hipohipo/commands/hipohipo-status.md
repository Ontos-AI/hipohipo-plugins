---
name: hipohipo-status
description: Check Hipohipo login and conversation capture status
---

This command is for an explicit user status request, not routine checks before
business tools. Use `auth.status` to observe local state; it does not contact
the service, refresh credentials or start login. Cached identity is last verified.
Otherwise use `scripts/run.cmd auth-status` for login status. For capture counts
and coverage, run `scripts/run.cmd status` from this command's installed plugin
directory. Resolve the installed directory from this command's source location.
If unavailable, direct the user to the status wrapper in the extracted package.

Report authorization state, relevant counts, known history gaps, and errors.
Include the Hipo Account ID, email when available, and Project ID returned by
`auth-status`. For `identity.status = verified`, describe them as verified at
`verifiedAt`. For `last_verified`, say "Last verified account" with that time;
current authorization and email remain unconfirmed. If no identity is returned,
say identity is unavailable. Never decode tokens or infer identity from another
host. Identity lookup does not start login and is only for explicit status requests.
Separate actual upload parts from retained Hook events. Use
`waitingForSourceEvents`, `awaitingConfirmationEvents`, and `recoveryEvents`
to explain pending capture work; none is a missing-message count.
`recoverySources` counts known source gaps. `followUpSources` counts retained
sources eligible for late-write checks on later plugin activity; a follow-up
alone does not mean content is missing or an upload failed. A handled terminal
notification can have follow-up remaining. Report this explicitly rather than
calling the entire conversation complete. No permanent background process
checks sources while the plugin is not running.
`queuedMessageVersions` shows locally handled versions even when a sparse
history leaves the reliable full-history offset unchanged.
Distinguish queued, admitted, and extracted history; do not claim memories are
searchable solely because upload was accepted. Omit transport URLs and other internal
identifiers unless needed for the user's specific diagnosis. Do not print
credentials or conversation content, inspect the capture database, or search
for `STATUS.md`; the plugin does not generate that file.
