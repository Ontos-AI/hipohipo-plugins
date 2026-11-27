#!/bin/sh
TASK_PLUGIN_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$TASK_PLUGIN_ROOT/scripts/run.cmd" logout --host cursor
