param([Parameter(ValueFromRemainingArguments = $true)][string[]] $RuntimeArguments)
# Bootstrap needs only built-in modules. Hosts may filter PSModulePath, making
# automatic command discovery scan unrelated installed modules before MCP starts.
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[DateTime] $invocationStarted = [DateTime]::UtcNow
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
if ($null -eq $RuntimeArguments) { $RuntimeArguments = @() }
[string] $pluginRoot = Split-Path $PSScriptRoot -Parent
[string] $manifestPath = $env:HIPO_RUNTIME_MANIFEST
if ([string]::IsNullOrWhiteSpace($manifestPath)) { $manifestPath = Join-Path $pluginRoot 'runtime-manifest.json' }
[string] $commandName = 'runtime-status'
if ($RuntimeArguments.Count -gt 0) { $commandName = $RuntimeArguments[0] }
[bool] $isHook = $commandName -in @('hook', 'host-hook')
[string] $eventName = ''
[string] $hostName = $env:HIPO_CAPTURE_HOST
for ([int] $index = 1; $index -lt $RuntimeArguments.Count - 1; $index++) {
    if ($RuntimeArguments[$index] -eq '--event') { $eventName = $RuntimeArguments[$index + 1] }
    if ($RuntimeArguments[$index] -eq '--host') { $hostName = $RuntimeArguments[$index + 1] }
}
if ($hostName -notin @('cursor', 'cursor-plugin', 'claude-code', 'codex')) { $hostName = '' }
if ($eventName -notin @('sessionStart', 'beforeSubmitPrompt', 'afterAgentResponse', 'stop', 'sessionEnd', 'SessionStart', 'UserPromptSubmit', 'Stop', 'PreCompact', 'SessionEnd', 'Interrupt', 'StopFailure')) { $eventName = '' }
[string] $logPath = ''
[string] $temporaryDirectory = ''
[bool] $hasPreparationLock = $false

function Write-HookResponse {
    if ($commandName -eq 'hook' -and $eventName -eq 'beforeSubmitPrompt') { [Console]::WriteLine('{"continue":true}') }
    else { [Console]::WriteLine('{}') }
}

function Get-UnixTime { return [long] ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) }

function Test-VerifiedFile([string] $path, [long] $size, [string] $digest) {
    if (-not [IO.File]::Exists($path)) { return $false }
    [IO.FileInfo] $info = New-Object IO.FileInfo $path
    if (($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $info.Length -ne $size) { return $false }
    [IO.FileStream] $stream = $null
    [Security.Cryptography.SHA256] $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::OpenRead($path)
        [string] $actual = [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '').ToLowerInvariant()
        return $actual -eq $digest
    }
    catch { return $false }
    finally { if ($null -ne $stream) { $stream.Dispose() }; $algorithm.Dispose() }
}

function Test-RuntimeReady { return Test-VerifiedFile $runtimePath $artifact.executableSize $artifact.executableSha256 }

function Protect-Directory([string] $path) {
    [void] [IO.Directory]::CreateDirectory($path)
    [Security.AccessControl.DirectorySecurity] $security = New-Object Security.AccessControl.DirectorySecurity
    $security.SetAccessRuleProtection($true, $false)
    [Security.Principal.SecurityIdentifier] $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
    [Security.AccessControl.FileSystemAccessRule] $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $security.AddAccessRule($rule)
    [IO.Directory]::SetAccessControl($path, $security)
}

