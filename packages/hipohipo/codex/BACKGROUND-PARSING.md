# Background document parsing permission

This candidate lets Codex apply an explicit, user-trusted Hipohipo permission
rule. It does not change the global reviewer or install shell allow rules.

After installing the candidate, open Codex on the same machine and profile,
run `/hooks`, and review the Hipohipo `PermissionRequest` entry. Trust it only
if you authorize this behavior: approve background parsing requests and the
plugin's original-document transfers to the Project selected in your existing
Hipohipo authorization. These actions send file metadata or original contents
to Hipohipo for remote parsing and storage.

Codex saves trust for the exact installed Hook and plugin contents. Changed
contents may require review again. Installing the plugin does not grant trust.
Disable the entry in `/hooks` to return these actions to ordinary host review;
revoke or disable background access on Hipohipo to stop this permission rule.

The handler checks the current write and background permission with the server,
verifies the authorized account, Project and connection, and binds admission to
the immutable request. It does not start login or refresh expired credentials.
The existing Skill selects supplied documents and completed deliverables and
honors explicit opt-outs; this Hook does not expand document discovery.

For local-file permits, pass the absolute original `localFilePath`. The plugin
validates it before admission, strips it from remote dispatch and returns a
complete dedicated transfer command including `--file`; run it unchanged. Its
result specifies the normal per-command approval mode, so Codex requests review
before executing it rather than failing on sandbox-protected runtime state.
This mode applies only to that command and does not change the global policy. Its
private operation ticket contains the exact authenticated server-issued URL,
original local path, document size and SHA-256, Source, upload and authorization
identities. Earlier tickets without a stored local path retain their original
size and SHA-256 checks. Before
transfer, the command checks permission again and freezes and verifies the
original bytes. Storage receives document bytes, not the MCP access token.
Redirects and changed grants, Projects or documents stop the transfer.

The Bash matcher observes approval requests, but the handler only decides the
plugin's exact ticket-bound transfer command. Other shell commands and external
URL parsing requests retain ordinary review. A completed transfer is not a
completed parse: check the same Source with `isBackground: true` until its actual
outcome is known. Do not create a replacement Source after an uncertain result.
