: << 'HIPO_WINDOWS_COMMAND'
@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0launch.ps1" %*
exit /b %errorlevel%
HIPO_WINDOWS_COMMAND
TASK_SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if [ -f "$TASK_SCRIPT_DIRECTORY/windows-ready-hook.sh" ]; then
      . "$TASK_SCRIPT_DIRECTORY/windows-ready-hook.sh"
      tryPreparedWindowsHook "$TASK_SCRIPT_DIRECTORY" "$@" || :
    fi
    TASK_WINDOWS_SCRIPT=$(cygpath -w "$TASK_SCRIPT_DIRECTORY/launch.ps1")
    exec powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$TASK_WINDOWS_SCRIPT" "$@" ;;
  *) exec sh "$TASK_SCRIPT_DIRECTORY/launch.sh" "$@" ;;
esac