function Write-Diagnostic([string] $event, [string] $outcome, [string] $code = '', [long] $byteCount = 0) {
    # Separate from Go's kernel-locked launcher log; never record URLs or payloads.
    [IO.FileStream] $guard = $null
    try {
        [void] [IO.Directory]::CreateDirectory((Split-Path $logPath -Parent))
        $guard = [IO.File]::Open($logPath + '.guard', 'OpenOrCreate', 'ReadWrite', 'None')
        if ([IO.File]::Exists($logPath) -and (Get-Item -LiteralPath $logPath).Length -ge 1048576) {
            for ([int] $number = 3; $number -ge 1; $number--) {
                [string] $previous = $logPath
                if ($number -gt 1) { $previous += '.' + ($number - 1) }
                if ([IO.File]::Exists($logPath + '.' + $number)) { [IO.File]::Delete($logPath + '.' + $number) }
                if ([IO.File]::Exists($previous)) { [IO.File]::Move($previous, $logPath + '.' + $number) }
            }
        }
        for ([int] $number = 1; $number -le 3; $number++) {
            [string] $rotated = $logPath + '.' + $number
            if ([IO.File]::Exists($rotated) -and [IO.File]::GetLastWriteTimeUtc($rotated) -lt [DateTime]::UtcNow.AddDays(-14)) { [IO.File]::Delete($rotated) }
        }
        [string] $record = @{timestamp = [DateTime]::UtcNow.ToString('o'); component = 'bootstrap'; event = $event; outcome = $outcome; errorCode = $code; runtimeVersion = $manifest.runtimeVersion; launcherVersion = $manifest.runtimeVersion; platform = 'windows-amd64'; host = $hostName; hook = $eventName; correlationId = [string] $PID; elapsedMilliseconds = [long] ([DateTime]::UtcNow - $invocationStarted).TotalMilliseconds; byteCount = $byteCount} | ConvertTo-Json -Compress
        [IO.File]::AppendAllText($logPath, $record + "`n", (New-Object Text.UTF8Encoding $false))
    }
    catch { }
    finally { if ($null -ne $guard) { $guard.Dispose() } }
}

function Write-Failure([string] $code) {
    [string] $pending = $failurePath + '.' + $PID
    [IO.File]::WriteAllText($pending, ((Get-UnixTime).ToString() + "`n" + $code + "`n"))
    Move-Item -LiteralPath $pending -Destination $failurePath -Force
    Write-Diagnostic 'preparation_completed' 'failed' $code
}

function Test-Cooldown {
    if (-not [IO.File]::Exists($failurePath)) { return $false }
    [string[]] $lines = [IO.File]::ReadAllLines($failurePath)
    [long] $failedAt = 0
    if ($lines.Count -eq 0 -or -not [long]::TryParse($lines[0], [ref] $failedAt)) { return $false }
    return (Get-UnixTime) - $failedAt -lt 180
}

function Get-PreparationLock {
    [void] [IO.Directory]::CreateDirectory((Split-Path $preparationLock -Parent))
    [void] [IO.Directory]::CreateDirectory((Split-Path $failurePath -Parent))
    try {
        [void] (New-Item -ItemType Directory -Path $preparationLock -ErrorAction Stop)
        [IO.File]::WriteAllText((Join-Path $preparationLock 'created'), (Get-UnixTime).ToString())
        [IO.File]::WriteAllText((Join-Path $preparationLock 'owner'), '0')
        return $true
    }
    catch {
        if (-not [IO.Directory]::Exists($preparationLock)) { throw }
        [int] $owner = 0
        [long] $created = ([DateTimeOffset] [IO.Directory]::GetLastWriteTimeUtc($preparationLock)).ToUnixTimeSeconds()
        if ([IO.File]::Exists((Join-Path $preparationLock 'owner'))) { [void] [int]::TryParse([IO.File]::ReadAllText((Join-Path $preparationLock 'owner')), [ref] $owner) }
        if ([IO.File]::Exists((Join-Path $preparationLock 'created'))) { [void] [long]::TryParse([IO.File]::ReadAllText((Join-Path $preparationLock 'created')), [ref] $created) }
        if ($owner -gt 0 -and $null -ne (Get-Process -Id $owner -ErrorAction SilentlyContinue)) { return $false }
        if ($owner -eq 0 -and (Get-UnixTime) - $created -le 5) { return $false }
        [IO.FileStream] $recovery = $null
        [string] $stalePath = $preparationLock + '.stale.' + [Guid]::NewGuid().ToString('N')
        try {
            $recovery = [IO.File]::Open($preparationLock + '.recovery', 'OpenOrCreate', 'ReadWrite', 'None')
            [string] $ownerPath = Join-Path $preparationLock 'owner'
            if ([IO.File]::Exists($ownerPath) -and [IO.File]::ReadAllText($ownerPath).Trim() -ne $owner.ToString()) { return $false }
            [long] $currentCreated = ([DateTimeOffset] [IO.Directory]::GetLastWriteTimeUtc($preparationLock)).ToUnixTimeSeconds()
            [string] $createdPath = Join-Path $preparationLock 'created'
            if ([IO.File]::Exists($createdPath)) { [void] [long]::TryParse([IO.File]::ReadAllText($createdPath), [ref] $currentCreated) }
            if ($currentCreated -ne $created) { return $false }
            [IO.Directory]::Move($preparationLock, $stalePath)
            Remove-Item -LiteralPath $stalePath -Recurse -Force
        }
        catch { return $false }
        finally { if ($null -ne $recovery) { $recovery.Dispose() } }
        return Get-PreparationLock
    }
}

