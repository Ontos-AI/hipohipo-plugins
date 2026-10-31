# Install or update Hipohipo

Install or update Hipohipo in the active client, reuse valid authorization or
complete sign-in, and verify the current MCP connection. Do the available work
yourself; explain only actions requiring the user.

## 1. Install or update

Use the active client's effective configuration. Preserve the configuration
directory and environment supplied by the host, along with existing authorization
and history. Keep verified existing channels and scopes; do not install a second
active copy or downgrade a newer version.
For an ordinary update, keep the same entry, source and scope; do not disable or uninstall
it first. Preserve update preferences. Do not re-enable automatic updates that the user has disabled
unless they request that change.

If a Hipohipo update notice brought you here, finish the current operation first.
Use the status command included in that notice, with its exact executable and
profile arguments, before acting. It runs `update-notice status` for the active
client. Ignore a disabled or withdrawn notice. Recheck the
effective installed version; if it already meets the target, do not reinstall.
An installed version outside the notice's affected range also needs no reinstall;
if the connected MCP remains affected, explain only the required loading action.
Verify the currently connected MCP before explaining any required reload, and
do not close or restart the host automatically. Attempt the update once through
the existing channel; report a failure without an automatic retry loop. Notice
preferences are described in the installed package's `SUPPORT.md`.

