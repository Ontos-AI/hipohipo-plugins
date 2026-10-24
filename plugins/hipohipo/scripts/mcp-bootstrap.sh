# Cold-start MCP adapter. Sourced only after launch.sh validates runtime pins.
# All protocol writes belong to the router. Pumps queue private frame files,
# avoiding interleaving JSON messages larger than a pipe's atomic write limit.
readMcpFields() {
  parsedFields=$(LC_ALL=C awk -f "$scriptDirectory/mcp-json.awk" "$1")
  { IFS= read -r frameValidity || :; IFS= read -r requestId || :; IFS= read -r methodName || :
    IFS= read -r toolName || :; IFS= read -r protocolVersion || :; IFS= read -r progressToken || :
    IFS= read -r cancelledId || :; IFS= read -r modernVersion || :; IFS= read -r responseOutcome || :
    IFS= read -r rawParameters || :; IFS= read -r responseVersion || :; IFS= read -r canChangeTools || :
    IFS= read -r canSubscribe || :; IFS= read -r canChangeResources || :; IFS= read -r argumentsValidity || :
    IFS= read -r requestKey || :; IFS= read -r cancelledKey || :; IFS= read -r isBackground || :
  } <<FIELDS
$parsedFields
FIELDS
}

writeMcpResult() {
  resultValue=$2
  if [ "${3:-}" = 2026-07-28 ]; then
    resultValue="${resultValue%\}},\"resultType\":\"complete\",\"ttlMs\":0,\"cacheScope\":\"private\",\"_meta\":{\"io.modelcontextprotocol/serverInfo\":{\"name\":\"hipohipo-plugin\",\"version\":\"$runtimeVersion\"}}}"
  fi
  printf '{"jsonrpc":"2.0","id":%s,"result":%s}\n' "$1" "$resultValue"
}

writeMcpError() {
  printf '{"jsonrpc":"2.0","id":%s,"error":{"code":%s,"message":"%s"}}\n' "$1" "$2" "$3"
}

