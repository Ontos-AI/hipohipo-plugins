# Shared preparation state is owned under a retained kernel-locked file. The
# foreground caller can always advance it; no detached process is required.
acquireFileLock() {
  lockResult=0
  case "$platform" in
    darwin-*)
      command -v lockf >/dev/null 2>&1 || return 69
      # Descriptor form implies -k and uses BSD flock, matching the Go layer.
      lockf -s -t 0 "$1" || lockResult=$? ;;
    *)
      command -v flock >/dev/null 2>&1 || return 69
      flock -n -E 75 "$1" || lockResult=$? ;;
  esac
  return "$lockResult"
}

readPreparationState() {
  attemptId=''; startedAt=0; deadlineAt=0; runtimeState=not_prepared
  preparationPhase=download; networkFailures=0; downloadedBytes=0; lastErrorCode=''
  downloadOrigin=primary; originFallbacks=0
  artifactIdentity=''; artifactAttemptId=''
  [ -f "$preparationStatePath" ] || return 0
  preparationFields=$(HIPO_BOOTSTRAP_JSON_MODE=preparation awk -f "$scriptDirectory/mcp-json.awk" < "$preparationStatePath")
  case "$preparationFields" in invalid-*) runtimeState=failed; lastErrorCode=preparation_state_invalid; return 0 ;; esac
  { IFS= read -r attemptId; IFS= read -r startedAt; IFS= read -r deadlineAt
    IFS= read -r runtimeState; IFS= read -r preparationPhase; IFS= read -r networkFailures
    IFS= read -r downloadedBytes; IFS= read -r lastErrorCode
    IFS= read -r downloadOrigin; IFS= read -r originFallbacks || :
    IFS= read -r artifactIdentity || :; IFS= read -r artifactAttemptId || :
  } <<FIELDS
$preparationFields
FIELDS
  if [ -n "$attemptId" ]; then
    partialPath="$runtimeDirectory/preparation/${artifactAttemptId:-$attemptId}/runtime.gz"
    if [ -f "$partialPath" ] && [ ! -L "$partialPath" ]; then
      downloadedBytes=$(wc -c < "$partialPath" | tr -d ' ')
    fi
  fi
  if [ "$runtimeState" = ready ] && ! isReady; then runtimeState=not_prepared; preparationPhase=download; fi
  if [ "$runtimeState" = preparing ] && [ "$(date +%s)" -ge "$deadlineAt" ]; then
    runtimeState=failed; lastErrorCode=preparation_timeout
  fi
}

savePreparationState() {
  printf '{"attemptId":"%s","startedAtUnixSeconds":%s,"deadlineAtUnixSeconds":%s,"state":"%s","phase":"%s","networkFailures":%s,"downloadedBytes":%s,"lastErrorCode":"%s","downloadOrigin":"%s","originFallbacks":%s,"artifactIdentity":"%s","artifactAttemptId":"%s"}\n' \
    "$attemptId" "$startedAt" "$deadlineAt" "$runtimeState" "$preparationPhase" "$networkFailures" "$downloadedBytes" "$lastErrorCode" "$downloadOrigin" "$originFallbacks" "$artifactIdentity" "$artifactAttemptId" > "$preparationStatePath.$$" &&
    mv -f "$preparationStatePath.$$" "$preparationStatePath"
}

writeFailure() {
  runtimeState=failed; lastErrorCode=$1
  savePreparationState || return 70
  writeDiagnostic preparation_completed failed "$1"
  return 1
}

hasCooldown() { readPreparationState; [ "$runtimeState" = failed ]; }

canRetainPreparationArtifact() {
  [ "$runtimeState" = failed ] && [ "$artifactIdentity" = "$runtimeVersion/$platform/$compressedDigest/$compressedSize" ] || return 1
  case "$lastErrorCode" in preparation_timeout|download_network_error|download_interrupted|download_http_[45][0-9][0-9]) ;; *) return 1 ;; esac
  retainedDirectory="$runtimeDirectory/preparation/${artifactAttemptId:-$attemptId}"
  [ -d "$retainedDirectory" ] && [ ! -L "$retainedDirectory" ] && [ -f "$retainedDirectory/runtime.gz" ] && [ ! -L "$retainedDirectory/runtime.gz" ] || return 1
  retainedBytes=$(wc -c < "$retainedDirectory/runtime.gz" | tr -d ' ')
  [ "$retainedBytes" -gt 0 ] && [ "$retainedBytes" -le "$compressedSize" ]
}

