---
name: hipohipo-status
description: Check Hipohipo login and conversation capture status
---

This command is for an explicit user status request, not routine checks before
business tools. Use `auth.status` when listed; it is hidden after login.
Otherwise use `scripts/run.cmd auth-status` for login status. For capture counts
and coverage, run `scripts/run.cmd status` from this command's installed plugin
directory. Resolve the installed directory from this command's source location.
If unavailable, direct the user to the status wrapper in the extracted package.

Report authorization state, relevant counts, known history gaps, and errors.
Distinguish queued, admitted, and extracted history; do not claim memories are
searchable solely because upload was accepted. Omit transport URLs and internal
identifiers unless needed for the user's specific diagnosis. Do not print
credentials or conversation content, inspect the capture database, or search
for `STATUS.md`; the plugin does not generate that file.
