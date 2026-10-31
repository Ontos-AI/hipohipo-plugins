#!/bin/sh
set -eu
TASK_PLUGIN_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$TASK_PLUGIN_ROOT/hipohipo" "$@"
