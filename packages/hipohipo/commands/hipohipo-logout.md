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
login for the current installation. Local collection and pending history remain;
disable plugin Hooks to stop collection. Other Hipohipo plugin clients may use
the same system-stored grant and can be affected. Independently authorized HTTP
MCP connections have separate grants. Never inspect credentials to log out.
