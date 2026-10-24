# Hipohipo for WorkBuddy

This package uses the shared native Hipohipo runtime with an explicit WorkBuddy
identity. WorkBuddy supplies `CODEBUDDY_PLUGIN_ROOT`, `CODEBUDDY_PLUGIN_DATA`,
and its effective configuration directory. New persistent state belongs to Hipo-managed application data; the native
plugin data directory only helps discover existing instances in place. The versioned installation directory never identifies
the user's configuration or selects the destination Hipo Project.

Follow the [unified installation guide](https://raw.githubusercontent.com/Ontos-AI/hipohipo-plugins/main/install/README.md).
It defines installation, updates, loading, sign-in and completion. Its WorkBuddy
section covers bundled-CLI discovery, child environment handling and native
installation in the active profile. Child-process examples are in SUPPORT.md.

For mainland China, use the [Chinese installation guide](https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/install/README.zh-CN.md).
It downloads a verified local marketplace from OSS and uses WorkBuddy's native
installer. First-run runtime preparation prefers OSS, then falls back to Blob
on network failure with the same pinned checksums and shared deadline.

Sign-in can finish through this installed package's CLI when the current
conversation has no MCP tools. Use the same host/profile/data binding. Confirm
`authorized`, then report host MCP availability separately. Capture complete
JSON and the real exit code. Pending calls continue the same attempt; terminal
failures require the action named in `nextAction`, never manual downloads or
lock cleanup. Explicitly rejected old credentials recover into one new consent
flow for this instance; denial or cancellation of that flow requires a new request.

The runtime accepts `WORKBUDDY_CONFIG_DIR`, with `CODEBUDDY_CONFIG_DIR` as its
alias. When both exist, they must resolve to the same directory. Missing or
conflicting metadata is diagnosed instead of selecting another profile.

Hooks persist session notifications and reuse the existing bounded worker and
conversation outbox. Authored text comes from the offered session transcript;
Hook prompt and assistant fields do not independently create conversation
turns. `StopFailure` and `SessionEnd` support is implemented from the contract,
but native delivery of those events remains unverified.

The document-capture Skill uses `source.create_background` for proactive saves,
with the same connection permission as Cursor, Claude Code and Codex. The choice
is made during authorization, not through per-document chat offers. If the tool
is unavailable or denied, the Agent continues without saving; explicit requests
use `source.create`. Local rules and memories use the shared one-time import
task, with the same Project concurrency and recovery rules. No historical
conversation directory is imported.

Opening the desktop alone does not establish plugin availability. If an import
needs this device, resume a WorkBuddy task with Hipohipo enabled. Uploaded work
continues on Hipo after the local MCP process exits.
