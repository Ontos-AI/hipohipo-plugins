# Hipohipo for WorkBuddy

Search Hipohipo memory and documents, capture supported local conversations,
and save selected documents under the connection's authorization.

## Install and update

Follow the [installation and update guide](https://hipohipo.ai/install/README.md)
or its [Chinese version](https://hipohipo.ai/install/README.zh-CN.md).
Use the WorkBuddy route to install the complete plugin, not just a Skill.
The guide covers the verified domestic source, first installation, updates in
the original scope, sign-in and actual MCP verification.

Keep the active client configuration, installation source, authorization and
history. For an existing installation, update the same entry. Git marketplaces
sync through native update; an OSS local-directory source needs the guide's
source refresh before native update and does not fetch future archives automatically.
Follow Support before changing a custom data location.

## Connect

Reuse valid authorization. When sign-in is needed, use the exposed `auth.login`
tool, or the installed CLI with `--host workbuddy` and the same client configuration.
Show the returned consent link or device code and continue the same pending flow.
Do not retry after refusal or cancellation without a new request.

Use `auth.status` to inspect authorization and the responding MCP version.
Successful CLI sign-in alone does not prove that WorkBuddy has loaded MCP.
Follow the guide's loading steps if the connection is unavailable or outdated.
Uploads require write access; keep an existing read-only grant when appropriate.

## Capture and documents

Conversation capture collects locally when WorkBuddy delivers the plugin's Hooks,
including before login. Upload requires valid authorization. It does not scan
unopened historical conversations. Coverage depends on the active client session;
memory extraction is asynchronous and may produce no reusable memory.

The document-capture Skill saves eligible supplied documents and completed
file deliverables when the connection permits background saving. Drafts and
engineering files are excluded unless explicitly requested. If the tool is
unavailable or denied, the Agent continues without saving. Explicit save requests
use the exposed save tool. Local reading can proceed independently of saving.

For rules and memories import, choose the WorkBuddy connection in the Project's
connection manager. Review the source selection and permission before import.
Keep a task with Hipohipo enabled available while local collection is needed;
opening the desktop alone does not establish plugin availability.

## Retained data and removal

Keep one active Hipohipo entry in WorkBuddy. Do not clear credentials or delete
history to install an update. Authorization may be shared with other Hipohipo
plugin clients on the same OS profile; reconnecting or logging out can affect them.

Disable Hooks to stop local collection. Logout stops authorized uploads while
local collection continues if Hooks remain enabled. Uninstalling does not delete
data already uploaded to Hipohipo. Preserve existing local data when using the
client's plugin manager; see Privacy before removing it.

[Support](SUPPORT.md) · [Privacy](PRIVACY.md)