queueMcpFrames() {
  frameNumber=0
  while IFS= read -r frame || [ -n "$frame" ]; do
    frameNumber=$((frameNumber + 1))
    framePath="$bootstrapDirectory/$1-$frameNumber.json"
    [ "${#frame}" -le 32000000 ] || frame='invalid oversized frame'
    printf '%s\n' "$frame" > "$framePath"
    printf '%s%s\n' "${1%"${1#?}"}" "$framePath"
  done
  printf '%s\n' "$2"
}

stopMcpRuntime() {
  exec 5>&-
  if [ -n "$backendProcess" ]; then
    # Let EOF release the child's runtime lease before escalating a stuck exit.
    (sleep 2; kill "$backendProcess" 2>/dev/null || :; sleep 2; kill -KILL "$backendProcess" 2>/dev/null || :) 3>&- 4<&- &
    shutdownGuard=$!
    wait "$backendProcess" 2>/dev/null || :
    # This timer owns no cleanup. Cancel without a catchable signal: Bash 3.2
    # can receive TERM before a freshly forked subshell resets inherited traps.
    kill -KILL "$shutdownGuard" 2>/dev/null || :
    wait "$shutdownGuard" 2>/dev/null || :
  fi
  [ -z "$backendReader" ] || kill "$backendReader" 2>/dev/null || :
  [ -z "$backendReader" ] || wait "$backendReader" 2>/dev/null || :
  backendProcess=''; backendReader=''; backendState=stopped
}

failMcpRuntime() {
  backendError=$1
  backendRetryAt=0
  stopMcpRuntime
  for forwardedPath in "$bootstrapDirectory"/forwarded-*; do
    [ -f "$forwardedPath" ] || continue
    writeMcpError "$(sed -n '1p' "$forwardedPath")" -32000 'Runtime stopped; request runtime_prepare explicitly to retry'
    rm -f "$forwardedPath"
  done
  writeDiagnostic mcp_runtime_failed failed "$backendError"
  completeMcpWaits
  printf '{"jsonrpc":"2.0","method":"notifications/tools/list_changed"}\n'
}

closeMcpBootstrap() {
  stopMcpRuntime
  kill "$inputReader" "$bootstrapClock" 2>/dev/null || :
  wait "$inputReader" "$bootstrapClock" 2>/dev/null || :
  exec 3>&- 4<&-
  rm -rf "$bootstrapDirectory"
}

startMcpRuntime() {
  [ "$backendState" = stopped ] && [ -z "$backendError" ] && [ -n "$initializationFrame" ] && isReady || return 0
  rm -f "$bootstrapDirectory/runtime-input" "$bootstrapDirectory/runtime-output"
  mkfifo "$bootstrapDirectory/runtime-input" "$bootstrapDirectory/runtime-output"
  backendGeneration=$((backendGeneration + 1))
  queueMcpFrames "R-$backendGeneration" "B$backendGeneration" < "$bootstrapDirectory/runtime-output" >&3 4<&- &
  backendReader=$!
  "$runtimePath" __runtime-run "$@" < "$bootstrapDirectory/runtime-input" > "$bootstrapDirectory/runtime-output" 3>&- 4<&- &
  backendProcess=$!
  exec 5> "$bootstrapDirectory/runtime-input"
  printf '%s\n' "$initializationFrame" >&5
  backendState=initializing
  backendDeadline=$(( $(date +%s) + 10 ))
  backendError=''
  writeDiagnostic mcp_runtime_started started
}

sendMcpRuntimeFrame() {
  if printf '%s\n' "$1" >&5 2>/dev/null; then return 0; fi
  failMcpRuntime runtime_process_closed
}

completeMcpWaits() {
  now=$(date +%s)
  for pendingPath in "$bootstrapDirectory"/pending-*; do
    [ -f "$pendingPath" ] || continue
    { IFS= read -r pendingDeadline; IFS= read -r pendingId; IFS= read -r pendingToken
      IFS= read -r pendingVersion; IFS= read -r pendingStarted; IFS= read -r pendingProgress
      IFS= read -r pendingKey
    } < "$pendingPath"
    printStatus >/dev/null
    state=$runtimeState; isError=false
    if [ "$backendState" = ready ]; then state=ready
    elif [ -n "$backendError" ]; then state=failed; isError=true; nextAction=request_runtime_retry
    elif [ "$runtimeState" = failed ]; then isError=true
    elif [ "$runtimeState" = not_prepared ]; then :
    elif [ "$now" -lt "$pendingDeadline" ]; then
      elapsed=$((now - pendingStarted))
      if [ -n "$pendingToken" ] && [ "$elapsed" -gt "$pendingProgress" ]; then
        printf '{"jsonrpc":"2.0","method":"notifications/progress","params":{"progressToken":%s,"progress":%s,"total":30,"message":"Preparing the Hipohipo runtime"}}\n' "$pendingToken" "$((now - pendingStarted))"
        operationFrame=$(sed -n '8p' "$pendingPath")
        printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' "$pendingDeadline" "$pendingId" "$pendingToken" "$pendingVersion" "$pendingStarted" "$elapsed" "$pendingKey" "$operationFrame" > "$pendingPath"
      fi
      continue
    fi
    operationFrame=$(sed -n '8p' "$pendingPath")
    if [ "$backendState" = ready ] && [ -n "$operationFrame" ]; then
      forwardedNumber=$((forwardedNumber + 1))
      printf '%s\n%s\n' "$pendingId" "$pendingKey" > "$bootstrapDirectory/forwarded-$forwardedNumber"
      sendMcpRuntimeFrame "$operationFrame"
      rm -f "$pendingPath"
      continue
    fi
    # Runtime readiness alone does not imply the MCP backend initialized.
    if [ "$state" = ready ] && [ "$backendState" != ready ]; then state=preparing; fi
    case "$state" in ready) nextAction=none ;; failed) ;; *) nextAction=continue_setup ;; esac
    status=$(printStatus "$state" "$nextAction")
    status="${status%\}},\"operationExecuted\":false,\"waitTimeoutSeconds\":30,\"retryIntervalSeconds\":0,\"backendRetryAtUnixSeconds\":$backendRetryAt,\"backendErrorCode\":\"$backendError\"}"
    case "$state" in
      ready) text='Runtime is ready. Continue using the existing tools in this conversation.' ;;
      failed) text='Runtime preparation or startup failed. Inspect lastErrorCode and follow nextAction. The original operation was not executed.' ;;
      not_prepared) text='Runtime is not prepared. Use auth.login to start or continue setup through this app; status checks do not start preparation.' ;;
      *) text='Runtime preparation is pending, not complete. Continue the original setup call while this attempt is pending; status checks only observe it. Do not reconnect MCP.' ;;
    esac
    result=$(printf '{"content":[{"type":"text","text":"%s %s"}],"structuredContent":%s,"isError":%s}' "$text" "$(escapeJson "$status")" "$status" "$isError")
    writeMcpResult "$pendingId" "$result" "$pendingVersion"
    rm -f "$pendingPath"
  done
}

