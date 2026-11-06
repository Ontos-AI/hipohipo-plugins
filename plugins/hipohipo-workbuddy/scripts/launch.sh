#!/bin/sh
# Bootstrap using only the POSIX shell and standard system download tools.
set -eu
if [ "${1:-}" = __hook-noop ]; then printf '{}\n'; exit 0; fi
case "${1:-}" in
  setup|install|update) printf '%s\n' 'Hipohipo plugin: use the independent installer for installation, updates, and repair.' >&2; exit 1 ;;
esac
umask 077
invocationStarted=$(date +%s)

scriptDirectory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
pluginRoot=$(CDPATH= cd -- "$scriptDirectory/.." && pwd)
# The active manifest switches every component at once. Keep this root bridge
# stable so CLI invocations also follow the selected complete package.
if [ "${1:-}" != install ] && [ -d "$pluginRoot/.hipohipo-releases" ] && [ ! -L "$pluginRoot/.hipohipo-releases" ]; then
  activeVersion=$(tr -d '\r\n' < "$pluginRoot/.cursor-plugin/plugin.json" | LC_ALL=C HIPO_BOOTSTRAP_JSON_MODE=version awk -f "$scriptDirectory/mcp-json.awk")
  case "$activeVersion" in ''|invalid-*) exit 1 ;; esac
  activeRoot="$pluginRoot/.hipohipo-releases/$activeVersion"
  if [ -d "$activeRoot" ] && [ ! -L "$activeRoot" ]; then
    unset HIPO_RUNTIME_MANIFEST HIPO_PLUGIN_INSTALLATION_ROOT
    exec "$activeRoot/hipohipo" "$@"
  fi
fi
manifestPath=${HIPO_RUNTIME_MANIFEST:-$pluginRoot/runtime-manifest.json}
pinsPath=${manifestPath%.json}.sh
commandName=${1:-runtime-status}
printUsage() { cat "$scriptDirectory/cli-help.txt"; }
case "$commandName" in --help|-h|-help) printUsage; exit 0 ;; esac
host=${HIPO_CAPTURE_HOST:-}
event=''
previousArgument=''
for argument in "$@"; do
  [ "$previousArgument" != --host ] || host=$argument
  [ "$previousArgument" != --event ] || event=$argument
  case "$argument" in
    --host=*) host=${argument#--host=} ;;
  esac
  previousArgument=$argument
done
case "$host" in cursor|cursor-plugin|claude-code|codex|workbuddy) ;; *) host='' ;; esac
case "$event" in sessionStart|beforeSubmitPrompt|afterAgentResponse|stop|sessionEnd|SessionStart|UserPromptSubmit|Stop|PreCompact|SessionEnd|Interrupt|StopFailure) ;; *) event='' ;; esac
isHook=false
case "$commandName" in hook|host-hook) isHook=true ;; esac

printHookResponse() {
  if [ -n "${1:-}" ]; then
    case "$commandName:$host:$event" in
      hook:cursor:beforeSubmitPrompt|hook:cursor-plugin:beforeSubmitPrompt|host-hook:codex:UserPromptSubmit|host-hook:claude-code:UserPromptSubmit|host-hook:workbuddy:UserPromptSubmit)
        if [ "$({ head -c 32000001; printf '\036end-share-hook'; } | LC_ALL=C HIPO_BOOTSTRAP_JSON_MODE=share-hook HIPO_BOOTSTRAP_HOOK_HOST="$host" HIPO_BOOTSTRAP_PLUGIN_ROOT="$pluginRoot" HIPO_BOOTSTRAP_HOOK_EVENT="$event" awk -f "$scriptDirectory/mcp-json.awk")" = share ]; then
          if [ "$commandName" = hook ]; then
            printf '{"continue":false,"user_message":"%s"}\n' "$1"
          else
            printf '{"decision":"block","reason":"%s"}\n' "$1"
          fi
          return
        fi ;;
    esac
  fi
  if [ "$commandName" = hook ] && [ "$event" = beforeSubmitPrompt ]; then
    printf '{"continue":true}\n'
  else
    printf '{}\n'
  fi
}

escapeJson() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n\r\t' '   '; }