Determine the target version from the official stable release before installing
or updating. Cursor, Claude Code, Codex and existing WorkBuddy Git installations use the
[official stable release](https://github.com/Ontos-AI/hipohipo-plugins/releases/latest);
WorkBuddy's domestic route uses the version index in **WorkBuddy domestic source** below.
Keep this target for the installed-package and MCP checks. If the existing source
cannot provide the target, report the gap without silently changing its source
or pinned revision.

For a first installation, choose the client route below using supported CLI/API
operations. Run the selected action without first requiring a complete plugin
inventory. An inventory failure alone does not block an explicitly requested
first installation. For an existing installation, reuse the host's available
active-installation information. Clarify conflicting installation information
before choosing a route. Cached packages alone do not establish an active installation.

Use only supported CLI/API operations. Do not automate desktop, browser or terminal menus,
or call undocumented installation APIs. Explain any required UI action to the user.
Keep stdout/stderr and the command's actual exit status for troubleshooting.
Use the host's normal per-command approval for blocked network or file access.
Command examples apply only to the matching client and task; adapt paths,
arguments and shell syntax to the actual installation.

| Client | First installation | Existing installation |
| --- | --- | --- |
| Cursor | Verified Cursor archive; register the official marketplace if its Agent CLI is available | Local CLI update or the original marketplace channel |
| WorkBuddy | Verified complete marketplace from the domestic source and native plugin install | For a known existing installation, prefer native update in its original scope |
| Claude Code | Register the official marketplace, then install its Claude Code entry | Update the same entry in its original scope |
| Codex | Register the official marketplace, then add its Codex entry | Refresh that source and verify the installed plugin through the current client's supported update flow |

### Cursor installation

For a first installation, use the official stable Cursor archive. With an available
Cursor Agent CLI (`agent` or `cursor-agent`), first register the official source
unless that same source is already registered:

```sh
agent plugin marketplace add https://github.com/Ontos-AI/hipohipo-plugins
```

This is registration only; it does not install or enable the plugin.
If the CLI is absent or registration fails, retain the diagnostic and continue with the archive.
Do not install or upgrade a host CLI solely for marketplace registration.

Download `hipohipo-cursor-<version>.tar.gz` or `.zip` and `SHA256SUMS-<version>.txt`
from that official release. Verify the archive's exact filename and checksum.
Require all entries to stay inside `hipohipo/`; reject absolute paths, traversal,
symbolic links and hard links. Extract into a new staging directory. Before
execution, match `release.json` version to the target and its `sourceCommit` to
the public release's `Source` record; no access to the source repository is needed.
Then run the packaged `hipohipo install` (`hipohipo.cmd install` on Windows).
This installer is Cursor-specific. Use the returned installation directory for
subsequent CLI calls.

Only if the user explicitly chooses marketplace installation, the user may
manually install Hipohipo from the registered official marketplace. Cursor-managed
automatic updates depend on Cursor's settings and prerequisites; installation alone does not confirm
that automatic updates are enabled. This replaces the archive route; do not run
both. Explain the required user action without operating the interface.

### Cursor updates

Keep an existing marketplace installation on the same marketplace and use
Cursor's marketplace updater. If that action has no supported CLI/API, explain
the required user action; do not replace it with an archive. Marketplace
registration or source refresh alone does not prove that the installed plugin
and responding MCP have updated. Marketplace setup and troubleshooting are in
[Cursor's update guidance](https://cursor.com/docs/plugins#keep-plugins-up-to-date).

To update an existing local installation now, run the installed CLI from its
installation directory, or use its full path. Windows uses `hipohipo.cmd`:

```sh
./hipohipo update --host cursor
```

Use the command as shown, from the existing installation's entry point; do not
append sign-in or configuration options.

If the command is unavailable or does not support this installation, upgrade
with the verified archive using the installation steps above. Then inspect the
result and update settings:

```sh
./hipohipo update status --host cursor
```

New Local installations check automatically by default for complete plugin updates on
MCP/session startup, at most once per day. Older Local installations need one
upgrade with the latest archive to receive automatic updates. Preserve existing
update preferences and use the status result to confirm the current setting.
A failed update preserves the working package and authorization.
For update preferences or rollback, consult the packaged `SUPPORT.md` when needed.
Continue with sign-in and actual MCP verification after updating.

### WorkBuddy

For first setup, use the complete marketplace from **WorkBuddy domestic source**
below, register it as needed and install `HipoHipo@hipohipo-plugins`. A Skill
upload is not full plugin installation. For a known existing installation,
prefer native update in the original scope; do not substitute a new installation
in another scope.

For an existing Git marketplace, native update synchronizes the remote source;
do not replace it with an OSS directory. Future updates follow the host's update
settings. For an OSS archive registered as a local directory, first refresh that
registered directory as described below, then use native update. The host does
not fetch newer OSS archives for a local-directory source.

Use an available native plugin-management API, or resolve WorkBuddy's bundled
plugin-management CLI (`codebuddy`) and runtime from its installation metadata
and package `bin` entry. This is the WorkBuddy entry, not standalone CodeBuddy.

For the bundled CLI, remove `SERVER__PORT` and `SERVER__HOST` from every child
invocation, including `--help`, marketplace, install and update. On POSIX, prefix
the supported arguments with `env -u SERVER__PORT -u SERVER__HOST "$workbuddyCli"`,
where `$workbuddyCli` is the verified host entry. Use equivalent child-only
handling in other shells. Preserve the parent environment, proxy, working
directory, runtime and bundle-selection arguments, and active profile.

### Claude Code

For first setup, register the official marketplace if needed, then install the
Claude Code entry. The example uses user scope; use the requested scope instead
when different:

```sh
claude plugin marketplace add https://github.com/Ontos-AI/hipohipo-plugins
claude plugin install hipohipo@hipohipo-plugins --scope user
```

For an existing installation, update the same entry with its verified original
scope. In this example, `$scope` is that scope, not an instruction to change it:

```sh
claude plugin update hipohipo@hipohipo-plugins --scope "$scope"
```

For a marketplace added through this guide's GitHub route, automatic updates are
off by default. Check actual settings rather than assuming the default still applies;
marketplaces added through claude.ai have a different default. Keep the user's
preference. The command above updates now; optional automatic-update configuration
is described in [Claude Code's update guidance](https://code.claude.com/docs/en/discover-plugins#keep-plugins-updated).
If configuration requires a UI action, explain it to the user.

Read the actual update result and installed version. Apply the current client's
supported loading flow in step 3; an installation result alone does not prove
that the current MCP has loaded the update.

### Codex

Use a Codex client with native plugin support. For first setup, register the
official marketplace if needed, then add the Codex entry:

```sh
codex plugin marketplace add https://github.com/Ontos-AI/hipohipo-plugins
codex plugin add hipohipo@hipohipo-plugins
```

For an existing installation, refresh only its configured official source:

```sh
codex plugin marketplace upgrade hipohipo-plugins
```

Then check the actual installed plugin version. A successful source refresh alone
does not confirm the installed plugin was updated. If the installed copy remains old, use the current
client's documented plugin update action for that same entry, source and profile.
Use this client's help for available operations; do not assume another client's
update command exists. If a required action is available only to the user,
explain it and leave the update unconfirmed. Continue with the actual MCP check
in step 3, including for desktop clients whose existing conversation has not
loaded the new version.

Future updates are managed by Codex and its current settings. Hipohipo does not add a separate updater
or promise a fixed update interval. Preserve the user's settings; use the refresh
and verification flow above when an update is requested.

### Check the installation result

Verify the installed package version against the target, along with its source,
scope and enabled state, using native results or available package metadata.
No particular inventory query is mandatory. Continue with sign-in and MCP
verification as soon as installation succeeds.

Consult CLI help or the verified package's `SUPPORT.md` when an actual error or
missing required information blocks the next step. If supported recovery is
unavailable, report the blocker without editing private host state.

## 2. Reuse authorization or sign in

Use an available status result to reuse valid authorization, including read-only grants.
`auth.login` being unavailable does not tell you whether MCP is loaded or you are signed in.
When sign-in is needed, use the selected installation's exposed `auth.login` tool.
If that login tool is not exposed, even when other MCP tools are available, use
that installation's CLI with the same client and effective configuration.
Refusal, cancellation or a permission restriction is not a missing tool;
do not switch to CLI to bypass it. From the installation directory, for example:

```sh
./hipohipo auth-status --host "$targetHost"
```

Only when sign-in is needed:

```sh
./hipohipo login --host "$targetHost"
```

`$targetHost` is the verified client: `cursor`, `workbuddy`, `codex` or `claude-code`.
Use the installed `.cmd` entry on Windows. Preserve configuration and overrides;
quote paths and pass separate arguments. For missing arguments, consult
`./hipohipo --help`. For additional diagnostics when needed, use
`./hipohipo status --host "$targetHost"` with the same client and profile.

Preserve existing authorization and history. Do not reset them to resolve an
installation or loading issue. Never inspect credentials.

Tell the user before consent and show returned browser/device links and public
user codes immediately. Wait for the current login and follow its `nextAction`;
continue the same pending flow after approval. Do not start parallel logins or
retry automatically after refusal, cancellation or terminal failure. Recovery
and timeout details are in `SUPPORT.md`.

## 3. Load and verify

After sign-in or authorization reuse, call the current session's exposed Hipohipo
MCP `auth.status` tool, using its actual name in that client. Compare the responding
`serverVersion` with the target version chosen in step 1 and confirm authorization.
An existing newer version may remain in place. CLI status, installed metadata
or an enabled setting alone cannot prove that this MCP has loaded the target.

If tools are missing or outdated, briefly retry tool discovery/status a few times
while the host finishes loading. Continue any pending setup action; retries alone
do not prove loading. If still unavailable or outdated, use the client flow below.

- Cursor: tell the user to quit and reopen the app normally if the new version is not loaded; do not operate the interface yourself.
- WorkBuddy: once the host reports MCP ready, verify in a new conversation first.
  If MCP cannot start or the new conversation still has no tools or an old version,
  quit and reopen the app normally.
- Claude Code: use the installed version's documented reload action when supported;
  otherwise continue in a fresh Claude Code session. Verify the resulting MCP connection.
- Codex: use the current client's supported plugin loading flow. If the existing
  conversation retains the old connection, continue in a fresh chat/session and
  verify the actual MCP response.

Enable MCP only if it is actually disabled. Preserve completed sign-in; do not
reinstall or log in again solely for loading. Reuse one sufficient status result.
Use only necessary status responses for verification; do not call business tools
or upload user content. Keep loading unconfirmed until verified.

Give a friendly final reply in the conversation's language, usually 1–3 sentences.
Once the connection is verified, confirm readiness and briefly describe finding documents and
recalling memories within the current grant, without example questions.
For a new conversation or normal app restart, state what is complete and that
loading remains unconfirmed. Give only the required loading action; do not
promise readiness after restarting, and do not ask the user to paste prompts, verify or report back.
For actual failures, explain the issue and next step without claiming readiness.
Keep technical details (versions, paths, checksums and diagnostic IDs)
in existing tool output unless requested or needed for support.

## WorkBuddy domestic source

Use this route for first setup or an existing OSS local-directory source.
Keep existing Git marketplaces on the Git update route above.

Read `https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/releases/latest.json`.
Require `schemaVersion: 1`, a valid stable version, a complete `sourceCommit`, and
package URLs on the same OSS host under `hipohipo/releases/<version>/`.
Use this version as the target. Download `marketplace.url` and verify its byte
size and SHA256; stop on mismatch. Before extraction, require all entries to stay
inside `hipohipo-plugin-marketplace/`, without absolute paths, `..`, symbolic
links or hard links. Match `release.json` version and source commit to the index;
require `.codebuddy-plugin/marketplace.json` and `plugins/hipohipo-workbuddy/`.
Use available tools; do not require users to install Go, Node.js or Python.
This route needs no GitHub version or guide lookup.

Keep the complete marketplace in a persistent user-writable location, separate
from the host-managed plugin cache. For first setup, use a new location under
the active configuration root; leave another profile's sources unchanged.

For an existing local-directory source, stage and verify the new complete marketplace,
then update the original registered source directory. First verify that it is the
official source for this profile and a user-managed directory, not a Git checkout
or host cache. Keep a backup of the old source until the native update succeeds.
A download in a different staging directory alone will not update the installed plugin.
Do not change the registered source path, credentials or history. If source replacement
fails, restore its backup before retrying; inspect native state if a host command fails.

Then refresh the marketplace and update the plugin in its original `$scope`.
The following arguments use the WorkBuddy CLI handling above:

```sh
plugin marketplace update hipohipo-plugins
plugin update HipoHipo@hipohipo-plugins --scope "$scope"
```

The host does not download future OSS archives for this source; run this guide again
to fetch, verify and apply a later version. Do not describe local-source installation
as automatic updating.

For first setup, register the marketplace as needed with
`plugin marketplace add <complete-marketplace-directory>`, then use
`plugin install HipoHipo@hipohipo-plugins --scope user` (or the requested scope).
Do not delete locks, edit private registries, silently remove marketplaces, enable
duplicate plugins, disable safety protections or bypass host protection. After an
error, check actual installed state before repeating installation; see `SUPPORT.md`.
