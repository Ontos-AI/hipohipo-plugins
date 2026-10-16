#!/bin/sh
# Bootstrap using only the POSIX shell and standard system download tools.
set -eu
umask 077
invocationStarted=$(date +%s)

scriptDirectory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
pluginRoot=$(CDPATH= cd -- "$scriptDirectory/.." && pwd)
manifestPath=${HIPO_RUNTIME_MANIFEST:-$pluginRoot/runtime-manifest.json}
pinsPath=${manifestPath%.json}.sh
commandName=${1:-runtime-status}
host=${HIPO_CAPTURE_HOST:-}
event=''
previousArgument=''
for argument in "$@"; do
  [ "$previousArgument" != --host ] || host=$argument
  [ "$previousArgument" != --event ] || event=$argument
  previousArgument=$argument
done
case "$host" in cursor|cursor-plugin|claude-code|codex) ;; *) host='' ;; esac
case "$event" in sessionStart|beforeSubmitPrompt|afterAgentResponse|stop|sessionEnd|SessionStart|UserPromptSubmit|Stop|PreCompact|SessionEnd|Interrupt|StopFailure) ;; *) event='' ;; esac
isHook=false
case "$commandName" in hook|host-hook) isHook=true ;; esac
temporaryDirectory=''
hasPreparationLock=false

printHookResponse() {
  if [ "$commandName" = hook ] && [ "$event" = beforeSubmitPrompt ]; then
    printf '{"continue":true}\n'
  else
    printf '{}\n'
  fi
}

escapeJson() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n\r\t' '   '; }

calculateDigest() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | cut -d ' ' -f 1
  else shasum -a 256 < "$1" | cut -d ' ' -f 1; fi
}

verifyFile() {
  [ -f "$1" ] && [ ! -L "$1" ] && [ "$(wc -c < "$1")" -eq "$2" ] && [ "$(calculateDigest "$1")" = "$3" ]
}

isReady() { [ -x "$runtimePath" ] && verifyFile "$runtimePath" "$executableSize" "$executableDigest"; }

writeDiagnostic() (
  # Logging is best effort and cannot prevent ordinary host conversations.
  mkdir -p "$configDirectory/logs" || exit 0
  diagnosticLock="$configDirectory/logs/bootstrap-write"
  mkdir "$diagnosticLock" 2>/dev/null || exit 0
  trap 'rmdir "$diagnosticLock" 2>/dev/null || :' 0
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
  [ -z "${logPath:-}" ] || writeDiagnostic command_failed failed "$1"
  printf 'Hipohipo bootstrap [%s]: %s. Run runtime-retry, then reconnect MCP. Local log: %s\n' "$1" "$2" "${logPath:-unavailable}" >&2
  if [ "$isHook" = true ]; then printHookResponse; exit 0; fi
  exit 1
}

releasePreparation() {
  [ -z "$temporaryDirectory" ] || rm -rf "$temporaryDirectory"
  if [ "$hasPreparationLock" = true ] && [ "$(cat "$preparationLock/owner" 2>/dev/null || :)" = "$$" ]; then
    rm -f "$preparationLock/owner" "$preparationLock/created"
    rmdir "$preparationLock" 2>/dev/null || :
  fi
}

readPreparationCreated() {
  if [ -f "$preparationLock/created" ]; then cat "$preparationLock/created"; return; fi
  # Recover an owner that died between mkdir and writing lock metadata.
  case "$platform" in
    darwin-*) stat -f %m "$preparationLock" 2>/dev/null ;;
    *) stat -c %Y "$preparationLock" 2>/dev/null ;;
  esac
}

acquirePreparation() {
  mkdir -p "$cacheDirectory/locks" "$cacheDirectory/state"
  if mkdir "$preparationLock" 2>/dev/null; then
    date +%s > "$preparationLock/created"
    printf '0\n' > "$preparationLock/owner"
    return 0
  fi
  lockOwner=$(cat "$preparationLock/owner" 2>/dev/null || printf 0)
  lockCreated=$(readPreparationCreated || date +%s)
  case "$lockOwner:$lockCreated" in *[!0-9:]*) return 1 ;; esac
  if [ "$lockOwner" -ne 0 ] && kill -0 "$lockOwner" 2>/dev/null; then return 1; fi
  [ "$lockOwner" -ne 0 ] || [ "$(( $(date +%s) - lockCreated ))" -gt 5 ] || return 1
  # Serialize reclamation; publication is additionally protected by Go's
  # kernel locks, shared with older launchers and detached capture workers.
  mkdir "$preparationLock-recovery" 2>/dev/null || return 1
  if [ "$(cat "$preparationLock/owner" 2>/dev/null || printf 0)" = "$lockOwner" ] && [ "$(readPreparationCreated || :)" = "$lockCreated" ]; then
    rm -f "$preparationLock/owner" "$preparationLock/created"
    rmdir "$preparationLock" 2>/dev/null || :
  fi
  rmdir "$preparationLock-recovery"
  acquirePreparation
}