reservePreparation() {
  readPreparationState
  if isReady; then return 0; fi
  [ "$lastErrorCode" != preparation_state_invalid ] || return 1
  if [ "$runtimeState" = failed ] && [ "${1:-}" != explicit ]; then return 1; fi
  if [ -z "$attemptId" ] || [ "$runtimeState" = failed ] || [ "$runtimeState" = not_prepared ]; then
    retainedArtifactId=''
    if [ "${1:-}" = explicit ] && canRetainPreparationArtifact; then retainedArtifactId=${artifactAttemptId:-$attemptId}; fi
    startedAt=$(date +%s); deadlineAt=$((startedAt + downloadTimeoutSeconds))
    attemptId="$startedAt-$$"; runtimeState=preparing; preparationPhase=download
    # Reference the retained archive in the atomic journal; no copy or move can
    # leave the previous attempt without its prefix if this process is killed.
    artifactIdentity="$runtimeVersion/$platform/$compressedDigest/$compressedSize"
    artifactAttemptId=${retainedArtifactId:-$attemptId}
    networkFailures=0; downloadedBytes=0; lastErrorCode=''
    downloadOrigin=primary; originFallbacks=0
    if [ "$host" = workbuddy ] && [ -n "${artifactMirrorUrl:-}" ]; then downloadOrigin=mirror; fi
    savePreparationState || return 70
    rm -f "$publicationErrorPath" 2>/dev/null || :
    writeDiagnostic preparation_requested started
  fi
}

printStatus() {
  readPreparationState
  ready=false; isReady && ready=true
  if [ "$ready" = true ]; then runtimeState=ready; preparationPhase=ready; fi
  [ -z "${transientPreparationError:-}" ] || { runtimeState=failed; lastErrorCode=$transientPreparationError; }
  [ "${hasContendedPreparation:-false}" != true ] || [ "$runtimeState" != not_prepared ] || runtimeState=preparing
  nextAction=continue_setup
  if [ "$runtimeState" = failed ]; then
    case "$lastErrorCode" in
      *permission*|local_*|preparation_state_invalid|dependency_missing|lock_*|*configuration*|runtime_publish_failed) nextAction=inspect_error ;;
      *) nextAction=request_runtime_retry ;;
    esac
  fi
  [ "$runtimeState" != ready ] || nextAction=none
  publicationError=''; [ ! -f "$publicationErrorPath" ] || publicationError=$publicationErrorPath
  printf '{"state":"%s","nextAction":"%s","runtimeVersion":"%s","launcherVersion":"%s","platform":"%s","isReady":%s,"executablePath":"%s","logPath":"%s","publicationErrorPath":"%s","lastErrorCode":"%s","retryEligibleAt":null,"attemptId":"%s","startedAtUnixSeconds":%s,"deadlineAtUnixSeconds":%s,"phase":"%s","downloadedBytes":%s}\n' \
    "${1:-$runtimeState}" "${2:-$nextAction}" "$runtimeVersion" "$runtimeVersion" "$platform" "$ready" "$(escapeJson "$runtimePath")" "$(escapeJson "$logPath")" "$(escapeJson "$publicationError")" "$lastErrorCode" "$attemptId" "$startedAt" "$deadlineAt" "$preparationPhase" "$downloadedBytes"
}

printSetupStatus() {
  setupStatus=$(printStatus)
  case "$commandName" in
    login|login-device) printf '%s,"operationExecuted":false}\n' "${setupStatus%\}}" ;;
    *) printf '%s\n' "$setupStatus" ;;
  esac
}

