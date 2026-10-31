#!/bin/sh
# A prepared native runtime avoids inheriting Git Bash's emulated PowerShell
# architecture. The native launcher still owns leases, identity and authorization.
tryPreparedWindowsHook() {
  TASK_READY_SCRIPT_DIRECTORY=$1
  shift
  case "${1:-}" in hook|host-hook|document-permission|runtime-status) ;; *) return 1 ;; esac
  for TASK_READY_ARGUMENT in "$@"; do
    case "$TASK_READY_ARGUMENT" in --help|-h|-help) return 1 ;; esac
  done
  command -v cygpath >/dev/null 2>&1 || return 1
  command -v reg.exe >/dev/null 2>&1 || return 1
  command -v sha256sum >/dev/null 2>&1 || return 1

  TASK_READY_MANIFEST=$(cygpath -u "${HIPO_RUNTIME_MANIFEST:-$TASK_READY_SCRIPT_DIRECTORY/../runtime-manifest.json}" 2>/dev/null) || return 1
  case "$TASK_READY_MANIFEST" in /*.json) ;; *) return 1 ;; esac
  TASK_READY_PINS=${TASK_READY_MANIFEST%.json}.sh
  [ -f "$TASK_READY_MANIFEST" ] && [ ! -L "$TASK_READY_MANIFEST" ] || return 1
  [ -f "$TASK_READY_PINS" ] && [ ! -L "$TASK_READY_PINS" ] || return 1
  sh -n "$TASK_READY_PINS" >/dev/null 2>&1 || return 1
  # These shell pins are generated with the package, never from Hook input.
  . "$TASK_READY_PINS"
  case "${manifestSize:-}" in ''|*[!0-9]*) return 1 ;; esac
  case "${manifestDigest:-}" in ''|*[!a-f0-9]*) return 1 ;; esac
  [ "${#manifestDigest}" -eq 64 ] && [ "$manifestSize" -le 65536 ] || return 1
  [ "$(wc -c < "$TASK_READY_MANIFEST")" -eq "$manifestSize" ] || return 1
  TASK_READY_DIGEST=$(sha256sum < "$TASK_READY_MANIFEST" 2>/dev/null) || return 1
  [ "${TASK_READY_DIGEST%% *}" = "$manifestDigest" ] || return 1
  case "${runtimeVersion:-}" in ''|*[!A-Za-z0-9._-]*) return 1 ;; esac

  TASK_READY_ARCHITECTURE=$(MSYS2_ARG_CONV_EXCL='*' reg.exe QUERY 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' /v PROCESSOR_ARCHITECTURE 2>/dev/null) || return 1
  case "$TASK_READY_ARCHITECTURE" in
    *REG_SZ*ARM64*|*REG_SZ*Arm64*) TASK_READY_PLATFORM=windows-arm64 ;;
    *REG_SZ*AMD64*|*REG_SZ*X64*) TASK_READY_PLATFORM=windows-amd64 ;;
    *) return 1 ;;
  esac
  executableDigest=''
  compressedDigest=''
  executableSize=''
  selectArtifact "$TASK_READY_PLATFORM"
  case "$executableDigest:$compressedDigest" in *[!a-f0-9:]*|:*|*:) return 1 ;; esac
  [ "${#executableDigest}" -eq 64 ] && [ "${#compressedDigest}" -eq 64 ] || return 1
  case "$executableSize" in ''|*[!0-9]*) return 1 ;; esac
  [ "$executableSize" -gt 0 ] && [ "$executableSize" -le 134217728 ] || return 1

  TASK_READY_CACHE=${HIPO_RUNTIME_CACHE_DIR:-${LOCALAPPDATA:-}/Hipohipo/runtimes}
  TASK_READY_CONFIGURATION=${HIPO_RUNTIME_CONFIG_DIR:-${APPDATA:-}/Hipohipo/runtime-launcher}
  [ -n "${HIPO_RUNTIME_CACHE_DIR:-}${LOCALAPPDATA:-}" ] || return 1
  [ -n "${HIPO_RUNTIME_CONFIG_DIR:-}${APPDATA:-}" ] || return 1
  TASK_READY_CACHE=$(cygpath -u "$TASK_READY_CACHE" 2>/dev/null) || return 1
  TASK_READY_CONFIGURATION=$(cygpath -u "$TASK_READY_CONFIGURATION" 2>/dev/null) || return 1
  case "$TASK_READY_CACHE:$TASK_READY_CONFIGURATION" in /*:/*) ;; *) return 1 ;; esac
  TASK_READY_PREFIX=$(printf '%.16s' "$compressedDigest")
  TASK_READY_RUNTIME="$TASK_READY_CACHE/versions/$runtimeVersion/$TASK_READY_PLATFORM/$TASK_READY_PREFIX/hipohipo.exe"
  [ -f "$TASK_READY_RUNTIME" ] && [ ! -L "$TASK_READY_RUNTIME" ] || return 1
  [ "$(wc -c < "$TASK_READY_RUNTIME")" -eq "$executableSize" ] || return 1
  TASK_READY_DIGEST=$(sha256sum < "$TASK_READY_RUNTIME" 2>/dev/null) || return 1
  [ "${TASK_READY_DIGEST%% *}" = "$executableDigest" ] || return 1

  HIPO_RUNTIME_MANIFEST=$(cygpath -w "$TASK_READY_MANIFEST" 2>/dev/null) || return 1
  HIPO_RUNTIME_CACHE_DIR=$(cygpath -w "$TASK_READY_CACHE" 2>/dev/null) || return 1
  HIPO_RUNTIME_CONFIG_DIR=$(cygpath -w "$TASK_READY_CONFIGURATION" 2>/dev/null) || return 1
  export HIPO_RUNTIME_MANIFEST HIPO_RUNTIME_CACHE_DIR HIPO_RUNTIME_CONFIG_DIR
  exec "$TASK_READY_RUNTIME" __runtime-run "$@"
}