hasCooldown() {
  [ -f "$failurePath" ] || return 1
  failedAt=$(sed -n '1p' "$failurePath")
  case "$failedAt" in ''|*[!0-9]*) return 1 ;; esac
  [ "$(( $(date +%s) - failedAt ))" -lt 180 ]
}

writeFailure() {
  { date +%s; printf '%s\n' "$1"; } > "$failurePath.$$"
  mv -f "$failurePath.$$" "$failurePath"
  writeDiagnostic preparation_completed failed "$1"
}

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

prepareRuntime() {
  hasPreparationLock=true
  printf '%s\n' "$$" > "$preparationLock/owner"
  trap releasePreparation 0
  trap 'exit 130' INT
  trap 'exit 143' TERM
  isReady && return 0
  for tool in curl gzip; do
    command -v "$tool" >/dev/null 2>&1 || { writeFailure dependency_missing; return 1; }
  done
  readProxy || { writeFailure proxy_configuration_invalid; return 1; }
  mkdir -p "$runtimeDirectory"
  for abandoned in "$runtimeDirectory"/.download.*; do
    [ ! -d "$abandoned" ] || [ -L "$abandoned" ] || rm -rf "$abandoned"
  done
  temporaryDirectory=$(mktemp -d "$runtimeDirectory/.download.XXXXXX")
  writeDiagnostic preparation_started started
  deadline=$(( $(date +%s) + downloadTimeoutSeconds ))
  attempt=1
  while :; do
    remaining=$(( deadline - $(date +%s) ))
    [ "$remaining" -gt 0 ] || { writeFailure preparation_timeout; return 1; }
    # Redirect curl's raw errors away from host pipes: proxy URLs may contain
    # credentials. Persist only a typed code and byte count.
    if [ -n "$proxyUrl" ]; then
      curl --proxy "$proxyUrl" --noproxy '' --fail --silent --location --max-redirs 5 --proto '=https' --proto-redir '=https' \
        --continue-at - --connect-timeout 10 --max-time "$remaining" --max-filesize "$compressedSize" \
        --output "$temporaryDirectory/runtime.gz" "$artifactUrl" 2>/dev/null && break
    else
      curl --fail --silent --location --max-redirs 5 --proto '=https' --proto-redir '=https' \
        --continue-at - --connect-timeout 10 --max-time "$remaining" --max-filesize "$compressedSize" \
        --output "$temporaryDirectory/runtime.gz" "$artifactUrl" 2>/dev/null && break
    fi
    writeDiagnostic download_attempt failed download_network_error
    [ "$attempt" -lt "$downloadMaximumAttempts" ] || { writeFailure download_network_error; return 1; }
    attempt=$((attempt + 1))
    sleep 1
  done
  verifyFile "$temporaryDirectory/runtime.gz" "$compressedSize" "$compressedDigest" || { writeFailure digest_mismatch; return 1; }
  writeDiagnostic compressed_verified success '' "$compressedSize"
  # A pinned compressed checksum precedes decompression; the extracted program
  # must separately match its own size and digest before any execution.
  gzip -dc "$temporaryDirectory/runtime.gz" > "$temporaryDirectory/hipohipo" 2>/dev/null || { writeFailure gzip_invalid; return 1; }
  verifyFile "$temporaryDirectory/hipohipo" "$executableSize" "$executableDigest" || { writeFailure digest_mismatch; return 1; }
  chmod 700 "$temporaryDirectory/hipohipo"
  HIPO_RUNTIME_MANIFEST="$manifestPath" "$temporaryDirectory/hipohipo" __runtime-publish >/dev/null 2>/dev/null || { writeFailure runtime_publish_failed; return 1; }
  rm -f "$failurePath"
  writeDiagnostic preparation_completed success '' "$executableSize"
}