function Test-ProxyUrl([string] $value) {
    [Uri] $address = $null
    if (-not [Uri]::TryCreate($value, 'Absolute', [ref] $address)) { return $false }
    return $address.Scheme -in @('http', 'https', 'socks5', 'socks5h') -and $address.Host.Length -gt 0 -and
        $address.Query.Length -eq 0 -and $address.Fragment.Length -eq 0 -and $address.AbsolutePath -in @('', '/') -and $value -notmatch '[\s\\"]'
}

function Get-ProxyUrl {
    [string] $value = ''
    if ([IO.File]::Exists((Join-Path $configDirectory 'proxy-url'))) { $value = [IO.File]::ReadAllText((Join-Path $configDirectory 'proxy-url')) }
    elseif ([IO.File]::Exists((Join-Path $configDirectory 'proxy.json'))) { $value = ([IO.File]::ReadAllText((Join-Path $configDirectory 'proxy.json')) | ConvertFrom-Json).url }
    if ($value.Length -gt 0 -and -not (Test-ProxyUrl $value)) { throw 'proxy_configuration_invalid' }
    return $value
}

function Initialize-Runtime {
    $script:hasPreparationLock = $true
    [IO.File]::WriteAllText((Join-Path $preparationLock 'owner'), $PID.ToString())
    if (Test-RuntimeReady) { return }
    [string] $downloadTool = Join-Path $env:SystemRoot 'System32\curl.exe'
    if (-not [IO.File]::Exists($downloadTool)) { throw 'dependency_missing' }
    [string] $proxyUrl = Get-ProxyUrl
    [void] [IO.Directory]::CreateDirectory($runtimeDirectory)
    Get-ChildItem -LiteralPath $runtimeDirectory -Filter '.download.*' -Directory -Force | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 } | Remove-Item -Recurse -Force
    $script:temporaryDirectory = Join-Path $runtimeDirectory ('.download.' + [Guid]::NewGuid().ToString('N'))
    [void] [IO.Directory]::CreateDirectory($temporaryDirectory)
    [string] $archivePath = Join-Path $temporaryDirectory 'runtime.gz'
    [string] $stagedPath = Join-Path $temporaryDirectory 'hipohipo.exe'
    [long] $deadline = (Get-UnixTime) + $downloadTimeoutSeconds
    Write-Diagnostic 'preparation_started' 'started'
    for ([int] $attempt = 1; $attempt -le $downloadMaximumAttempts; $attempt++) {
        [long] $remaining = $deadline - (Get-UnixTime)
        if ($remaining -le 0) { throw 'preparation_timeout' }
        [string[]] $downloadArguments = @('--fail', '--silent', '--location', '--max-redirs', '5', '--proto', '=https', '--proto-redir', '=https', '--continue-at', '-', '--connect-timeout', '10', '--max-time', [string] $remaining, '--max-filesize', [string] $artifact.size, '--output', $archivePath, $artifact.url)
        if ($proxyUrl.Length -gt 0) { $downloadArguments = @('--proxy', $proxyUrl, '--noproxy', '""') + $downloadArguments }
        # Windows PowerShell 5.1 converts native stderr into ErrorRecord. Suppress
        # raw downloader messages; only typed outcomes enter persistent logs.
        [string] $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try { & $downloadTool @downloadArguments 2>$null; [int] $downloadExit = $LASTEXITCODE }
        finally { $ErrorActionPreference = $previousPreference }
        if ($downloadExit -eq 0) { break }
        Write-Diagnostic 'download_attempt' 'failed' 'download_network_error'
        if ($attempt -eq $downloadMaximumAttempts) { throw 'download_network_error' }
        Start-Sleep -Seconds 1
    }
    if (-not (Test-VerifiedFile $archivePath $artifact.size $artifact.sha256)) { throw 'digest_mismatch' }
    Write-Diagnostic 'compressed_verified' 'success' '' $artifact.size
    [IO.FileStream] $compressed = $null
    [IO.Compression.GZipStream] $reader = $null
    [IO.FileStream] $output = $null
    try {
        $compressed = [IO.File]::OpenRead($archivePath)
        $reader = New-Object IO.Compression.GZipStream($compressed, [IO.Compression.CompressionMode]::Decompress)
        $output = [IO.File]::Create($stagedPath)
        [byte[]] $buffer = New-Object byte[] 65536
        [long] $count = 0
        [int] $readCount = 0
        while (($readCount = $reader.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $count += $readCount
            if ($count -gt $artifact.executableSize) { throw 'size_mismatch' }
            $output.Write($buffer, 0, $readCount)
        }
    }
    finally { if ($null -ne $output) { $output.Dispose() }; if ($null -ne $reader) { $reader.Dispose() }; if ($null -ne $compressed) { $compressed.Dispose() } }
    if (-not (Test-VerifiedFile $stagedPath $artifact.executableSize $artifact.executableSha256)) { throw 'digest_mismatch' }
    [string] $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $stagedPath '__runtime-publish' 2>$null; [int] $publishExit = $LASTEXITCODE }
    finally { $ErrorActionPreference = $previousPreference }
    if ($publishExit -ne 0) { throw 'runtime_publish_failed' }
    if ([IO.File]::Exists($failurePath)) { [IO.File]::Delete($failurePath) }
    Write-Diagnostic 'preparation_completed' 'success' '' $artifact.executableSize
}

