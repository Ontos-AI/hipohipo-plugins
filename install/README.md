# Install Hipohipo

Install or update `hipohipo` to the latest stable non-draft release in the active
client, complete sign-in, and verify the current MCP connection. Do the available
work yourself; explain only actions requiring the user. Adapt command examples to
the client's actual capabilities. Test-machine versions, usernames and absolute
paths are not prerequisites.

## 1. Install or update

Reuse verified client, environment, active profile, channel and scope. Once the
route and target version are known, perform the necessary native install/update;
reuse a matching installation and never downgrade a newer one. Register or refresh
its marketplace only as needed. Downloading or listing a marketplace is not installation.
Consult help or the verified package's `SUPPORT.md` for missing information or errors.

Keep diagnostic stdout/stderr and the installer's actual exit status. Summaries
and output filters are allowed if original diagnostics and results remain available;
a filter's exit status alone does not prove installation success.

| Client | Installation route |
| --- | --- |
| Cursor | Keep an existing marketplace channel. For local installation, download the stable Cursor archive, verify the exact filename against `SHA256SUMS-<version>.txt`, extract it, and run its `hipohipo install` (`hipohipo.cmd install` on Windows). This installer is Cursor-specific. |
| WorkBuddy | Prefer native third-party plugin controls; otherwise resolve this app's bundled CLI/runtime from installation metadata and its package `bin` entry. Use the domestic source below. |
| Claude Code, Codex | Use native plugin controls or this installation's CLI with `https://github.com/Ontos-AI/hipohipo-plugins`. Follow the supported marketplace install/update route. Examples include `claude plugin install` and `codex plugin add`; they are not a checklist. |

The main `SHA256SUMS-<version>.txt` covers all eight client archives.
Verify installed version, source, scope and enabled state from native results,
available inventory or returned package metadata; no particular query is mandatory.

### WorkBuddy domestic source

**Remove `SERVER__PORT` and `SERVER__HOST` only from every independent WorkBuddy CLI
child, starting with its first invocation.** They can cause the CLI to inherit host
service mode and refuse commands. Preserve the parent environment, proxy, working
directory, runtime arguments and active profile. Its internal `codebuddy` entry
is not the standalone CodeBuddy product.

Read `https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/releases/latest.json`.
Require `schemaVersion: 1`, a valid stable version, a complete `sourceCommit`, and
package URLs on the same OSS host under `hipohipo/releases/<version>/`.
Download `marketplace.url` and verify its byte size and SHA256; stop on mismatch.
Before extraction, require all entries to stay inside `hipohipo-plugin-marketplace/`,
without absolute paths, `..`, symbolic links or hard links. Match `release.json`
version and source commit to the index; require `.codebuddy-plugin/marketplace.json`
and `plugins/hipohipo-workbuddy/`. Use available tools; do not require users to install
Go, Node.js or Python. This route needs no GitHub version or guide lookup.

Keep the complete marketplace in a persistent user-writable location, separate
from the host-managed plugin cache. Stage and verify updates, preserving the old
source, authorization and capture state until the native update succeeds. Use
supported marketplace registration and install/update controls as needed, for example
`plugin marketplace add <complete-marketplace-directory>` and
`plugin install hipohipo@hipohipo-plugins --scope user`, or the native update command
for an existing installation. A Skill upload is not full plugin installation.

Do not delete locks, edit private registries, silently remove marketplaces, enable
duplicate plugins, disable safety protections or bypass host protection. After an
error, check actual installed state before repeating installation; see `SUPPORT.md`.

## 2. Reuse authorization or sign in

Reuse valid authorization, including read-only grants. Otherwise use authentication
tools belonging to the selected installation, or its installed CLI if MCP is not
loaded yet. For example, `./hipohipo login --host "$targetHost"`, with the verified
host `cursor`, `workbuddy`, `codex` or `claude-code`; use the installed `.cmd` entry
on Windows. Preserve configuration and overrides; quote paths and pass separate arguments.

**Do not search for or invent `--state-dir`.** The plugin locates or creates its
persistent instance. Healthy old instances remain in place. Missing legacy status
fields do not justify discarding a valid grant. Never inspect credentials.

Tell the user before consent and show returned browser/device links and public
user codes immediately. Wait for the current login and follow its `nextAction`;
continue the same pending flow after approval. Do not start parallel logins or
retry automatically after refusal, cancellation or terminal failure. Recovery and
timeout details are in `SUPPORT.md`; new sign-in does not establish historical-data recovery.

## 3. Load and verify

After sign-in or reuse of valid authorization, check the current MCP target version.
If tools are unavailable, including after first installation, or still run the old
version, wait once for **30 seconds**, then rediscover tools and check again. Skip
waiting when already loaded. Waiting alone never proves loading or completes a
pending setup action. If still unavailable or outdated, continue with loading below.

- WorkBuddy: ask the user to quit and reopen the app normally, then resume this
  installation conversation. A new conversation may retain an old shared connection.
- Cursor: for local plugins, use the documented `Developer: Reload Window` only
  when exposed in the current interface; otherwise restart Cursor normally.
- Claude Code, Codex: use the current client's documented loading flow; if this
  session cannot load the update, continue verification in a fresh client session.

Enable MCP only if it is actually disabled. An installer's suggested command alone
does not establish that this client exposes it. When another conversation/session
is needed, give the user a short follow-up carrying the installed target version
and completed steps. Preserve completed sign-in; do not reinstall or log in again
solely for loading, or repeat the loading wait.

Confirm authorization and the responding MCP `serverVersion`; CLI status or an
enabled setting alone cannot prove MCP loading. Reuse one sufficient status result.
Report installation, sign-in, loading and any remaining user action; keep loading
pending until verified and retain diagnostic IDs for failures. Stop after setup,
without extra business searches, uploads, Skills/Hooks or capture tests.
