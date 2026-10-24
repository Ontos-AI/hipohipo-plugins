#!/bin/sh
set -eu

# HIPO_CLAUDE_RUNNER may point at a packaged native Hipo executable. The
# default is the executable bundled by the Claude plugin package.
TASK_RUNNER=${HIPO_CLAUDE_RUNNER:-"${CLAUDE_PLUGIN_ROOT}/scripts/run.cmd"}
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
  printf '%s\n' "Hipohipo Claude runner is not installed. Set HIPO_CLAUDE_RUNNER to its native executable." >&2
  exit 1
fi

set -- "$TASK_RUNNER" login --host claude-code
if [ -n "${HIPO_CLAUDE_STATE_DIR:-}" ]; then
  set -- "$@" --state-dir "$HIPO_CLAUDE_STATE_DIR"
fi
case "$TASK_RUNNER" in
  *.cmd) exec sh "$@" ;;
  *) exec "$@" ;;
esac