requestPreparation() {
  isReady && return 0
  hasCooldown && return 2
  acquirePreparation || return 0
  # nohup plus closed standard streams lets a Hook exit while preparation
  # continues, without keeping MCP pipes open or launching a permanent daemon.
  nohup sh "$scriptDirectory/launch.sh" __runtime-prepare </dev/null >/dev/null 2>&1 3>&- 4<&- 5>&- &
  writeDiagnostic preparation_requested started
}

printStatus() {
  ready=false
  isReady && ready=true
  lastErrorCode=''
  retryEligibleAt=''
  if [ -f "$failurePath" ]; then
    lastErrorCode=$(sed -n '2p' "$failurePath" | tr -cd 'a-z0-9_')
    failedAt=$(sed -n '1p' "$failurePath")
    case "$failedAt" in ''|*[!0-9]*) ;; *)
      eligibleSeconds=$((failedAt + 180))
      case "$platform" in
        darwin-*) retryEligibleAt=$(date -u -r "$eligibleSeconds" +%Y-%m-%dT%H:%M:%SZ) ;;
        *) retryEligibleAt=$(date -u -d "@$eligibleSeconds" +%Y-%m-%dT%H:%M:%SZ) ;;
      esac ;;
    esac
  fi
  printf '{"runtimeVersion":"%s","launcherVersion":"%s","platform":"%s","isReady":%s,"executablePath":"%s","logPath":"%s","lastErrorCode":"%s","retryEligibleAt":%s}\n' \
    "$runtimeVersion" "$runtimeVersion" "$platform" "$ready" "$(escapeJson "$runtimePath")" "$(escapeJson "$logPath")" "$lastErrorCode" "$(if [ -n "$retryEligibleAt" ]; then printf '"%s"' "$retryEligibleAt"; else printf null; fi)"
}

installPackage() {
  destination="$HOME/.cursor/plugins/local/hipohipo"
  [ "$pluginRoot" != "$destination" ] || reportFailure already_installed 'Reload Cursor to use the installed plugin'
  [ ! -L "$destination" ] || reportFailure installation_invalid 'The local plugin destination must not be a symlink'
  [ -z "$(find "$pluginRoot" -type l -print)" ] || reportFailure installation_invalid 'The plugin package must not contain symlinks'
  mkdir -p "$destination"
  rm -rf "$destination/bin"
  rm -f "$destination/hipohipo.exe"
  cp -Rf "$pluginRoot/." "$destination/"
  printf '{"mcpServers":{"hipohipo":{"command":"%s/hipohipo","args":["mcp"],"cwd":"%s"}}}\n' \
    "$(escapeJson "$destination")" "$(escapeJson "$destination")" > "$destination/mcp.json"
  hookPath="$destination/hooks/hooks.json"
  [ ! -f "$destination/hooks/cursor.json" ] || hookPath="$destination/hooks/cursor.json"
  quotedDispatcher=$(printf '%s' "$destination/scripts/run.cmd" | sed "s/'/'\"'\"'/g")
  {
    printf '{"version":1,"hooks":{'
    separator=''
    for hookEvent in sessionStart beforeSubmitPrompt afterAgentResponse stop sessionEnd; do
      printf '%s"%s":[{"command":"%s","timeout":5}]' "$separator" "$hookEvent" "$(escapeJson "'$quotedDispatcher' hook --event $hookEvent")"
      separator=','
    done
    printf '}}\n'
  } > "$hookPath"
  printf 'Installed local plugin: %s\nReload Cursor to use the plugin.\n' "$destination"
}

command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || reportFailure dependency_missing 'SHA256 verification requires sha256sum or shasum'
[ -f "$pinsPath" ] || reportFailure manifest_missing 'Reinstall the plugin to restore its runtime pins'
# This is generated from the validated release manifest, never user input.
. "$pinsPath"
verifyFile "$manifestPath" "$manifestSize" "$manifestDigest" || reportFailure manifest_mismatch 'Runtime manifest and script pins differ'
case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) platform=darwin-arm64; artifactPlatform=macos-arm64 ;;
  Linux/x86_64|Linux/amd64) platform=linux-amd64; artifactPlatform=linux-amd64 ;;
  Linux/aarch64|Linux/arm64) platform=linux-arm64; artifactPlatform=linux-arm64 ;;
  *) reportFailure platform_unsupported "Hipohipo does not support $(uname -s)/$(uname -m)" ;;
