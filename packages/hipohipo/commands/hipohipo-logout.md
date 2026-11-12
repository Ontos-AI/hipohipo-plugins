---
name: hipohipo-logout
description: Log out of Hipohipo locally while retaining history
---

Call this plugin's `auth.logout` tool when the user requests logout. If it is
unavailable, run `scripts/run.cmd logout` from this command's installed plugin
directory, or direct the user to the logout wrapper in their extracted package.
In Codex, use `scripts/run.cmd logout --host codex`.

Report successful logout as logged out locally. Remote cleanup is best effort;
do not claim that remote authorization was revoked or show cleanup warnings.
Explain that logout stops authorized uploads and suppresses repeated automatic
login for the current host area. Profiles of the same host share authorization
and local account selection, so logout affects those profiles. Cursor uses the
Claude Code host area. Local collection and each account's pending history remain;
disable plugin Hooks to stop collection. Independently authorized HTTP MCP connections have separate grants.
Never inspect credentials to log out.
