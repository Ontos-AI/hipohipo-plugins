# Validate one JSON-RPC frame and extract only transport routing fields.
# Raw JSON values preserve string/number IDs and progress tokens exactly.
function failJson() { hasError = 1 }
function skipWhitespace() { while (substr(source, position, 1) ~ /^[ \t\r\n]$/) position++ }
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
function readString(    start, character, escape, value, decoded, lower) {
  start = position++
  decoded = ""
  while (position <= length(source)) {
    character = substr(source, position++, 1)
    if (character == "\"") { stringValue = decoded; return substr(source, start, position - start) }
    if (character ~ /[[:cntrl:]]/) { failJson(); return "" }
    if (character != "\\") { decoded = decoded character; continue }
    escape = substr(source, position++, 1)
    if (escape == "u") {
      value = substr(source, position, 4)
      if (length(value) != 4 || value ~ /[^0-9a-fA-F]/) { failJson(); return "" }
      position += 4
      value = decodeHex(value)
      if (value >= 55296 && value <= 56319) {
        if (substr(source, position, 2) != "\\u") { failJson(); return "" }
        lower = substr(source, position + 2, 4)
        if (length(lower) != 4 || lower ~ /[^0-9a-fA-F]/) { failJson(); return "" }
        lower = decodeHex(lower)
        if (lower < 56320 || lower > 57343) { failJson(); return "" }
        value = 65536 + (value - 55296) * 1024 + lower - 56320
        position += 6
      } else if (value >= 56320 && value <= 57343) { failJson(); return "" }
      decoded = decoded encodeCodePoint(value)
    } else if (escape == "\"" || escape == "\\" || escape == "/") decoded = decoded escape
    else if (escape == "b") decoded = decoded "\b"
    else if (escape == "f") decoded = decoded "\f"
    else if (escape == "n") decoded = decoded "\n"
    else if (escape == "r") decoded = decoded "\r"
    else if (escape == "t") decoded = decoded "\t"
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
BEGIN { for (byteIndex = 0; byteIndex < 256; byteIndex++) byteValues[sprintf("%c", byteIndex)] = byteIndex }
function createPath(path, key) { return path length(key) ":" key }
function readValue(path, depth,    start, character, key, nextPath, raw, value) {
  if (depth > 64) { failJson(); return "" }
  skipWhitespace()
  start = position
  character = substr(source, position, 1)
  if (character == "\"") raw = readString()
  else if (character == "{" || character == "[") {
    position++
    skipWhitespace()
    if (substr(source, position, 1) == (character == "{" ? "}" : "]")) position++
    else while (!hasError) {
      nextPath = path "[]"
      if (character == "{") {
        if (substr(source, position, 1) != "\"") { failJson(); break }
        readString()
        key = stringValue
        nextPath = createPath(path, key)
        if (seen[start SUBSEP key]++) { failJson(); break }
        skipWhitespace()
        if (substr(source, position++, 1) != ":") { failJson(); break }
      }
      readValue(nextPath, depth + 1)
      skipWhitespace()
      value = substr(source, position++, 1)
      if (value == (character == "{" ? "}" : "]")) break
      if (value != ",") { failJson(); break }
      skipWhitespace()
    }
    raw = substr(source, start, position - start)
  } else {
    while (position <= length(source) && substr(source, position, 1) !~ /[ \t\r\n,}\]]/) position++
    raw = substr(source, start, position - start)
    if (raw != "true" && raw != "false" && raw != "null" && raw !~ /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) failJson()
  }
  values[path] = raw
  if (character == "\"") strings[path] = stringValue
  return raw
}
{
  source = $0
  position = 1
  readValue("", 0)
  skipWhitespace()
  if (position <= length(source) || substr(values[""], 1, 1) != "{") failJson()
}
END {
  if (hasError || NR != 1) { print "invalid-json"; exit }
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
}
