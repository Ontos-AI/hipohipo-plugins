#!/bin/sh
set -eu

if [ "$#" -ne 2 ] || [ "$1" != "--event" ]; then
  printf '%s\n' "usage: hook.sh --event EVENT" >&2
  exit 2
fi

# The shared native executable owns parsing, SQLite persistence and worker
# handoff. The host flag selects Claude's envelope and state namespace.
TASK_RUNNER=${HIPO_CLAUDE_HOOK_RUNNER:-"${CLAUDE_PLUGIN_ROOT}/scripts/run.cmd"}
if [ ! -f "$TASK_RUNNER" ] && [ -x "${TASK_RUNNER}.exe" ]; then
  TASK_RUNNER="${TASK_RUNNER}.exe"
fi
# Git Bash reports .cmd files as non-executable even though they are valid
# shell dispatchers. Run the polyglot's POSIX branch explicitly; native runner
# overrides retain normal executable permission checks.
canRunClaudeRunner() {
  case "$TASK_RUNNER" in
    *.cmd) [ -f "$TASK_RUNNER" ] && [ -r "$TASK_RUNNER" ] ;;
    *) [ -x "$TASK_RUNNER" ] ;;
  esac
}
if ! canRunClaudeRunner; then
  # An incomplete package must not block the conversation, while diagnostics
  # still make the missing capture component visible.
  printf '%s\n' "Hipohipo Claude runner is missing or unreadable." >&2
  printf '%s\n' '{}'
  exit 0
fi
set -- "$TASK_RUNNER" host-hook --host claude-code --event "$2"
if [ -n "${HIPO_CLAUDE_STATE_DIR:-}" ]; then
  set -- "$@" --state-dir "$HIPO_CLAUDE_STATE_DIR"
fi
case "$TASK_RUNNER" in
  *.cmd) exec sh "$@" ;;
  *) exec "$@" ;;
esac