readSliceRemaining() {
  sliceDeadline=${HIPO_SETUP_DEADLINE_UNIX_SECONDS:-$deadlineAt}
  [ "$sliceDeadline" -le "$deadlineAt" ] || sliceDeadline=$deadlineAt
  remaining=$((sliceDeadline - $(date +%s)))
  if [ "$(date +%s)" -ge "$deadlineAt" ]; then writeFailure preparation_timeout; return 1; fi
  [ "$remaining" -gt 0 ] || return 2
}

downloadPreparationSlice() {
  downloadOffset=0
  [ ! -f "$archivePath" ] || downloadOffset=$(wc -c < "$archivePath" | tr -d ' ')
  downloadedBytes=$downloadOffset
  [ "$downloadOffset" -le "$compressedSize" ] || { writeFailure size_mismatch; return 1; }
  [ "$downloadOffset" -ne "$compressedSize" ] || return 0
  readSliceRemaining || return $?
  set -- --fail --silent --location --max-redirs 5 --proto '=https' --proto-redir '=https' \
    --continue-at - --connect-timeout 10 --speed-limit 1 --speed-time 10 --max-time "$remaining" --max-filesize "$compressedSize" \
    --suppress-connect-headers --dump-header "$attemptDirectory/headers" --output "$archivePath"
  if [ -n "$proxyUrl" ]; then set -- --proxy "$proxyUrl" --noproxy '' "$@"; fi
  downloadExit=0
  downloadAddress=$artifactUrl
  if [ "$downloadOrigin" = mirror ]; then
    [ -n "${artifactMirrorUrl:-}" ] || { writeFailure configuration_invalid; return 1; }
    downloadAddress=$artifactMirrorUrl
  fi
  curl "$@" "$downloadAddress" 2>/dev/null || downloadExit=$?
  downloadedBytes=0
  [ ! -f "$archivePath" ] || downloadedBytes=$(wc -c < "$archivePath" | tr -d ' ')
  savePreparationState || return 70
  # Only the final response headers count after redirects or proxy CONNECT.
  responseFields=$(awk 'tolower($1) ~ /^http\// { status=$2; range="" } tolower($1)=="content-range:" { range=$2 " " $3 } END { gsub("\r", "", range); print status; print range }' "$attemptDirectory/headers" 2>/dev/null || :)
  { IFS= read -r responseStatus; IFS= read -r responseRange || :; } <<FIELDS
$responseFields
FIELDS
  if [ "$downloadOffset" -gt 0 ] && [ "$responseStatus" = 200 ]; then writeFailure download_resume_unsupported; return 1; fi
  if [ "$responseStatus" = 416 ]; then writeFailure download_range_invalid; return 1; fi
  if [ "$responseStatus" = 206 ]; then
    [ "$responseRange" = "bytes $downloadOffset-$((compressedSize - 1))/$compressedSize" ] || { writeFailure download_range_invalid; return 1; }
  elif [ "$responseStatus" = 200 ] && [ "$downloadOffset" -eq 0 ]; then :
  elif [ -n "$responseStatus" ] && [ "$responseStatus" -lt 400 ]; then writeFailure download_response_invalid; return 1
  elif [ "$downloadExit" -eq 0 ]; then writeFailure download_response_invalid; return 1
  fi
  if [ "$downloadExit" -eq 0 ]; then return 0; fi
  if [ "$(date +%s)" -ge "$deadlineAt" ]; then writeFailure preparation_timeout; return 1; fi
  if [ "$downloadExit" -eq 28 ] && [ "$(date +%s)" -ge "$sliceDeadline" ]; then return 2; fi
  case "$downloadExit" in
    33) writeFailure download_resume_unsupported; return 1 ;;
    23|26) writeFailure local_io_error; return 1 ;;
    63) writeFailure size_mismatch; return 1 ;;
  esac
  networkFailures=$((networkFailures + 1))
  if [ "$networkFailures" -ge "$downloadMaximumAttempts" ]; then writeFailure download_network_error; return 1; fi
  if [ "$originFallbacks" -eq 0 ] && [ -n "${artifactMirrorUrl:-}" ]; then
    if [ "$downloadOrigin" = mirror ]; then downloadOrigin=primary; else downloadOrigin=mirror; fi
    originFallbacks=1
    # Both origins pin identical compressed bytes. Retain the partial prefix;
    # the next request validates its Range and final size/digest before use.
  fi
  savePreparationState || return 70
  return 3
}