hasRemainingLoginTime() {
  case "$commandName" in
    login|login-device) [ "$(date +%s)" -lt "$((HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS / 1000))" ] ;;
    *) return 0 ;;
  esac
}

finishExpiredLogin() {
  if ! hasRemainingLoginTime; then
    printf '{"status":"setup_pending","state":"preparing","nextAction":"continue_setup","lastErrorCode":"login_timeout","operationExecuted":false,"message":"The total login deadline elapsed before authorization could execute. Continue the same login command."}\n'
    exit 0
  fi
}

calculateDigest() (
  case "$commandName" in
    login|login-device) ;;
    *) if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | cut -d ' ' -f 1
       else shasum -a 256 < "$1" | cut -d ' ' -f 1; fi; exit $? ;;
  esac
  hasRemainingLoginTime || exit 75
  digestOutput=$(mktemp "${TMPDIR:-/tmp}/hipohipo-digest.XXXXXX") || exit 1
  trap 'rm -f "$digestOutput"' 0
  if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" > "$digestOutput" 2>/dev/null &
  else shasum -a 256 < "$1" > "$digestOutput" 2>/dev/null & fi
  digestProcess=$!
  while kill -0 "$digestProcess" 2>/dev/null; do
    if ! hasRemainingLoginTime; then
      kill -TERM "$digestProcess" 2>/dev/null || :
      wait "$digestProcess" 2>/dev/null || :
      exit 75
    fi
    sleep 0.02
  done
  wait "$digestProcess" || exit $?
  hasRemainingLoginTime || exit 75
  cut -d ' ' -f 1 "$digestOutput"
)

verifyFile() {
  [ -f "$1" ] && [ ! -L "$1" ] && [ "$(wc -c < "$1")" -eq "$2" ] && [ "$(calculateDigest "$1")" = "$3" ]
}

isReady() { [ -x "$runtimePath" ] && verifyFile "$runtimePath" "$executableSize" "$executableDigest"; }

writeDiagnostic() (
  # Logging is best effort and cannot prevent ordinary host conversations.
  mkdir -p "$configDirectory/logs" || exit 0
  diagnosticLock="$configDirectory/logs/bootstrap-write.lock"
  exec 8>>"$diagnosticLock"
  acquireFileLock 8 || exit 0
  if [ -f "$logPath" ] && [ "$(wc -c < "$logPath")" -ge 1048576 ]; then
    rm -f "$logPath.3"
    [ ! -f "$logPath.2" ] || mv -f "$logPath.2" "$logPath.3"
    [ ! -f "$logPath.1" ] || mv -f "$logPath.1" "$logPath.2"
    mv -f "$logPath" "$logPath.1"
  fi
  find "$configDirectory/logs" -name 'bootstrap.jsonl.[123]' -type f -mtime +14 -exec rm -f {} \;
  printf '{"timestamp":"%s","component":"bootstrap","event":"%s","outcome":"%s","errorCode":"%s","runtimeVersion":"%s","launcherVersion":"%s","platform":"%s","host":"%s","hook":"%s","correlationId":"%s","elapsedMilliseconds":%s,"byteCount":%s}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "${3:-}" "$runtimeVersion" "$runtimeVersion" "$platform" "$host" "$event" "$$" "$(( ($(date +%s) - invocationStarted) * 1000 ))" "${4:-0}" >> "$logPath"
) || :

reportFailure() {
  if [ "$1" = invalid_arguments ]; then
    set -- "$1" "$2. Run hipohipo --help for usage and status/login examples."
  fi
  case "$1" in invalid_arguments|configuration_invalid) ;; *) finishExpiredLogin ;; esac
  case "$commandName" in
    runtime-status) ;;
    *) [ -z "${logPath:-}" ] || writeDiagnostic command_failed failed "$1" ;;
  esac
  printf 'Hipohipo bootstrap [%s]: %s. Inspect this error before retrying; use runtime-retry only for an explicit preparation retry. Local log: %s\n' "$1" "$2" "${logPath:-unavailable}" >&2
  if [ "$isHook" = true ]; then printHookResponse 'Hipohipo could not prepare its runtime. Check Hipohipo status before sharing again.'; exit 0; fi
  case "$commandName:$1" in
    *:invalid_arguments|runtime-prepare:*|runtime-retry:*|runtime-status:*|auth-status:*|login:*|login-device:*)
      printf '{"state":"failed","nextAction":"inspect_error","lastErrorCode":"%s","logPath":"%s","operationExecuted":false,"message":"%s"}\n' "$1" "$(escapeJson "${logPath:-}")" "$(escapeJson "$2")" ;;
  esac
  exit 1
}