serveMcpBootstrap() {
  command -v awk >/dev/null 2>&1 || reportFailure dependency_missing 'The system AWK interpreter is unavailable'
  mkdir -p "$configDirectory"
  bootstrapDirectory=$(mktemp -d "$configDirectory/.mcp.XXXXXX")
  backendProcess=''; backendReader=''; backendState=stopped; backendError=''
  initializationFrame=''; initializationMethod=''; negotiatedVersion=''; hasInitialized=false; pendingNumber=0
  backendGeneration=0; backendRetryAt=0; forwardedNumber=0
  descriptor=$(tr -d '\n' < "$scriptDirectory/mcp-bootstrap.json")
  descriptorFields=$(printf '%s\n' "$descriptor" | LC_ALL=C HIPO_BOOTSTRAP_JSON_MODE=descriptor awk -f "$scriptDirectory/mcp-json.awk")
  { IFS= read -r bootstrapTools; IFS= read -r bootstrapCapabilities; IFS= read -r bootstrapInstructions; IFS= read -r bootstrapVersions; } <<FIELDS
$descriptorFields
FIELDS
  mkfifo "$bootstrapDirectory/events"
  exec 3<> "$bootstrapDirectory/events" 4<&0
  queueMcpFrames C E <&4 >&3 &
  inputReader=$!
  (while :; do sleep 1; printf 'T\n'; done) >&3 4<&- &
  bootstrapClock=$!
  trap closeMcpBootstrap 0
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap '' PIPE
  writeDiagnostic mcp_bootstrap_started success
  while IFS= read -r eventFrame <&3; do
    eventType=${eventFrame%"${eventFrame#?}"}
    framePath=${eventFrame#?}
    case "$eventType" in
      E) return 0 ;;
      B)
        if [ "$framePath" = "$backendGeneration" ] && [ "$backendState" != stopped ]; then
          failMcpRuntime runtime_process_closed
        fi
        continue ;;
      T)
        if [ "$backendState" = initializing ] && [ "$(date +%s)" -ge "$backendDeadline" ]; then
          failMcpRuntime runtime_initialize_timeout
        fi
        if [ -z "$backendError" ] && [ "$backendState" = stopped ]; then
          startMcpRuntime "$@"
        fi
        completeMcpWaits
        continue ;;
      C|R) ;;
      *) continue ;;
    esac
    if [ "$eventType" = R ]; then
      case "$framePath" in "$bootstrapDirectory/R-$backendGeneration-"*) ;; *) rm -f "$framePath"; continue ;; esac
    fi
    readMcpFields "$framePath"
    frame=$(cat "$framePath")
    rm -f "$framePath"
    if [ "$frameValidity" != valid ]; then
      if [ "$eventType" = R ]; then failMcpRuntime runtime_invalid_response
      elif [ "$frameValidity" = invalid-json ]; then writeMcpError null -32700 'Invalid JSON'
      else writeMcpError null -32600 'Invalid JSON-RPC frame'; fi
      continue
    fi
    if [ "$eventType" = R ]; then
      if [ "$backendState" = initializing ] && [ "$requestId" = '"hipohipo.bootstrap.initialize"' ] && [ -z "$methodName" ]; then
        if [ "$responseOutcome" = error ]; then
          failMcpRuntime runtime_initialize_failed
        elif [ "$canChangeTools" != true ] || [ "$canSubscribe" != true ] || [ "$canChangeResources" != false ] || { [ "$initializationMethod" = initialize ] && [ "$responseVersion" != "$negotiatedVersion" ]; }; then
          failMcpRuntime runtime_protocol_mismatch
        else
          backendState=ready
          [ "$hasInitialized" != true ] || sendMcpRuntimeFrame '{"jsonrpc":"2.0","method":"notifications/initialized"}'
          printf '{"jsonrpc":"2.0","method":"notifications/tools/list_changed"}\n'
          writeDiagnostic mcp_runtime_ready success
        fi
        completeMcpWaits
      else
        if [ -z "$methodName" ]; then
          for forwardedPath in "$bootstrapDirectory"/forwarded-*; do
            [ -f "$forwardedPath" ] || continue
            [ "$(sed -n '2p' "$forwardedPath")" != "$requestKey" ] || rm -f "$forwardedPath"
          done
        fi
        printf '%s\n' "$frame"
      fi
      continue
    fi
    if [ -n "$modernVersion" ] && [ "$modernVersion" != 2026-07-28 ]; then writeMcpError "$requestId" -32022 'Unsupported protocol version'; continue; fi
    # Modern requests carry their own version and need no legacy handshake.
    if [ "$modernVersion" = 2026-07-28 ] && [ -z "$initializationFrame" ]; then
      initializationMethod=server/discover
      initializationFrame='{"jsonrpc":"2.0","id":"hipohipo.bootstrap.initialize","method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}'
    fi
    case "$methodName" in
      server/discover)
        if [ -z "$initializationFrame" ]; then
          initializationMethod=server/discover
          initializationFrame=$(printf '{"jsonrpc":"2.0","id":"hipohipo.bootstrap.initialize","method":"server/discover","params":%s}' "$rawParameters")
        fi
        result=$(printf '{"supportedVersions":%s,"capabilities":%s,"instructions":%s}' "$bootstrapVersions" "$bootstrapCapabilities" "$bootstrapInstructions")
        writeMcpResult "$requestId" "$result" 2026-07-28
        startMcpRuntime "$@"
        continue ;;
      initialize)
        if [ -n "$initializationFrame" ]; then writeMcpError "$requestId" -32600 'MCP is already initialized'; continue; fi
        case "$protocolVersion" in 2025-11-25|2025-06-18|2025-03-26|2024-11-05|2024-10-07) ;; *) protocolVersion=2025-11-25 ;; esac
        initializationMethod=initialize; negotiatedVersion=$protocolVersion
        initializationFrame=$(printf '{"jsonrpc":"2.0","id":"hipohipo.bootstrap.initialize","method":"initialize","params":%s}' "$rawParameters")
        result=$(printf '{"protocolVersion":"%s","capabilities":%s,"serverInfo":{"name":"hipohipo-plugin","version":"%s"},"instructions":%s}' "$protocolVersion" "$bootstrapCapabilities" "$runtimeVersion" "$bootstrapInstructions")
        writeMcpResult "$requestId" "$result"
        startMcpRuntime "$@"
        continue ;;
      notifications/initialized)
        hasInitialized=true
        [ "$backendState" != ready ] || sendMcpRuntimeFrame "$frame"
        continue ;;
      notifications/cancelled)
        for pendingPath in "$bootstrapDirectory"/pending-*; do
          [ -f "$pendingPath" ] || continue
          [ "$(sed -n '7p' "$pendingPath")" != "$cancelledKey" ] || rm -f "$pendingPath"
        done
        for forwardedPath in "$bootstrapDirectory"/forwarded-*; do
          [ -f "$forwardedPath" ] || continue
          [ "$(sed -n '2p' "$forwardedPath")" != "$cancelledKey" ] || rm -f "$forwardedPath"
        done
        [ "$backendState" != ready ] || sendMcpRuntimeFrame "$frame"
        continue ;;
      ping) writeMcpResult "$requestId" '{}' "$modernVersion"; continue ;;
      tools/list)
        if [ "$backendState" != ready ]; then writeMcpResult "$requestId" "{\"tools\":$bootstrapTools}" "$modernVersion"; continue; fi ;;
      tools/call)
        isBackgroundInvocation=false
        case "$toolName" in
          source.create_background|source_create_background) isBackgroundInvocation=true ;;
          library.list|library_list|source.get_status|source_get_status)
            [ "$isBackground" != true ] || isBackgroundInvocation=true ;;
        esac
        if [ "$isBackgroundInvocation" = true ]; then
          if [ "$backendState" != ready ]; then
            writeMcpResult "$requestId" '{"content":[{"type":"text","text":"Skip background saving and continue the original task."}],"structuredContent":{"status":"background_upload_unavailable","operationExecuted":false},"isError":true}' "$modernVersion"
            continue
          fi
          forwardedNumber=$((forwardedNumber + 1))
          printf '%s\n%s\n' "$requestId" "$requestKey" > "$bootstrapDirectory/forwarded-$forwardedNumber"
          sendMcpRuntimeFrame "$frame"
          continue
        fi
        canonicalTool=''
        for candidateTool in $(printf '%s\n' "$bootstrapTools" | grep -o '"name"[[:space:]]*:[[:space:]]*"[A-Za-z0-9_.-]*"' | sed 's/.*:[[:space:]]*"//;s/"$//'); do
          if [ "$toolName" = "$candidateTool" ] || [ "$toolName" = "$(printf '%s' "$candidateTool" | tr . _)" ]; then canonicalTool=$candidateTool; break; fi
        done
        if [ -z "$canonicalTool" ]; then writeMcpError "$requestId" -32601 'Tool is not included in this plugin version catalog'; continue; fi
        toolName=$canonicalTool
        if [ "$toolName" = auth.status ] || [ "$toolName" = auth_status ]; then
          if [ "$backendState" != ready ]; then
            printStatus >/dev/null
            observedRuntime=$(printStatus)
            writeMcpResult "$requestId" "{\"content\":[{\"type\":\"text\",\"text\":\"Runtime is not prepared; authorization was not checked.\"}],\"structuredContent\":{\"status\":\"runtime_not_prepared\",\"nextAction\":\"$nextAction\",\"operationExecuted\":false,\"runtime\":$observedRuntime},\"isError\":false}" "$modernVersion"
            continue
          fi
        fi
        operationFrame=''
        case "$toolName" in
          runtime_prepare|runtime_status)
            pendingCount=0; hasDuplicate=false
            for pendingPath in "$bootstrapDirectory"/pending-*; do
              [ -f "$pendingPath" ] || continue
              pendingCount=$((pendingCount + 1))
              [ "$(sed -n '7p' "$pendingPath")" != "$requestKey" ] || hasDuplicate=true
            done
            if [ "$requestId" = null ] || [ "$hasDuplicate" = true ] || [ "$pendingCount" -ge 16 ]; then
              writeMcpError "$requestId" -32600 'Invalid or duplicate preparation request'
              continue
            fi
            if [ "$argumentsValidity" != valid ]; then writeMcpError "$requestId" -32602 'Preparation tools accept an empty arguments object'; continue; fi
            if [ "$toolName" = runtime_prepare ]; then
              backendError=''
              requestPreparation explicit || :
              startMcpRuntime "$@"
            fi
            pendingNumber=$((pendingNumber + 1))
            now=$(date +%s)
            printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n' "$((now + 30))" "$requestId" "$progressToken" "$modernVersion" "$now" -1 "$requestKey" > "$bootstrapDirectory/pending-$pendingNumber"
            if [ "$toolName" = runtime_status ]; then
              sed '1s/.*/0/' "$bootstrapDirectory/pending-$pendingNumber" > "$bootstrapDirectory/status-$pendingNumber"
              mv "$bootstrapDirectory/status-$pendingNumber" "$bootstrapDirectory/pending-$pendingNumber"
            fi
            completeMcpWaits
            continue ;;
        esac
        if [ "$backendState" != ready ]; then
          [ "$requestId" != null ] || continue
          hasDuplicate=false
          for existingPending in "$bootstrapDirectory"/pending-*; do
            [ -f "$existingPending" ] || continue
            [ "$(sed -n '7p' "$existingPending")" != "$requestKey" ] || hasDuplicate=true
          done
          if [ "$hasDuplicate" = true ]; then writeMcpError "$requestId" -32600 'Duplicate pending request'; continue; fi
          pendingCount=$(find "$bootstrapDirectory" -name 'pending-*' -type f | wc -l)
          if [ "$pendingCount" -ge 16 ]; then writeMcpError "$requestId" -32000 'Preparation request capacity exceeded'; continue; fi
          requestPreparation || :
          startMcpRuntime "$@"
          pendingNumber=$((pendingNumber + 1))
          now=$(date +%s)
          printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' "$((now + 30))" "$requestId" "$progressToken" "$modernVersion" "$now" -1 "$requestKey" "$frame" > "$bootstrapDirectory/pending-$pendingNumber"
          completeMcpWaits
          continue
        fi ;;

    esac
    if [ "$backendState" = ready ]; then
      if [ -n "$methodName" ] && [ "$requestId" != null ]; then
        forwardedNumber=$((forwardedNumber + 1))
        printf '%s\n%s\n' "$requestId" "$requestKey" > "$bootstrapDirectory/forwarded-$forwardedNumber"
      fi
      sendMcpRuntimeFrame "$frame"
      continue
    fi
    [ "$requestId" != null ] || continue
    case "$methodName" in
      tools/list) writeMcpResult "$requestId" "{\"tools\":$bootstrapTools}" "$modernVersion" ;;
      resources/list) writeMcpResult "$requestId" '{"resources":[]}' "$modernVersion" ;;
      resources/templates/list) writeMcpResult "$requestId" '{"resourceTemplates":[]}' "$modernVersion" ;;
      *) writeMcpError "$requestId" -32601 'Runtime is not ready; call runtime_prepare or runtime_status' ;;
    esac
  done
}
