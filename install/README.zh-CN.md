# Install or update Hipohipo

Install Hipohipo in the app running this conversation using its existing configuration.
Select additional apps only when the user requests them.

## 1. Download the installer

- WorkBuddy: use the [Aliyun OSS installer index](https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/installer/releases/latest.json).
- Other apps: use the [Vercel Blob installer index](https://zwtuvd9pqclibkom.public.blob.vercel-storage.com/hipohipo/installer/releases/latest.json); if that index is unavailable, use the OSS index above.

Choose the archive matching this computer's operating system and CPU architecture,
download its `url`, verify its size and SHA256, and extract it.

## 2. Run the installer

From the extracted directory, run the command for the current app:

| Current app | Command |
| --- | --- |
| Cursor, through its Claude compatibility import | `./hipohipo-installer install --host claude-code` |
| Claude Code | `./hipohipo-installer install --host claude-code` |
| Codex | `./hipohipo-installer install --host codex` |
| WorkBuddy | `./hipohipo-installer install --host workbuddy` |

On Windows use `hipohipo-installer.exe` instead of `./hipohipo-installer`.

If the result's `nextAction` is `run_host_update`, the app manages this installation:
run each `hostUpdate.commands` entry in order, then restart the app.

## 3. Load the plugin and reuse authorization

Follow the app's normal plugin loading and Hook-review flow. Reconnect MCP or
start a new conversation when required, then call the current Hipohipo MCP
`auth.status` tool. A downloaded source or installed manifest does not prove
that this conversation loaded the new version.

The installer quietly preserves or reuses available authorization through the
plugin's business login interface. It does not open a browser for Hipohipo
sign-in.
Keep a valid grant, including a read-only grant. If sign-in is needed, call
`auth.login`, show its authorization link and public code, and continue that
same flow after the user authorizes it. Do not copy credential files between
apps or start parallel login attempts.

On macOS and Linux, installing or updating for Claude Code or Cursor also
prepares background tasks: for each of Claude Code and Cursor present on this computer,
the installer installs its CLI when missing and, if that CLI is signed out,
opens the vendor's sign-in page once and waits. Tell the user before running
the installer that a Claude or Cursor sign-in page may open. The result's
`backgroundAgents` lists each agent as `ready`, `install_failed` or
`login_incomplete`; the last two do not fail the installation.

## 4. Confirm completion

Call the current conversation's Hipohipo MCP `auth.status`. If it answers and
the installed and responding plugin versions match, tell the user Hipohipo is
ready and whether sign-in is still needed.

Only if this conversation cannot use Hipohipo's tools yet, or still answers with
the previous version: most apps load a newly installed or updated plugin only
after their own loading step, so this is the normal result, not a failure. Tell
the user, in the conversation's language, that Hipohipo is installed and to
open a new conversation to start using it (Cursor: quit and reopen the app),
for example "Hipohipo is installed. Open a new conversation to start using it."

Keep the reply short. Mention the update owner, authorization or
`backgroundAgents` details only when they need the user's attention. For
installation diagnostics, use the package's `SUPPORT.md`. If the WorkBuddy
installer fails before the package is installed, use the
[public WorkBuddy SUPPORT.md](https://raw.githubusercontent.com/Ontos-AI/hipohipo-plugins/main/plugins/hipohipo-workbuddy/SUPPORT.md).