function Start-Preparation {
    if (Test-RuntimeReady) { return }
    if (Test-Cooldown) { throw 'retry_cooldown' }
    if (-not (Get-PreparationLock)) { return }
    [string] $sourcePath = Join-Path $PSScriptRoot 'launch.ps1'
    [string] $encodedSource = "& '" + $sourcePath.Replace("'", "''") + "' '__runtime-prepare'"
    [Diagnostics.ProcessStartInfo] $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $start.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($encodedSource))
    # .NET Framework's CreateProcess path can inherit unrelated host pipe
    # handles even when its three standard streams are redirected. ShellExecute
    # creates a separate hidden console and does not inherit those MCP handles.
    $start.UseShellExecute = $true
    $start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    [Diagnostics.Process] $child = $null
    try { $child = [Diagnostics.Process]::Start($start) }
    catch { Write-Failure 'preparation_start_failed'; throw 'preparation_start_failed' }
    $child.Dispose()
    Write-Diagnostic 'preparation_requested' 'started'
}

function Write-RuntimeStatus {
    [string] $lastErrorCode = ''
    [object] $retryEligibleAt = $null
    if ([IO.File]::Exists($failurePath)) {
        [string[]] $lines = [IO.File]::ReadAllLines($failurePath)
        [long] $failedAt = 0
        if ($lines.Count -ge 2 -and [long]::TryParse($lines[0], [ref] $failedAt)) {
            $lastErrorCode = $lines[1] -replace '[^a-z0-9_]', ''
            $retryEligibleAt = [DateTimeOffset]::FromUnixTimeSeconds($failedAt + 180).UtcDateTime.ToString('o')
        }
    }
    @{runtimeVersion = $manifest.runtimeVersion; launcherVersion = $manifest.runtimeVersion; platform = 'windows-amd64'; isReady = (Test-RuntimeReady); executablePath = $runtimePath; logPath = $logPath; lastErrorCode = $lastErrorCode; retryEligibleAt = $retryEligibleAt} | ConvertTo-Json -Compress
}

