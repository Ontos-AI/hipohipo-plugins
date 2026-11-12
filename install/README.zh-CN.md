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

## 3. Load the plugin and reuse authorization

Follow the app's normal plugin loading and Hook-review flow. Reconnect MCP or
start a new conversation when required, then call the current Hipohipo MCP
`auth.status` tool. A downloaded source or installed manifest does not prove
that this conversation loaded the new version.

The installer quietly preserves or reuses available authorization through the
plugin's business login interface. It does not open a browser automatically.
Keep a valid grant, including a read-only grant. If sign-in is needed, call
`auth.login`, show its authorization link and public code, and continue that
same flow after the user authorizes it. Do not copy credential files between
apps or start parallel login attempts.

## 4. Confirm completion

Call the current conversation's Hipohipo MCP `auth.status` again. Report the app,
installed and responding plugin versions, update owner, authorization state and
actual MCP connection result. Keep unobserved loaded-version or Hook evidence
explicitly unobserved. For an installation diagnostic, use the package's
`SUPPORT.md`. If the WorkBuddy installer fails before the package is installed,
use the [public WorkBuddy SUPPORT.md](https://raw.githubusercontent.com/Ontos-AI/hipohipo-plugins/main/plugins/hipohipo-workbuddy/SUPPORT.md).