# Validate before reading pins, hashing files or contacting a download service.
initializeLoginDeadline() {
  loginTimeoutSeconds=600
  loginCommand=$1
  shift
  while [ "$#" -gt 0 ]; do
    loginArgument=$1
    shift
    case "$loginArgument" in
      --help|-h|-help)
        printUsage; exit 0 ;;
      --timeout-seconds|--timeout-seconds=*)
        case "$loginCommand" in login|login-device) ;; *) reportFailure invalid_arguments '--timeout-seconds applies to login only' ;; esac
        case "$loginArgument" in
          *=*) loginTimeoutSeconds=${loginArgument#*=} ;;
          *) [ "$#" -gt 0 ] || reportFailure invalid_arguments '--timeout-seconds requires a value'; loginTimeoutSeconds=$1; shift ;;
        esac
        case "$loginTimeoutSeconds" in ''|*[!0-9]*) reportFailure invalid_arguments '--timeout-seconds must be an integer from 1 to 600' ;; esac
        loginTimeoutSeconds=$(printf '%s' "$loginTimeoutSeconds" | sed 's/^0*//')
        [ -n "$loginTimeoutSeconds" ] && [ "${#loginTimeoutSeconds}" -le 3 ] && [ "$loginTimeoutSeconds" -le 600 ] || reportFailure invalid_arguments '--timeout-seconds must be an integer from 1 to 600' ;;
      --host|--state-dir|--configuration-root|--reuse-auth-from|--source-configuration-root)
        case "$loginCommand:$loginArgument" in login-device:--reuse-auth-from|login-device:--source-configuration-root) reportFailure invalid_arguments 'Authorization reuse applies to ordinary login only' ;; esac
        case "$loginCommand" in
          login|login-device) [ "$#" -gt 0 ] || reportFailure invalid_arguments "$loginArgument requires a value"; case "$1" in --*) reportFailure invalid_arguments "$loginArgument requires a value" ;; esac; shift ;;
        esac ;;
      --host=*|--state-dir=*|--configuration-root=*) ;;
      --reuse-auth-from=*|--source-configuration-root=*)
        case "$loginCommand" in login-device) reportFailure invalid_arguments 'Authorization reuse applies to ordinary login only' ;; esac ;;
      --reuse-only|--reuse-only=true|--reuse-only=false)
        case "$loginCommand" in login-device) reportFailure invalid_arguments 'Authorization reuse applies to ordinary login only' ;; esac ;;
      --device|--headless|--device=true|--device=false|--headless=true|--headless=false)
        case "$loginCommand" in login) ;; login-device) reportFailure invalid_arguments '--device and --headless apply to login only' ;; esac ;;
      *) case "$loginCommand" in login|login-device) reportFailure invalid_arguments 'Unsupported login argument' ;; esac ;;
    esac
  done
  case "$loginCommand" in login|login-device) ;; *) return ;; esac
  loginDeadline=$(( (invocationStarted + loginTimeoutSeconds) * 1000 ))
  if [ -n "${HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS:-}" ]; then
    case "$HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS" in *[!0-9]*) reportFailure configuration_invalid 'Invalid login deadline' ;; esac
    [ "${#HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS}" -le 16 ] && [ "$HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS" -gt 0 ] || reportFailure configuration_invalid 'Invalid login deadline'
    [ "$HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS" -ge "$loginDeadline" ] || loginDeadline=$HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS
  fi
  HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS=$loginDeadline
  export HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS
}
if [ "$#" -gt 0 ]; then initializeLoginDeadline "$@"; fi
finishExpiredLogin