try {
    # MCP clients may filter OS/PROCESSOR_ARCHITECTURE out of the environment.
    # Detect the native process instead of relying on inherited shell variables.
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne 'X64') { throw 'platform_unsupported' }
    if ((Get-Item -LiteralPath $manifestPath).Length -gt 65536) { throw 'manifest_invalid' }
    [object] $manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or $manifest.runtimeVersion -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,80}$') { throw 'manifest_invalid' }
    [object] $artifact = $manifest.artifacts.'windows-amd64'
    [Uri] $address = $null
    if (-not [Uri]::TryCreate($artifact.url, 'Absolute', [ref] $address) -or $address.Scheme -ne 'https' -or $address.Host.Length -eq 0 -or $address.UserInfo.Length -gt 0 -or $address.Fragment.Length -gt 0 -or
        $artifact.sha256 -cnotmatch '^[a-f0-9]{64}$' -or $artifact.executableSha256 -cnotmatch '^[a-f0-9]{64}$' -or $artifact.size -le 0 -or $artifact.size -gt 67108864 -or $artifact.executableSize -le 0 -or $artifact.executableSize -gt 134217728) { throw 'manifest_invalid' }
    [string] $cacheDirectory = $env:HIPO_RUNTIME_CACHE_DIR
    [string] $configDirectory = $env:HIPO_RUNTIME_CONFIG_DIR
    if ([string]::IsNullOrWhiteSpace($cacheDirectory)) { $cacheDirectory = Join-Path $env:LOCALAPPDATA 'Hipohipo\runtimes' }
    if ([string]::IsNullOrWhiteSpace($configDirectory)) { $configDirectory = Join-Path $env:APPDATA 'Hipohipo\runtime-launcher' }
    foreach ($path in @($cacheDirectory, $configDirectory, $manifestPath)) { if (-not [IO.Path]::IsPathRooted($path)) { throw 'configuration_invalid' } }
    Protect-Directory $cacheDirectory
    Protect-Directory $configDirectory
    [string] $cacheKey = $manifest.runtimeVersion + '-windows-amd64-' + $artifact.sha256.Substring(0, 16)
    [string] $runtimeDirectory = Join-Path $cacheDirectory ('versions\' + $manifest.runtimeVersion + '\windows-amd64\' + $artifact.sha256.Substring(0, 16))
    [string] $runtimePath = Join-Path $runtimeDirectory 'hipohipo.exe'
    [string] $preparationLock = Join-Path $cacheDirectory ('locks\' + $cacheKey + '-script-prepare')
    [string] $failurePath = Join-Path $cacheDirectory ('state\' + $cacheKey + '-script-failure')
    $logPath = Join-Path $configDirectory 'logs\bootstrap.jsonl'
    [int] $downloadTimeoutSeconds = 600
    [int] $downloadMaximumAttempts = 5
    if ($env:HIPO_RUNTIME_DOWNLOAD_TIMEOUT_SECONDS -and -not [int]::TryParse($env:HIPO_RUNTIME_DOWNLOAD_TIMEOUT_SECONDS, [ref] $downloadTimeoutSeconds)) { throw 'configuration_invalid' }
    if ($env:HIPO_RUNTIME_DOWNLOAD_ATTEMPTS -and -not [int]::TryParse($env:HIPO_RUNTIME_DOWNLOAD_ATTEMPTS, [ref] $downloadMaximumAttempts)) { throw 'configuration_invalid' }
    if ($downloadTimeoutSeconds -lt 1 -or $downloadTimeoutSeconds -gt 1800 -or $downloadMaximumAttempts -lt 1 -or $downloadMaximumAttempts -gt 10) { throw 'configuration_invalid' }
    $env:HIPO_RUNTIME_CACHE_DIR = $cacheDirectory
    $env:HIPO_RUNTIME_CONFIG_DIR = $configDirectory
    $env:HIPO_RUNTIME_MANIFEST = $manifestPath
    $env:HIPO_CAPTURE_HOST = $hostName
    switch ($commandName) {
        'install' {
            [string] $destination = Join-Path $env:USERPROFILE '.cursor\plugins\local\hipohipo'
            if ([IO.Path]::GetFullPath($destination) -eq [IO.Path]::GetFullPath($pluginRoot)) { throw 'already_installed' }
            [void] [IO.Directory]::CreateDirectory($destination)
            if (((Get-Item -LiteralPath $destination).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'installation_invalid' }
            if (Get-ChildItem -LiteralPath $pluginRoot -Recurse -Force | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }) { throw 'installation_invalid' }
            if ([IO.Directory]::Exists((Join-Path $destination 'bin'))) { Remove-Item -LiteralPath (Join-Path $destination 'bin') -Recurse -Force }
            [IO.File]::Delete((Join-Path $destination 'hipohipo.exe'))
            Get-ChildItem -LiteralPath $pluginRoot -Force | Copy-Item -Destination $destination -Recurse -Force
            [string] $configuration = @{mcpServers = @{hipohipo = @{command = (Join-Path $destination 'hipohipo.cmd'); args = @('mcp'); cwd = $destination}}} | ConvertTo-Json -Depth 5
            [IO.File]::WriteAllText((Join-Path $destination 'mcp.json'), $configuration)
            [string] $hookPath = Join-Path $destination 'hooks\hooks.json'
            if ([IO.File]::Exists((Join-Path $destination 'hooks\cursor.json'))) { $hookPath = Join-Path $destination 'hooks\cursor.json' }
            [hashtable] $hooks = @{}
            foreach ($hookEvent in @('sessionStart', 'beforeSubmitPrompt', 'afterAgentResponse', 'stop', 'sessionEnd')) {
                $hooks[$hookEvent] = @(@{command = ('cmd.exe /d /c call "' + (Join-Path $destination 'scripts\run.cmd') + '" hook --event ' + $hookEvent); timeout = 5})
            }
            [IO.File]::WriteAllText($hookPath, (@{version = 1; hooks = $hooks} | ConvertTo-Json -Depth 6))
            [Console]::WriteLine('Installed local plugin: ' + $destination + "`nReload Cursor to use the plugin.")
            exit 0
        }
        'runtime-status' { Write-RuntimeStatus; exit 0 }
        'proxy-set' {
            if ($RuntimeArguments.Count -ne 2 -or -not (Test-ProxyUrl $RuntimeArguments[1])) { throw 'proxy_configuration_invalid' }
            [string] $proxyPath = Join-Path $configDirectory 'proxy-url'
            [string] $pending = $proxyPath + '.' + $PID
            [IO.File]::WriteAllText($pending, $RuntimeArguments[1])
            if ([IO.File]::Exists($proxyPath)) { [IO.File]::Replace($pending, $proxyPath, $null) }
            else { [IO.File]::Move($pending, $proxyPath) }
            Write-Diagnostic 'proxy_configured' 'success'; exit 0
        }
        'proxy-clear' { foreach ($name in @('proxy-url', 'proxy.json')) { [IO.File]::Delete((Join-Path $configDirectory $name)) }; exit 0 }
        'proxy-status' {
            [string] $proxyUrl = Get-ProxyUrl
            [string] $source = 'environment'
            if ($proxyUrl.Length -gt 0) { $source = 'persistent' }
            @{source = $source; configurationPath = $configDirectory} | ConvertTo-Json -Compress; exit 0
        }
        '__runtime-prepare' { Initialize-Runtime; exit 0 }
        'runtime-retry' {
            [long] $deadline = (Get-UnixTime) + $downloadTimeoutSeconds + 5
            while (-not (Get-PreparationLock)) {
                if (Test-RuntimeReady) { Write-RuntimeStatus; exit 0 }
                if ((Get-UnixTime) -ge $deadline) { throw 'preparation_busy' }
                Start-Sleep -Milliseconds 200
            }
            Initialize-Runtime; Write-RuntimeStatus; exit 0
        }
    }
    if ($isHook) { Write-Diagnostic 'hook_invoked' 'observed' }
    if (-not (Test-RuntimeReady)) {
        if ($isHook) {
            try { Start-Preparation } catch { Write-Diagnostic 'preparation_request' 'failed' 'runtime_unavailable' }
            Write-Diagnostic 'capture_gap' 'runtime_unavailable' 'runtime_missing'
            Write-HookResponse; exit 0
        }
        if ($commandName -eq 'mcp') {
            . (Join-Path $PSScriptRoot 'mcp-bootstrap.ps1')
            Start-McpBootstrap
            exit 0
        }
        Start-Preparation
        [DateTime] $deadline = [DateTime]::UtcNow.AddSeconds(8)
        while (-not (Test-RuntimeReady)) {
            if (Test-Cooldown) { throw 'preparation_failed' }
            if ([DateTime]::UtcNow -ge $deadline) { throw 'runtime_preparing' }
            Start-Sleep -Milliseconds 200
        }
    }
    [IO.File]::WriteAllText((Join-Path $runtimeDirectory 'last-used'), [DateTime]::UtcNow.ToString('o'))
    $ErrorActionPreference = 'Continue'
    & $runtimePath '__runtime-run' @RuntimeArguments
    [int] $runtimeExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    exit $runtimeExit
}
catch {
    [string] $code = 'bootstrap_error'
    if ($_.Exception.Message -match '^[a-z]+[a-z0-9_]*$') { $code = $_.Exception.Message }
    if ($hasPreparationLock) { try { Write-Failure $code } catch { } }
    if ($logPath.Length -gt 0) { Write-Diagnostic 'command_failed' 'failed' $code }
    if ($isHook) { Write-HookResponse; exit 0 }
    [Console]::Error.WriteLine('Hipohipo bootstrap [' + $code + ']. Run runtime-retry, then reconnect MCP. Local log: ' + $logPath)
    exit 1
}
finally {
    if ($temporaryDirectory.Length -gt 0 -and [IO.Directory]::Exists($temporaryDirectory)) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue }
    if ($hasPreparationLock -and [IO.Directory]::Exists($preparationLock)) {
        Remove-Item -LiteralPath $preparationLock -Recurse -Force -ErrorAction SilentlyContinue
    }
}
