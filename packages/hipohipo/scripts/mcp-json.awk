# Validate one JSON-RPC frame and extract only transport routing fields.
# Raw JSON values preserve string/number IDs and progress tokens exactly.
function failJson() { hasError = 1 }
function sourceByte(offset) {
  if (!isShareHookMode) return substr(source, offset, 1)
  if (offset > sourceLength) return ""
  # Some AWK implementations rescan the entire string for each substr call.
  if (offset < byteOffset || offset >= byteOffset + byteCount) {
    byteOffset = offset
    byteChunk = substr(source, offset, 65536)
    byteCount = split(byteChunk, sourceBytes, "")
  }
  return sourceBytes[offset - byteOffset + 1]
}
function sourceWindow(start, count) {
  if (start > sourceLength) return ""
  sourceByte(start)
  return substr(byteChunk, start - byteOffset + 1, count)
}
function sourceText(start, count,    value, end) {
  if (!isShareHookMode || count > 16) return substr(source, start, count)
  end = start + count
  for (; start < end; start++) value = value sourceByte(start)
  return value
}
function skipWhitespace() { while (sourceByte(position) ~ /^[ \t\r\n]$/) position++ }
function decodeHex(value,    characterIndex, digit, result) {
  result = 0
  for (characterIndex = 1; characterIndex <= length(value); characterIndex++) {
    digit = index("0123456789abcdef", tolower(substr(value, characterIndex, 1))) - 1
    result = result * 16 + digit
  }
  return result
}
function encodeCodePoint(value) {
  if (value < 128) return sprintf("%c", value)
  if (value < 2048) return sprintf("%c%c", 192 + int(value / 64), 128 + value % 64)
  if (value < 65536) return sprintf("%c%c%c", 224 + int(value / 4096), 128 + int(value / 64) % 64, 128 + value % 64)
  return sprintf("%c%c%c%c", 240 + int(value / 262144), 128 + int(value / 4096) % 64, 128 + int(value / 64) % 64, 128 + value % 64)
}
function readString(keep,    start, character, escape, value, decoded, lower, chunk, boundary, pieces, pieceCount, i, j) {
  start = position++
  decoded = ""
  while (position <= sourceLength) {
    character = sourceByte(position++)
    if (character == "\"") {
      if (pieceCount) {
        pieces[++pieceCount] = decoded
        # Join pieces in pairs so long escaped strings stay cheap to decode.
        while (pieceCount > 1) {
          j = 0
          for (i = 1; i <= pieceCount; i += 2) pieces[++j] = pieces[i] (i < pieceCount ? pieces[i + 1] : "")
          pieceCount = j
        }
        decoded = pieces[1]
      }
      stringValue = decoded
      return isShareHookMode ? "\"\"" : substr(source, start, position - start)
    }
    if (isShareHookMode && keep && length(decoded) >= 4096) {
      pieces[++pieceCount] = decoded
      decoded = ""
    }
    if (character ~ /[[:cntrl:]]/) { failJson(); return "" }
    if (character != "\\") {
      if (isShareHookMode && sourceByte(position) !~ /["\\[:cntrl:]]/) {
        # Scan in chunks, and validate unknown strings without decoding them.
        chunk = sourceWindow(position, 256)
        boundary = match(chunk, /["\\[:cntrl:]]/)
        if (!boundary && length(chunk) == 256) {
          chunk = sourceWindow(position, 65536)
          boundary = match(chunk, /["\\[:cntrl:]]/)
        }
        if (keep) decoded = decoded character substr(chunk, 1, boundary ? boundary - 1 : length(chunk))
        position += (boundary ? boundary - 1 : length(chunk))
      } else if (keep) decoded = decoded character
      continue
    }
    escape = sourceByte(position++)
    if (escape == "u") {
      value = sourceText(position, 4)
      if (length(value) != 4 || value ~ /[^0-9a-fA-F]/) { failJson(); return "" }
      position += 4
      value = decodeHex(value)
      if (value >= 55296 && value <= 56319) {
        if (sourceText(position, 2) != "\\u") { failJson(); return "" }
        lower = sourceText(position + 2, 4)
        if (length(lower) != 4 || lower ~ /[^0-9a-fA-F]/) { failJson(); return "" }
        lower = decodeHex(lower)
        if (lower < 56320 || lower > 57343) { failJson(); return "" }
        value = 65536 + (value - 55296) * 1024 + lower - 56320
        position += 6
      } else if (value >= 56320 && value <= 57343) { failJson(); return "" }
      if (keep) decoded = decoded encodeCodePoint(value)
    } else if (escape == "\"" || escape == "\\" || escape == "/") { if (keep) decoded = decoded escape }
    else if (escape == "b") { if (keep) decoded = decoded "\b" }
    else if (escape == "f") { if (keep) decoded = decoded "\f" }
    else if (escape == "n") { if (keep) decoded = decoded "\n" }
    else if (escape == "r") { if (keep) decoded = decoded "\r" }
    else if (escape == "t") { if (keep) decoded = decoded "\t" }
    else { failJson(); return "" }
  }
  failJson()
  return ""
}
function createIdentifierKey(path,    characterIndex, result, value) {
  value = values[path]
  if (substr(value, 1, 1) != "\"") return "number:" (value == "-0" ? "0" : value)
  value = strings[path]
  result = "string:"
  for (characterIndex = 1; characterIndex <= length(value); characterIndex++) result = result sprintf("%02x", byteValues[substr(value, characterIndex, 1)])
  return result
}
BEGIN {
  for (byteIndex = 0; byteIndex < 256; byteIndex++) byteValues[sprintf("%c", byteIndex)] = byteIndex
  isShareHookMode = ENVIRON["HIPO_BOOTSTRAP_JSON_MODE"] == "share-hook"
  if (isShareHookMode) {
    # An unescaped record separator is invalid JSON. Native hook frames can
    # contain line breaks, unlike the JSON-RPC transport.
    RS = sprintf("%c", 30)
    shareWhitespace = "[[:space:]]"
    # Match the non-ASCII Unicode whitespace used by Go's strings.Fields.
    spaceCount = split("133 160 5760 8192 8193 8194 8195 8196 8197 8198 8199 8200 8201 8202 8232 8233 8239 8287 12288", spaceCodePoints, " ")
    for (spaceIndex = 1; spaceIndex <= spaceCount; spaceIndex++) shareWhitespace = shareWhitespace "|" encodeCodePoint(spaceCodePoints[spaceIndex])
    shareWhitespace = "(" shareWhitespace ")+"
    shareStringFields[createPath("", "prompt")] = 1
    shareStringFields[createPath("", "hook_event_name")] = 1
    shareStringFields[createPath("", "cursor_version")] = 1
  }
}
function createPath(path, key) { return path length(key) ":" key }
function readValue(path, depth,    start, character, key, nextPath, raw, value) {
  if (depth > 64) { failJson(); return "" }
  skipWhitespace()
  start = position
  character = sourceByte(position)
  if (character == "\"") raw = readString(!isShareHookMode || (path in shareStringFields))
  else if (character == "{" || character == "[") {
    position++
    skipWhitespace()
    if (sourceByte(position) == (character == "{" ? "}" : "]")) position++
    else while (!hasError) {
      nextPath = path "[]"
      if (character == "{") {
        if (sourceByte(position) != "\"") { failJson(); break }
        readString(1)
        key = stringValue
        nextPath = createPath(path, key)
        if (seen[start SUBSEP key]++) { failJson(); break }
        skipWhitespace()
        if (sourceByte(position++) != ":") { failJson(); break }
      }
      readValue(nextPath, depth + 1)
      skipWhitespace()
      value = sourceByte(position++)
      if (value == (character == "{" ? "}" : "]")) break
      if (value != ",") { failJson(); break }
      skipWhitespace()
    }
    raw = isShareHookMode ? (character == "{" ? "{}" : "[]") : substr(source, start, position - start)
  } else {
    while (position <= sourceLength && sourceByte(position) !~ /[ \t\r\n,}\]]/) position++
    raw = sourceText(start, position - start)
    if (raw != "true" && raw != "false" && raw != "null" && raw !~ /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) failJson()
  }
  values[path] = raw
  if (character == "\"") strings[path] = stringValue
  return raw
}

function trimShareWhitespace(text) {
  sub("^" shareWhitespace, "", text)
  sub(shareWhitespace "$", "", text)
  return text
}
function isShareCommand(text, command,    fields, parts, count, i) {
  count = split(trimShareWhitespace(text), fields, shareWhitespace)
  if (fields[1] != command) return 0
  if (count == 1) return 1
  if (count != 3 || fields[2] != "retry" || length(fields[3]) != 36 || split(fields[3], parts, "-") != 5) return 0
  if (length(parts[1]) != 8 || length(parts[2]) != 4 || length(parts[3]) != 4 || length(parts[4]) != 4 || length(parts[5]) != 12 || substr(parts[3], 1, 1) != "4") return 0
  for (i = 1; i <= 5; i++) if (parts[i] !~ /^[0-9a-f]+$/) return 0
  return 1
}
function isCodexShareSkill(text, command, path,    link, wrappedLink) {
  link = "[" command "](" path ")"
  wrappedLink = "[" command "](<" path ">)"
  if (index(text, link) == 1) return isShareCommand(command " " substr(text, length(link) + 1), command)
  if (index(text, wrappedLink) == 1) return isShareCommand(command " " substr(text, length(wrappedLink) + 1), command)
  return 0
}
function isDirectShareHook(host, event, root,    text, kind, kindPath, excluded, cli, version, fields) {
  text = trimShareWhitespace(strings[createPath("", "prompt")])
  kindPath = createPath("", "hook_event_name")
  if (values[kindPath] != "" && values[kindPath] != "null" && substr(values[kindPath], 1, 1) != "\"") return 0
  kind = strings[kindPath]
  if (kind != "" && kind != event) return 0
  excluded = values[createPath("", (host == "cursor" || host == "cursor-plugin") ? "is_background_agent" : "is_internal_continuation")]
  if (excluded != "" && excluded != "false" && excluded != "null") return 0
  if (host == "codex") {
    return isShareCommand(text, "$hipohipo:hipo-share") ||
      isShareCommand(text, "$hipohipo:source-command-hipo-share") ||
      isCodexShareSkill(text, "$hipohipo:hipo-share", root "/codex/skills/hipo-share/SKILL.md") ||
      isCodexShareSkill(text, "$hipohipo:source-command-hipo-share", root "/.codex-plugin/migrated-command-skills/source-command-hipo-share/SKILL.md")
  }
  if (host == "claude-code" && isShareCommand(text, "/hipohipo:share")) return 1
  if (host == "cursor" || host == "cursor-plugin") {
    cli = ENVIRON["CURSOR_CLI"]
    version = strings[createPath("", "cursor_version")]
    split(version, fields, ".")
    if ((cli != "" && cli != "${env:CURSOR_CLI}") || (length(fields[1]) == 4 && index(fields[1], "20") == 1 && index(version, "-") != 0)) return 0
  }
  return isShareCommand(text, "/hipo-share")
}
{
  if (isShareHookMode && NR == 2 && $0 == "end-share-hook") next
  source = $0
  if (isShareHookMode) {
    if (NR != 1 || length(source) > 32000000) { failJson(); exit }
    if (substr(source, 1, 3) == sprintf("%c%c%c", 239, 187, 191)) source = substr(source, 4)
  }
  sourceLength = length(source)
  position = 1
  readValue("", 0)
  skipWhitespace()
  if (position <= sourceLength || substr(values[""], 1, 1) != "{") failJson()
}
END {
  if (isShareHookMode) {
    if (!hasError && NR == 2 &&
        isDirectShareHook(ENVIRON["HIPO_BOOTSTRAP_HOOK_HOST"], ENVIRON["HIPO_BOOTSTRAP_HOOK_EVENT"], ENVIRON["HIPO_BOOTSTRAP_PLUGIN_ROOT"])) print "share"
    exit
  }
  if (hasError || NR != 1) { print "invalid-json"; exit }
  if (ENVIRON["HIPO_BOOTSTRAP_JSON_MODE"] == "preparation") {
    fieldsCount = split("attemptId startedAtUnixSeconds deadlineAtUnixSeconds state phase networkFailures downloadedBytes lastErrorCode downloadOrigin originFallbacks artifactIdentity artifactAttemptId", fields, " ")
    originPath = createPath("", "downloadOrigin")
    fallbackPath = createPath("", "originFallbacks")
    if (!(originPath in values)) { values[originPath] = "\"primary\""; strings[originPath] = "primary" }
    if (!(fallbackPath in values)) values[fallbackPath] = "0"
    identityPath = createPath("", "artifactIdentity")
    artifactAttemptPath = createPath("", "artifactAttemptId")
    if (!(identityPath in values)) { values[identityPath] = "\"\""; strings[identityPath] = "" }
    if (!(artifactAttemptPath in values)) { values[artifactAttemptPath] = "\"\""; strings[artifactAttemptPath] = "" }
    if (substr(values[identityPath], 1, 1) != "\"" || strings[identityPath] ~ /[^A-Za-z0-9._\/-]/ || substr(values[artifactAttemptPath], 1, 1) != "\"" || (strings[artifactAttemptPath] != "" && strings[artifactAttemptPath] !~ /^[A-Za-z0-9][A-Za-z0-9_-]*$/)) { print "invalid-state"; exit }
    if (strings[originPath] !~ /^(primary|mirror)$/ || values[fallbackPath] !~ /^[01]$/) { print "invalid-state"; exit }
    if (strings["9:attemptId"] !~ /^[A-Za-z0-9_-]+$/ || strings["5:state"] !~ /^(preparing|failed|ready)$/ || strings["5:phase"] !~ /^(download|verify|publish|ready)$/ || strings["13:lastErrorCode"] ~ /[^a-z0-9_]/) { print "invalid-state"; exit }
    for (fieldIndex = 1; fieldIndex <= fieldsCount; fieldIndex++) {
      fieldPath = createPath("", fields[fieldIndex])
      if (fieldIndex == 2 || fieldIndex == 3 || fieldIndex == 6 || fieldIndex == 7) {
        if (values[fieldPath] !~ /^(0|[1-9][0-9]*)$/) { print "invalid-state"; exit }
      }
    }
    for (fieldIndex = 1; fieldIndex <= fieldsCount; fieldIndex++) {
      fieldPath = createPath("", fields[fieldIndex])
      print (substr(values[fieldPath], 1, 1) == "\"" ? strings[fieldPath] : values[fieldPath])
    }
    exit
  }
  if (ENVIRON["HIPO_BOOTSTRAP_JSON_MODE"] == "version") {
    if (strings["4:name"] != "hipohipo" || strings["7:version"] !~ /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/) { print "invalid-package"; exit }
    print strings["7:version"]
    exit
  }
  if (ENVIRON["HIPO_BOOTSTRAP_JSON_MODE"] == "installation") {
    if (values[createPath("", "schemaVersion")] != "1" || strings[createPath("", "channel")] != "archive" || strings[createPath("", "host")] != "cursor" || strings[createPath("", "installationRoot")] ~ /[[:cntrl:]]/) { print "invalid-installation"; exit }
    print strings[createPath("", "installationRoot")]
    exit
  }
  if (ENVIRON["HIPO_BOOTSTRAP_JSON_MODE"] == "package") {
    if (strings["4:name"] != "hipohipo" || strings["7:version"] !~ /^[0-9]+\.[0-9]+\.[0-9]+$/ || (strings["5:hooks"] != "" && strings["5:hooks"] != "./hooks/hooks.json" && strings["5:hooks"] != "./hooks/cursor.json" && strings["5:hooks"] !~ /^\.\/\.hipohipo-releases\/[0-9]+\.[0-9]+\.[0-9]+\/hooks\/(cursor|hooks)\.json$/)) { print "invalid-package"; exit }
    print strings["4:name"]
    print strings["7:version"]
    print (strings["5:hooks"] == "./hooks/cursor.json" ? "cursor.json" : "hooks.json")
    exit
  }
  if (ENVIRON["HIPO_BOOTSTRAP_JSON_MODE"] == "descriptor") {
    print values["5:tools"]
    print values["12:capabilities"]
    print values["12:instructions"]
    print values["16:protocolVersions"]
    exit
  }
  if (strings["7:jsonrpc"] != "2.0") { print "invalid-frame"; exit }
  id = values["2:id"]
  if (id != "" && id != "null" && id !~ /^"/ && id !~ /^-?(0|[1-9][0-9]*)$/) { print "invalid-frame"; exit }
  method = values["6:method"]
  parameters = values["6:params"]
  metadata = values["6:params5:_meta"]
  token = values["6:params5:_meta13:progressToken"]
  if ((method != "" && method !~ /^"/) || (parameters != "" && parameters !~ /^\{/) || (metadata != "" && metadata !~ /^\{/) || (token != "" && token !~ /^"/ && token !~ /^-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$/)) { print "invalid-frame"; exit }
  if (method == "" && values["6:result"] == "" && values["5:error"] == "") { print "invalid-frame"; exit }
  if (strings["6:method"] ~ /[[:cntrl:]]/ || strings["6:params4:name"] ~ /[[:cntrl:]]/ || strings["6:params15:protocolVersion"] ~ /[[:cntrl:]]/ || strings[createPath("6:params5:_meta", "io.modelcontextprotocol/protocolVersion")] ~ /[[:cntrl:]]/) { print "invalid-frame"; exit }
  print "valid"
  print (id == "" ? "null" : id)
  print strings["6:method"]
  print strings["6:params4:name"]
  print strings["6:params15:protocolVersion"]
  print values["6:params5:_meta13:progressToken"]
  print values["6:params9:requestId"]
  print strings[createPath("6:params5:_meta", "io.modelcontextprotocol/protocolVersion")]
  print (values["5:error"] == "" ? "success" : "error")
  print (parameters == "" ? "{}" : parameters)
  print strings["6:result15:protocolVersion"]
  print values["6:result12:capabilities5:tools11:listChanged"]
  print values["6:result12:capabilities9:resources9:subscribe"]
  print values["6:result12:capabilities9:resources11:listChanged"]
  arguments = values["6:params9:arguments"]
  gsub(/[ \t\r\n]/, "", arguments)
  print (arguments == "" || arguments == "{}" ? "valid" : "invalid")
  print createIdentifierKey("2:id")
  print createIdentifierKey("6:params9:requestId")
  print (values[createPath("6:params9:arguments", "isBackground")] == "true" ? "true" : "false")
}