readProxy() {
  proxyUrl=''
  if [ -f "$configDirectory/proxy-url" ]; then
    proxyUrl=$(cat "$configDirectory/proxy-url")
  elif [ -f "$configDirectory/proxy.json" ]; then
    # Legacy native launchers write this one-field JSON object. Escaped URLs
    # require resetting the proxy explicitly rather than guessing at decoding.
    proxyUrl=$(sed -n 's/^[[:space:]]*{[[:space:]]*"url"[[:space:]]*:[[:space:]]*"\([^"\\]*\)"[[:space:]]*}[[:space:]]*$/\1/p' "$configDirectory/proxy.json")
    [ -n "$proxyUrl" ] || return 1
  fi
  [ -z "$proxyUrl" ] || validateProxy "$proxyUrl"
}

validateProxy() {
  case "$1" in *[[:space:]\\\"\?\#]*|'') return 1 ;; esac
  case "$1" in http://?*|https://?*|socks5://?*|socks5h://?*) ;; *) return 1 ;; esac
  proxyAuthority=${1#*://}
  proxyAuthority=${proxyAuthority%/}
  case "$proxyAuthority" in */*|'') return 1 ;; esac
}

[ -f "$pinsPath" ] || reportFailure manifest_missing 'Reinstall the plugin to restore its runtime pins'
# This is generated from the validated release manifest, never user input.
. "$pinsPath"
verifyFile "$manifestPath" "$manifestSize" "$manifestDigest" || reportFailure manifest_mismatch 'Runtime manifest and script pins differ'
case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) platform=darwin-arm64; artifactPlatform=macos-arm64 ;;
  Darwin/x86_64|Darwin/amd64) platform=darwin-amd64; artifactPlatform=macos-amd64 ;;
  Linux/x86_64|Linux/amd64) platform=linux-amd64; artifactPlatform=linux-amd64 ;;
  Linux/aarch64|Linux/arm64) platform=linux-arm64; artifactPlatform=linux-arm64 ;;
  *) reportFailure platform_unsupported "Hipohipo does not support $(uname -s)/$(uname -m)" ;;
esac
selectArtifact "$artifactPlatform"
artifactMirrorUrl=${artifactMirrorUrl:-}
case "$platform" in
  darwin-*) cacheDirectory=${HIPO_RUNTIME_CACHE_DIR:-$HOME/Library/Caches/Hipohipo/runtimes}; configDirectory=${HIPO_RUNTIME_CONFIG_DIR:-$HOME/Library/Application Support/Hipohipo/runtime-launcher} ;;
  *) cacheDirectory=${HIPO_RUNTIME_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/Hipohipo/runtimes}; configDirectory=${HIPO_RUNTIME_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/Hipohipo/runtime-launcher} ;;
esac
case "$cacheDirectory:$configDirectory:$manifestPath" in /*:/*:/*) ;; *) reportFailure configuration_invalid 'Runtime cache, configuration and manifest paths must be absolute' ;; esac
cacheKey="$runtimeVersion-$platform-$(printf '%.16s' "$compressedDigest")"
runtimeDirectory="$cacheDirectory/versions/$runtimeVersion/$platform/$(printf '%.16s' "$compressedDigest")"
runtimePath="$runtimeDirectory/hipohipo"
preparationLock="$cacheDirectory/locks/$cacheKey-preparation.lock"
preparationStatePath="$cacheDirectory/state/$cacheKey-preparation.json"
failurePath="$cacheDirectory/state/$cacheKey-script-failure"
logPath="$configDirectory/logs/bootstrap.jsonl"
publicationErrorPath="$configDirectory/logs/$cacheKey-publication.stderr"
downloadTimeoutSeconds=${HIPO_RUNTIME_DOWNLOAD_TIMEOUT_SECONDS:-600}
downloadMaximumAttempts=${HIPO_RUNTIME_DOWNLOAD_ATTEMPTS:-3}
case "$downloadTimeoutSeconds:$downloadMaximumAttempts" in *[!0-9:]*|:*|*:) reportFailure configuration_invalid 'Download limits must be integers' ;; esac
[ "$downloadTimeoutSeconds" -ge 1 ] && [ "$downloadTimeoutSeconds" -le 600 ] && [ "$downloadMaximumAttempts" -ge 1 ] && [ "$downloadMaximumAttempts" -le 3 ] || reportFailure configuration_invalid 'Download limits are out of range'
. "$scriptDirectory/runtime-preparation.sh"
export HIPO_RUNTIME_CACHE_DIR="$cacheDirectory" HIPO_RUNTIME_CONFIG_DIR="$configDirectory" HIPO_RUNTIME_MANIFEST="$manifestPath" HIPO_CAPTURE_HOST="$host"

case "$commandName" in
  runtime-status) printStatus; exit 0 ;;
  auth-status)
    if ! isReady; then
      printStatus >/dev/null
      observedAction=$nextAction
      observedStatus=$(printStatus)
      printf '{"status":"runtime_not_prepared","nextAction":"%s","operationExecuted":false,"message":"Runtime is not prepared; authorization was not checked.","runtime":%s}\n' "$observedAction" "$observedStatus"
      exit 0
    fi ;;
  runtime-prepare|runtime-retry|login|login-device)
    preparationMode=''
    [ "$commandName" != runtime-retry ] || preparationMode=explicit
    setupResult=0
    continueSetupPreparation "$preparationMode" || setupResult=$?
    [ "$setupResult" -ne 1 ] || exit 1
    [ "$setupResult" -ne 2 ] || exit 0
    case "$commandName" in runtime-prepare|runtime-retry) printStatus; exit 0 ;; esac ;;
  proxy-set)
    [ "$#" -eq 2 ] && validateProxy "$2" || reportFailure proxy_configuration_invalid 'Usage: proxy-set http[s]://host:port or socks5[h]://host:port'
    mkdir -p "$configDirectory"
    printf '%s' "$2" > "$configDirectory/proxy-url.$$"
    mv -f "$configDirectory/proxy-url.$$" "$configDirectory/proxy-url"
    writeDiagnostic proxy_configured success
    exit 0 ;;
  proxy-clear) rm -f "$configDirectory/proxy-url" "$configDirectory/proxy.json"; exit 0 ;;
  proxy-status)
    readProxy || reportFailure proxy_configuration_invalid 'Reset the stored proxy with proxy-set or proxy-clear'
    source=environment; [ -z "$proxyUrl" ] || source=persistent
    printf '{"source":"%s","configurationPath":"%s"}\n' "$source" "$(escapeJson "$configDirectory")"
    exit 0 ;;
  __runtime-prepare) unset HIPO_SETUP_DEADLINE_UNIX_SECONDS; runLockedPreparation advance; exit $? ;;
esac

if [ "$isHook" = true ]; then writeDiagnostic hook_invoked observed; fi
if ! isReady; then
  case "$commandName" in
    document-permission) printf '{}\n'; exit 0 ;;
    document-transfer) reportFailure runtime_missing 'Prepare the runtime explicitly before an original document transfer' ;;
  esac
  if [ "$commandName" = mcp ]; then
    . "$scriptDirectory/mcp-bootstrap.sh"
    serveMcpBootstrap "$@"
    exit 0
  fi
  preparationResult=0
  requestPreparation || preparationResult=$?
  if [ "$isHook" = true ]; then
    writeDiagnostic capture_gap runtime_unavailable runtime_missing
    if [ "$preparationResult" -eq 0 ]; then
      printHookResponse 'Hipohipo is preparing its runtime. Submit the share command again when it is ready.'
    else
      printHookResponse 'Hipohipo could not prepare its runtime. Check Hipohipo status before sharing again.'
    fi
    exit 0
  fi
  if [ "$commandName" = mcp ]; then
    . "$scriptDirectory/mcp-bootstrap.sh"
    serveMcpBootstrap "$@"
    exit 0
  fi
  [ "$preparationResult" -ne 2 ] || reportFailure retry_cooldown 'Preparation is stopped after failure; request runtime-retry explicitly'
  remainingWait=40
  until isReady; do
    hasCooldown && reportFailure preparation_failed 'Runtime download failed; inspect runtime-status'
    [ "$remainingWait" -gt 0 ] || reportFailure runtime_preparing 'Runtime is still downloading in the background'
    remainingWait=$((remainingWait - 1))
    sleep 0.2
  done
fi
finishExpiredLogin
# Updating recency before exec also protects the native handoff from eviction.
date -u +%Y-%m-%dT%H:%M:%SZ > "$runtimeDirectory/last-used"
exec "$runtimePath" __runtime-run "$@"