runBoundedPreparationStage() {
  readSliceRemaining || return $?
  stageResult=0
  "$@" </dev/null &
  stageProcess=$!
  (sleep "$remaining"; kill -TERM "$stageProcess" 2>/dev/null || :) </dev/null >/dev/null 2>&1 9>&- &
  stageWatchdog=$!
  wait "$stageProcess" || stageResult=$?
  kill "$stageWatchdog" 2>/dev/null || :
  wait "$stageWatchdog" 2>/dev/null || :
  readSliceRemaining || return $?
  return "$stageResult"
}

advancePreparation() {
  reservePreparation "${1:-}" || return $?
  isReady && return 0
  attemptDirectory="$runtimeDirectory/preparation/${artifactAttemptId:-$attemptId}"
  mkdir -p "$attemptDirectory" "$configDirectory/logs" || return 70
  archivePath="$attemptDirectory/runtime.gz"
  stagedPath="$attemptDirectory/hipohipo"
  for tool in curl gzip; do command -v "$tool" >/dev/null 2>&1 || { writeFailure dependency_missing; return 1; }; done
  readProxy || { writeFailure proxy_configuration_invalid; return 1; }
  while :; do
    readSliceRemaining || return $?
    case "$preparationPhase" in
      download)
        transferResult=0; downloadPreparationSlice || transferResult=$?
        case "$transferResult" in 0) preparationPhase=verify; savePreparationState || return 70 ;; 3) sleep 0.2 ;; *) return "$transferResult" ;; esac ;;
      verify)
        stageResult=0
        runBoundedPreparationStage verifyFile "$archivePath" "$compressedSize" "$compressedDigest" || stageResult=$?
        case "$stageResult" in 0) ;; 2) return 2 ;; *) [ "$runtimeState" = failed ] || writeFailure digest_mismatch; return 1 ;; esac
        runBoundedPreparationStage gzip -dc "$archivePath" > "$stagedPath" 2>/dev/null || stageResult=$?
        case "$stageResult" in 0) ;; 2) return 2 ;; *) [ "$runtimeState" = failed ] || writeFailure gzip_invalid; return 1 ;; esac
        runBoundedPreparationStage verifyFile "$stagedPath" "$executableSize" "$executableDigest" || stageResult=$?
        case "$stageResult" in 0) ;; 2) return 2 ;; *) [ "$runtimeState" = failed ] || writeFailure digest_mismatch; return 1 ;; esac
        chmod 700 "$stagedPath" || return 70
        preparationPhase=publish; savePreparationState || return 70 ;;
      publish)
        # The publisher owns its distinct native prepare/use locks and receives
        # both deadlines. A temporary use-lock wait must not fail this attempt.
        publicationResult=0
        HIPO_RUNTIME_PREPARATION_DEADLINE="$deadlineAt" HIPO_SETUP_DEADLINE_UNIX_SECONDS="$sliceDeadline" \
          "$stagedPath" __runtime-publish >/dev/null 2>"$attemptDirectory/publish.stderr" 9>&- &
        publisher=$!
        (sleep "$remaining"; kill -TERM "$publisher" 2>/dev/null || :) </dev/null >/dev/null 2>&1 9>&- &
        publicationWatchdog=$!
        wait "$publisher" || publicationResult=$?
        kill "$publicationWatchdog" 2>/dev/null || :
        wait "$publicationWatchdog" 2>/dev/null || :
        if [ "$(date +%s)" -ge "$deadlineAt" ]; then writeFailure preparation_timeout; return 1; fi
        if [ "$publicationResult" -ne 0 ]; then
          dd if="$attemptDirectory/publish.stderr" of="$publicationErrorPath" bs=8192 count=1 2>/dev/null || :
          [ "$(date +%s)" -lt "$sliceDeadline" ] || return 2
          writeFailure runtime_publish_failed; return 1
        fi
        isReady || { writeFailure runtime_publish_failed; return 1; }
        runtimeState=ready; preparationPhase=ready; lastErrorCode=''
        savePreparationState || return 70
        writeDiagnostic preparation_completed success '' "$executableSize"
        return 0 ;;
      ready) return 0 ;;
      *) writeFailure preparation_state_invalid; return 1 ;;
    esac
  done
}