esac
selectArtifact "$artifactPlatform"
case "$platform" in
  darwin-*) cacheDirectory=${HIPO_RUNTIME_CACHE_DIR:-$HOME/Library/Caches/Hipohipo/runtimes}; configDirectory=${HIPO_RUNTIME_CONFIG_DIR:-$HOME/Library/Application Support/Hipohipo/runtime-launcher} ;;
  *) cacheDirectory=${HIPO_RUNTIME_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/Hipohipo/runtimes}; configDirectory=${HIPO_RUNTIME_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/Hipohipo/runtime-launcher} ;;
esac
case "$cacheDirectory:$configDirectory:$manifestPath" in /*:/*:/*) ;; *) reportFailure configuration_invalid 'Runtime cache, configuration and manifest paths must be absolute' ;; esac
cacheKey="$runtimeVersion-$platform-$(printf '%.16s' "$compressedDigest")"
runtimeDirectory="$cacheDirectory/versions/$runtimeVersion/$platform/$(printf '%.16s' "$compressedDigest")"
runtimePath="$runtimeDirectory/hipohipo"
preparationLock="$cacheDirectory/locks/$cacheKey-script-prepare"
failurePath="$cacheDirectory/state/$cacheKey-script-failure"
logPath="$configDirectory/logs/bootstrap.jsonl"
downloadTimeoutSeconds=${HIPO_RUNTIME_DOWNLOAD_TIMEOUT_SECONDS:-600}
downloadMaximumAttempts=${HIPO_RUNTIME_DOWNLOAD_ATTEMPTS:-5}
case "$downloadTimeoutSeconds:$downloadMaximumAttempts" in *[!0-9:]*|:*|*:) reportFailure configuration_invalid 'Download limits must be integers' ;; esac
[ "$downloadTimeoutSeconds" -ge 1 ] && [ "$downloadTimeoutSeconds" -le 1800 ] && [ "$downloadMaximumAttempts" -ge 1 ] && [ "$downloadMaximumAttempts" -le 10 ] || reportFailure configuration_invalid 'Download limits are out of range'
export HIPO_RUNTIME_CACHE_DIR="$cacheDirectory" HIPO_RUNTIME_CONFIG_DIR="$configDirectory" HIPO_RUNTIME_MANIFEST="$manifestPath" HIPO_CAPTURE_HOST="$host"

case "$commandName" in
  install) installPackage; exit 0 ;;
  runtime-status) printStatus; exit 0 ;;
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
  __runtime-prepare) prepareRuntime; exit $? ;;
  runtime-retry)
    deadline=$(( $(date +%s) + downloadTimeoutSeconds + 5 ))
    until acquirePreparation; do
      isReady && { printStatus; exit 0; }
      [ "$(date +%s)" -lt "$deadline" ] || reportFailure preparation_busy 'Another preparation is still running'
      sleep 1
    done
    prepareRuntime || reportFailure preparation_failed 'Inspect runtime-status and the local log'
    releasePreparation
    printStatus
    exit 0 ;;
esac

if [ "$isHook" = true ]; then writeDiagnostic hook_invoked observed; fi
if ! isReady; then
  preparationResult=0
  requestPreparation || preparationResult=$?
  if [ "$isHook" = true ]; then
    writeDiagnostic capture_gap runtime_unavailable runtime_missing
    printHookResponse
    exit 0
  fi
  if [ "$commandName" = mcp ]; then
    . "$scriptDirectory/mcp-bootstrap.sh"
    serveMcpBootstrap "$@"
    exit 0
  fi
  [ "$preparationResult" -ne 2 ] || reportFailure retry_cooldown 'Automatic preparation is paused for three minutes'
  remainingWait=40
  until isReady; do
    hasCooldown && reportFailure preparation_failed 'Runtime download failed; inspect runtime-status'
    [ "$remainingWait" -gt 0 ] || reportFailure runtime_preparing 'Runtime is still downloading in the background'
    remainingWait=$((remainingWait - 1))
    sleep 0.2
  done
fi
# Updating recency before exec also protects the native handoff from eviction.
date -u +%Y-%m-%dT%H:%M:%SZ > "$runtimeDirectory/last-used"
exec "$runtimePath" __runtime-run "$@"