runLockedPreparation() (
  mkdir -p "$cacheDirectory/locks" "$cacheDirectory/state" || exit 70
  [ ! -L "$preparationLock" ] && [ ! -L "$preparationStatePath" ] || exit 70
  ( : >>"$preparationLock" ) 2>/dev/null || exit 70
  [ -f "$preparationLock" ] || exit 70
  { exec 9>>"$preparationLock"; } 2>/dev/null || exit 70
  acquireFileLock 9 || exit $?
  if [ "${1:-}" = reserve ]; then reservePreparation "${2:-}"; else advancePreparation "${2:-}"; fi
)

continueSetupPreparation() {
  setupWaitSeconds=${HIPO_SETUP_WAIT_TIMEOUT_SECONDS:-30}
  case "$setupWaitSeconds" in ''|*[!0-9]*) transientPreparationError=configuration_invalid; printSetupStatus; return 1 ;; esac
  [ "$setupWaitSeconds" -ge 1 ] && [ "$setupWaitSeconds" -le 30 ] || { transientPreparationError=configuration_invalid; printSetupStatus; return 1; }
  setupDeadline=$((invocationStarted + setupWaitSeconds))
  if [ -n "${HIPO_SETUP_DEADLINE_UNIX_SECONDS:-}" ]; then
    case "$HIPO_SETUP_DEADLINE_UNIX_SECONDS" in *[!0-9]*) transientPreparationError=configuration_invalid; printSetupStatus; return 1 ;; esac
    [ "${#HIPO_SETUP_DEADLINE_UNIX_SECONDS}" -le 12 ] || { transientPreparationError=configuration_invalid; printSetupStatus; return 1; }
    [ "$HIPO_SETUP_DEADLINE_UNIX_SECONDS" -ge "$setupDeadline" ] || setupDeadline=$HIPO_SETUP_DEADLINE_UNIX_SECONDS
  fi
  case "$commandName" in login|login-device)
    loginPreparationDeadline=$((HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS / 1000))
    [ "$loginPreparationDeadline" -ge "$setupDeadline" ] || setupDeadline=$loginPreparationDeadline ;;
  esac
  HIPO_SETUP_DEADLINE_UNIX_SECONDS=$setupDeadline
  export HIPO_SETUP_DEADLINE_UNIX_SECONDS
  mode=${1:-}
  while :; do
    setupResult=0; runLockedPreparation advance "$mode" || setupResult=$?
    case "$setupResult" in
      0) return 0 ;;
      2) printSetupStatus; return 2 ;;
      75)
        hasContendedPreparation=true
        if [ "$(date +%s)" -ge "$HIPO_SETUP_DEADLINE_UNIX_SECONDS" ]; then printSetupStatus; return 2; fi
        mode=''; sleep 0.1 ;;
      *)
        case "$setupResult" in 69) transientPreparationError=lock_unavailable ;; 64|71) transientPreparationError=lock_unavailable ;; 70|73|74) transientPreparationError=local_io_error ;; esac
        printSetupStatus; return 1 ;;
    esac
  done
}

requestPreparation() {
  isReady && return 0
  reserveResult=0; runLockedPreparation reserve "${1:-}" || reserveResult=$?
  transientPreparationError=''; hasContendedPreparation=false
  case "$reserveResult" in
    0) ;;
    75) hasContendedPreparation=true; return 0 ;;
    69|64|71) transientPreparationError=lock_unavailable; return 2 ;;
    70|73|74) transientPreparationError=local_io_error; return 2 ;;
    1) return 2 ;;
    *) transientPreparationError=local_io_error; return 2 ;;
  esac
  # A Hook can finish promptly. Any later foreground operation can resume this
  # exact attempt even if the host terminates the detached worker.
  nohup sh "$scriptDirectory/launch.sh" __runtime-prepare </dev/null >/dev/null 2>&1 3>&- 4<&- 5>&- &
}
