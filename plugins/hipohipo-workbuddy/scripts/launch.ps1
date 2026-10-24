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
[string] $setupStateDirectory = ''
for ([int] $index = 1; $index -lt $RuntimeArguments.Count; $index++) {
    if ($RuntimeArguments[$index].StartsWith('--host=')) { $hostName = $RuntimeArguments[$index].Substring(7) }
    if ($RuntimeArguments[$index].StartsWith('--state-dir=')) { $setupStateDirectory = $RuntimeArguments[$index].Substring(12) }
    if ($index -ge $RuntimeArguments.Count - 1) { continue }
    if ($RuntimeArguments[$index] -eq '--state-dir') { $setupStateDirectory = $RuntimeArguments[$index + 1] }
    if ($RuntimeArguments[$index] -eq '--event') { $eventName = $RuntimeArguments[$index + 1] }
    if ($RuntimeArguments[$index] -eq '--host') { $hostName = $RuntimeArguments[$index + 1] }
}
if ($hostName -notin @('cursor', 'cursor-plugin', 'claude-code', 'codex', 'workbuddy')) { $hostName = '' }
if ($eventName -notin @('sessionStart', 'beforeSubmitPrompt', 'afterAgentResponse', 'stop', 'sessionEnd', 'SessionStart', 'UserPromptSubmit', 'Stop', 'PreCompact', 'SessionEnd', 'Interrupt', 'StopFailure')) { $eventName = '' }
[string] $runtimePlatform = 'unknown'
[string] $logPath = ''
[string] $temporaryDirectory = ''
[bool] $hasPreparationLock = $false
[string] $installStaging = ''
[string] $installBackup = ''
[string] $installLockPath = ''
[IO.FileStream] $installLock = $null
$script:preparationGuard = $null
$script:hasPreparationCompetition = $false
$script:activePreparation = $null

function Initialize-LoginDeadline {
    [bool] $isLogin = $commandName -in @('login', 'login-device')
    [int] $timeoutSeconds = 600
    for ([int] $index = 1; $index -lt $RuntimeArguments.Count; $index++) {
        [string[]] $parts = ($RuntimeArguments[$index] -split '=', 2)
        [string] $name = $parts[0]
        if ($isLogin -and $name -in @('--help', '-h', '-help')) {
            [Console]::WriteLine('Usage: ' + $commandName + ' [--device|--headless] [--timeout-seconds 1..600] [--host HOST] [--state-dir PATH] [--configuration-root PATH]')
            [Console]::WriteLine('Default total login timeout: 600 seconds.')
            exit 0
        }
        [bool] $hasValue = $parts.Count -eq 2
        [string] $value = ''
        if ($hasValue) { $value = $parts[1] }
        if ($name -eq '--timeout-seconds') {
            if (-not $isLogin) { throw 'invalid_arguments' }
            if (-not $hasValue) {
                $index++
                if ($index -ge $RuntimeArguments.Count) { throw 'invalid_arguments' }
                $value = $RuntimeArguments[$index]
            }
            if ($value -notmatch '^[0-9]+$' -or -not [int]::TryParse($value, [ref] $timeoutSeconds) -or $timeoutSeconds -lt 1 -or $timeoutSeconds -gt 600) { throw 'invalid_arguments' }
            continue
        }
        if (-not $isLogin) { continue }
        if ($name -in @('--host', '--state-dir', '--configuration-root')) {
            if (-not $hasValue) {
                $index++
                if ($index -ge $RuntimeArguments.Count -or $RuntimeArguments[$index].StartsWith('--')) { throw 'invalid_arguments' }
            }
            continue
        }
        if ($name -in @('--device', '--headless')) {
            if ($commandName -ne 'login' -or ($hasValue -and $value -cnotin @('true', 'false'))) { throw 'invalid_arguments' }
            continue
        }
        throw 'invalid_arguments'
    }
    if (-not $isLogin) { return }
    [long] $deadline = ([DateTimeOffset] $invocationStarted).ToUnixTimeMilliseconds() + ([long] $timeoutSeconds * 1000)
    if ($env:HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS) {
        [long] $inheritedDeadline = 0
        if ($env:HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS -notmatch '^[0-9]+$' -or -not [long]::TryParse($env:HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS, [ref] $inheritedDeadline) -or $inheritedDeadline -lt 1) { throw 'configuration_invalid' }
        $deadline = [Math]::Min($deadline, $inheritedDeadline)
    }
    $env:HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS = $deadline.ToString()
}

function Assert-LoginTime {
    if ($commandName -in @('login', 'login-device') -and [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() -ge [long] $env:HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS) { throw 'login_timeout' }
}

function Write-HookResponse {
    if ($commandName -eq 'hook' -and $eventName -eq 'beforeSubmitPrompt') { [Console]::WriteLine('{"continue":true}') }
    else { [Console]::WriteLine('{}') }
}

function Get-UnixTime { return [long] ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) }

function Test-VerifiedFile([string] $path, [long] $size, [string] $digest) {
    Assert-LoginTime
    if (-not [IO.File]::Exists($path)) { return $false }
    [IO.FileInfo] $info = New-Object IO.FileInfo $path
    if (($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $info.Length -ne $size) { return $false }
    [IO.FileStream] $stream = $null
    [Security.Cryptography.SHA256] $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::OpenRead($path)
        [byte[]] $buffer = New-Object byte[] 65536
        [int] $count = 0
        while (($count = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            Assert-LoginTime
            [void] $algorithm.TransformBlock($buffer, 0, $count, $buffer, 0)
        }
        Assert-LoginTime
        [void] $algorithm.TransformFinalBlock($buffer, 0, 0)
        return [BitConverter]::ToString($algorithm.Hash).Replace('-', '').ToLowerInvariant() -eq $digest
    }
    catch { if ($_.Exception.Message -eq 'login_timeout') { throw }; return $false }
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
        [string] $record = @{timestamp = [DateTime]::UtcNow.ToString('o'); component = 'bootstrap'; event = $event; outcome = $outcome; errorCode = $code; runtimeVersion = $manifest.runtimeVersion; launcherVersion = $manifest.runtimeVersion; platform = $runtimePlatform; host = $hostName; hook = $eventName; correlationId = [string] $PID; elapsedMilliseconds = [long] ([DateTime]::UtcNow - $invocationStarted).TotalMilliseconds; byteCount = $byteCount} | ConvertTo-Json -Compress
        [IO.File]::AppendAllText($logPath, $record + "`n", (New-Object Text.UTF8Encoding $false))
    }
    catch { }
    finally { if ($null -ne $guard) { $guard.Dispose() } }
}

function Write-Failure([string] $code) {
    if ($null -ne $script:activePreparation) {
        $script:activePreparation.state = 'failed'
        $script:activePreparation.lastErrorCode = $code
        Save-PreparationState $script:activePreparation
    }
    Write-Diagnostic 'preparation_completed' 'failed' $code
}

function Test-Cooldown {
    [object] $state = Read-PreparationState
    return $null -ne $state -and ($state.state -eq 'failed' -or ($state.state -eq 'preparing' -and (Get-UnixTime) -ge $state.deadlineAtUnixSeconds))
}

function Save-PublicationError([string] $path) {
    # Only the verified local publisher's stderr is retained, never curl output.
    [IO.FileStream] $source = $null
    [IO.FileStream] $destination = $null
    try {
        $source = [IO.File]::OpenRead($path)
        [byte[]] $buffer = New-Object byte[] 8192
        [int] $count = $source.Read($buffer, 0, $buffer.Length)
        $destination = [IO.File]::Create($publicationErrorPath)
        $destination.Write($buffer, 0, $count)
    }
    catch { }
    finally { if ($null -ne $source) { $source.Dispose() }; if ($null -ne $destination) { $destination.Dispose() } }
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

function Read-PreparationState {
    if (-not [IO.Directory]::Exists((Split-Path $preparationStatePath -Parent))) { return $null }
    # ReplaceFileW can briefly hide the name while existing readers retain the
    # previous file. A bounded read retry must not turn that gap into cold state.
    for ([int] $readAttempt = 0; $readAttempt -le 20; $readAttempt++) {
        try {
            [IO.FileStream] $stream = [IO.File]::Open($preparationStatePath, 'Open', 'Read', ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
            [IO.StreamReader] $reader = New-Object IO.StreamReader $stream
            try { [object] $state = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose(); $stream.Dispose() }
            # Older resumable attempts used the primary origin exclusively.
            if ($null -eq $state.PSObject.Properties['downloadOrigin']) { $state | Add-Member -NotePropertyName downloadOrigin -NotePropertyValue 'primary' }
            if ($null -eq $state.PSObject.Properties['originFallbacks']) { $state | Add-Member -NotePropertyName originFallbacks -NotePropertyValue 0 }
            if ($null -eq $state.PSObject.Properties['artifactIdentity']) { $state | Add-Member -NotePropertyName artifactIdentity -NotePropertyValue '' }
            if ($null -eq $state.PSObject.Properties['artifactAttemptId']) { $state | Add-Member -NotePropertyName artifactAttemptId -NotePropertyValue '' }
            if ($state.artifactIdentity -isnot [string] -or $state.artifactAttemptId -isnot [string] -or ($state.artifactAttemptId -ne '' -and $state.artifactAttemptId -notmatch '^[A-Za-z0-9][A-Za-z0-9_-]*$')) { throw 'preparation_state_invalid' }
            if ($state.attemptId -notmatch '^[A-Za-z0-9_-]+$' -or $state.state -notin @('preparing', 'failed', 'ready') -or $state.phase -notin @('download', 'verify', 'publish', 'ready') -or $state.startedAtUnixSeconds -le 0 -or $state.deadlineAtUnixSeconds -lt $state.startedAtUnixSeconds -or $state.networkFailures -lt 0 -or $state.downloadedBytes -lt 0 -or $state.lastErrorCode -notmatch '^[a-z0-9_]*$' -or $state.downloadOrigin -notin @('primary', 'mirror') -or $state.originFallbacks -notin @(0, 1) -or ($state.originFallbacks -isnot [int] -and $state.originFallbacks -isnot [long])) { throw 'preparation_state_invalid' }
            return $state
        } catch {
            [Exception] $cause = $_.Exception
            while ($null -ne $cause.InnerException) { $cause = $cause.InnerException }
            if ($cause -is [IO.FileNotFoundException]) {
                if ($readAttempt -ge 20) { return $null }
                Start-Sleep -Milliseconds 5
                continue
            }
            if ($cause -is [IO.IOException] -or $cause -is [UnauthorizedAccessException]) { throw 'local_io_error' }
            throw 'preparation_state_invalid'
        }
    }
}

function Test-PreparationInspectionError([string] $code) {
    return $code -in @('dependency_missing', 'preparation_state_invalid', 'runtime_publish_failed', 'artifact_url_invalid') -or $code -match 'permission|identity|local|configuration|^lock_'
}

function Save-PreparationState([object] $state) {
    [string] $pending = $preparationStatePath + '.' + $PID + '.tmp'
    [IO.File]::WriteAllText($pending, ($state | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding $false))
    if ([IO.File]::Exists($preparationStatePath)) { [IO.File]::Replace($pending, $preparationStatePath, [NullString]::Value) }
    else { [IO.File]::Move($pending, $preparationStatePath) }
}

function Get-PreparationLock {
    try {
        [void] [IO.Directory]::CreateDirectory((Split-Path $preparationLock -Parent))
        [void] [IO.Directory]::CreateDirectory((Split-Path $preparationStatePath -Parent))
        $script:preparationGuard = [IO.File]::Open($preparationLock, 'OpenOrCreate', 'ReadWrite', 'ReadWrite')
        $script:preparationGuard.Lock(0, 1)
        $script:hasPreparationLock = $true
        return $true
    } catch {
        if ($null -ne $script:preparationGuard) { $script:preparationGuard.Dispose(); $script:preparationGuard = $null }
        [Exception] $cause = $_.Exception
        while ($null -ne $cause.InnerException) { $cause = $cause.InnerException }
        if (($cause.HResult -band 65535) -eq 33) { $script:hasPreparationCompetition = $true; return $false }
        if ($cause -is [UnauthorizedAccessException] -or $cause -is [IO.IOException]) { throw 'local_io_error' }
        throw 'lock_unavailable'
    }
}

function Close-PreparationLock {
    if ($null -ne $script:preparationGuard) {
        try { if ($script:hasPreparationLock) { $script:preparationGuard.Unlock(0, 1) } }
        finally { $script:preparationGuard.Dispose(); $script:preparationGuard = $null; $script:hasPreparationLock = $false }
    }
}

function Assert-PreparationTime {
    if ((Get-UnixTime) -ge $script:activePreparation.deadlineAtUnixSeconds) { throw 'preparation_timeout' }
    if ((Get-UnixTime) -ge $script:callDeadline) { throw 'preparation_slice_complete' }
}

function Initialize-PreparationProcess {
    if ($null -ne ('HipohipoPreparationProcess' -as [type])) { return }
    # Closing the job on process death also closes curl/publisher, so another
    # call can acquire the preparation lock and resume the same archive safely.
    Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class HipohipoPreparationProcess {
    [StructLayout(LayoutKind.Sequential)] struct BasicLimits {
        public long ProcessTime, JobTime; public uint Flags; public UIntPtr Minimum, Maximum;
        public uint ProcessLimit; public UIntPtr Affinity; public uint Priority, Scheduling;
    }
    [StructLayout(LayoutKind.Sequential)] struct IoCounters { public ulong Read, Write, Other, ReadBytes, WriteBytes, OtherBytes; }
    [StructLayout(LayoutKind.Sequential)] struct ExtendedLimits {
        public BasicLimits Basic; public IoCounters Io; public UIntPtr ProcessMemory, JobMemory, PeakProcess, PeakJob;
    }
    [DllImport("kernel32.dll", SetLastError=true)] static extern IntPtr CreateJobObject(IntPtr attributes, string name);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool SetInformationJobObject(IntPtr job, int kind, IntPtr information, uint size);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
    public static int Run(string executable, string arguments, long deadline, string errorPath) {
        IntPtr job = CreateJobObject(IntPtr.Zero, null);
        if (job == IntPtr.Zero) throw new InvalidOperationException("runtime_process_failed");
        Process child = null;
        try {
            ExtendedLimits limits = new ExtendedLimits(); limits.Basic.Flags = 0x2000;
            int size = Marshal.SizeOf(limits); IntPtr buffer = Marshal.AllocHGlobal(size);
            try {
                Marshal.StructureToPtr(limits, buffer, false);
                if (!SetInformationJobObject(job, 9, buffer, (uint)size)) throw new InvalidOperationException("runtime_process_failed");
            } finally { Marshal.FreeHGlobal(buffer); }
            ProcessStartInfo start = new ProcessStartInfo(executable, arguments);
            start.UseShellExecute = false; start.CreateNoWindow = true;
            start.RedirectStandardOutput = true; start.RedirectStandardError = true;
            child = Process.Start(start);
            if (!AssignProcessToJobObject(job, child.Handle)) { child.Kill(); throw new InvalidOperationException("runtime_process_failed"); }
            System.Threading.Tasks.Task<string> output = child.StandardOutput.ReadToEndAsync();
            System.Threading.Tasks.Task<string> error = child.StandardError.ReadToEndAsync();
            while (!child.WaitForExit(50)) {
                if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() >= deadline) {
                    CloseHandle(job); job = IntPtr.Zero; child.WaitForExit(); return -1;
                }
            }
            if (!String.IsNullOrEmpty(errorPath)) {
                string content = error.Result;
                System.IO.File.WriteAllText(errorPath, content.Substring(0, Math.Min(content.Length, 8192)));
            }
            return child.ExitCode;
        } finally { if (job != IntPtr.Zero) CloseHandle(job); if (child != null) child.Dispose(); }
    }
}
'@
}

function ConvertTo-ProcessArgument([string] $value) {
    return '"' + [regex]::Replace([regex]::Replace($value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}

function Invoke-PreparationProcess([string] $executable, [string[]] $arguments, [string] $errorPath = '') {
    Initialize-PreparationProcess
    Assert-PreparationTime
    [string] $encoded = ($arguments | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join ' '
    return [HipohipoPreparationProcess]::Run($executable, $encoded, $script:callDeadline, $errorPath)
}

function Test-PreparationFile([string] $path, [long] $size, [string] $digest) {
    Assert-PreparationTime
    if (-not [IO.File]::Exists($path)) { return $false }
    [IO.FileInfo] $info = New-Object IO.FileInfo $path
    if (($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $info.Length -ne $size) { return $false }
    [IO.FileStream] $stream = [IO.File]::OpenRead($path)
    [Security.Cryptography.SHA256] $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        [byte[]] $buffer = New-Object byte[] 65536
        [int] $count = 0
        while (($count = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            Assert-PreparationTime
            [void] $algorithm.TransformBlock($buffer, 0, $count, $buffer, 0)
        }
        [void] $algorithm.TransformFinalBlock($buffer, 0, 0)
        return [BitConverter]::ToString($algorithm.Hash).Replace('-', '').ToLowerInvariant() -eq $digest
    } finally { $stream.Dispose(); $algorithm.Dispose() }
}

function Invoke-RuntimeDownload([string] $archivePath) {
    [string] $downloadTool = Join-Path $env:SystemRoot 'System32\curl.exe'
    if (-not [IO.File]::Exists($downloadTool)) { throw 'dependency_missing' }
    [string] $proxyUrl = Get-ProxyUrl
    [string] $headersPath = Join-Path $script:temporaryDirectory 'download.headers'
    while ($true) {
        Assert-PreparationTime
        [long] $offset = 0
        if ([IO.File]::Exists($archivePath)) { $offset = (New-Object IO.FileInfo $archivePath).Length }
        $script:activePreparation.downloadedBytes = $offset
        Save-PreparationState $script:activePreparation
        if ($offset -eq $artifact.size) { return }
        if ($offset -gt $artifact.size) { throw 'size_mismatch' }
        [string] $downloadUrl = $artifact.url
        if ($script:activePreparation.downloadOrigin -eq 'mirror') {
            if ($mirrorUrl.Length -eq 0) { throw 'configuration_invalid' }
            $downloadUrl = $mirrorUrl
        }
        [long] $remaining = $script:callDeadline - (Get-UnixTime)
        [string[]] $arguments = @('--fail', '--silent', '--location', '--max-redirs', '5', '--proto', '=https', '--proto-redir', '=https', '--continue-at', [string] $offset, '--connect-timeout', [string] ([Math]::Min(10, $remaining)), '--speed-limit', '1', '--speed-time', '10', '--max-time', [string] $remaining, '--max-filesize', [string] $artifact.size, '--suppress-connect-headers', '--dump-header', $headersPath, '--output', $archivePath, $downloadUrl)
        if ($proxyUrl.Length -gt 0) { $arguments = @('--proxy', $proxyUrl, '--noproxy', '') + $arguments }
        [int] $downloadExit = Invoke-PreparationProcess $downloadTool $arguments
        if ([IO.File]::Exists($archivePath)) { $script:activePreparation.downloadedBytes = (New-Object IO.FileInfo $archivePath).Length }
        Save-PreparationState $script:activePreparation
        [string] $headers = ''
        if ([IO.File]::Exists($headersPath)) { $headers = [IO.File]::ReadAllText($headersPath) }
        [object[]] $responses = @([regex]::Matches($headers, '(?m)^HTTP/\S+\s+(\d{3})[^\r\n]*\r?\n([\s\S]*?)(?=\r?\n\r?\n)'))
        if ($responses.Count -gt 0) {
            [object] $response = $responses[$responses.Count - 1]
            [int] $status = [int] $response.Groups[1].Value
            if ($status -eq 416) { throw 'download_range_invalid' }
            [int] $expectedStatus = 200
            if ($offset -gt 0) { $expectedStatus = 206 }
            if ($offset -gt 0 -and $status -eq 200) { throw 'download_resume_unsupported' }
            if ($status -ge 200 -and $status -lt 400 -and $status -ne $expectedStatus) { throw 'download_response_invalid' }
            if ($offset -gt 0) {
                if ($status -eq 206 -and $response.Groups[2].Value -notmatch ('(?im)^Content-Range:\s*bytes ' + $offset + '-' + ([long] $artifact.size - 1) + '/' + $artifact.size + '\s*$')) { throw 'download_range_invalid' }
            }
        }
        if ($downloadExit -eq 0) {
            if ($offset -gt 0 -and ($responses.Count -eq 0 -or [int] $responses[$responses.Count - 1].Groups[1].Value -ne 206)) { throw 'download_resume_unsupported' }
            return
        }
        if ($downloadExit -in @(23, 26)) { throw 'local_io_error' }
        if ($downloadExit -eq 63) { throw 'size_mismatch' }
        if ($downloadExit -eq 33) { throw 'download_resume_unsupported' }
        if ($downloadExit -eq -1 -or ($downloadExit -eq 28 -and (Get-UnixTime) -ge $script:callDeadline)) { Assert-PreparationTime; throw 'preparation_slice_complete' }
        $script:activePreparation.networkFailures++
        if ($script:activePreparation.networkFailures -lt $downloadMaximumAttempts -and $mirrorUrl.Length -gt 0 -and $script:activePreparation.originFallbacks -eq 0) {
            if ($script:activePreparation.downloadOrigin -eq 'mirror') { $script:activePreparation.downloadOrigin = 'primary' }
            else { $script:activePreparation.downloadOrigin = 'mirror' }
            $script:activePreparation.originFallbacks = 1
        }
        Save-PreparationState $script:activePreparation
        Write-Diagnostic 'download_attempt' 'failed' 'download_network_error'
        if ($script:activePreparation.networkFailures -ge $downloadMaximumAttempts) { throw 'download_network_error' }
    }
}

function Get-PreparationDirectory([object] $state) {
    [string] $identifier = $state.artifactAttemptId
    if ($identifier.Length -eq 0) { $identifier = $state.attemptId }
    return Join-Path $runtimeDirectory ('preparation\' + $identifier)
}

function Test-RetainedPreparationArtifact([object] $state, [string] $identity) {
    if ($null -eq $state -or $state.state -ne 'failed' -or $state.artifactIdentity -ne $identity) { return $false }
    if ($state.lastErrorCode -notin @('preparation_timeout', 'download_network_error', 'download_interrupted') -and $state.lastErrorCode -notmatch '^download_http_[45][0-9]{2}$') { return $false }
    [string] $directory = Get-PreparationDirectory $state
    if (-not [IO.Directory]::Exists($directory) -or ([IO.File]::GetAttributes($directory) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return $false }
    [string] $path = Join-Path $directory 'runtime.gz'
    if (-not [IO.File]::Exists($path)) { return $false }
    [IO.FileInfo] $info = New-Object IO.FileInfo $path
    return ($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 -and $info.Length -gt 0 -and $info.Length -le $artifact.size
}

function Set-PreparationAttempt([bool] $isExplicit) {
    $script:activePreparation = Read-PreparationState
    if ($null -ne $script:activePreparation -and $script:activePreparation.state -eq 'preparing' -and (Get-UnixTime) -ge $script:activePreparation.deadlineAtUnixSeconds) { $script:activePreparation.state = 'failed'; $script:activePreparation.lastErrorCode = 'preparation_timeout'; Save-PreparationState $script:activePreparation }
    if ($null -eq $script:activePreparation -or $script:activePreparation.state -eq 'ready' -or ($isExplicit -and $script:activePreparation.state -eq 'failed')) {
        [string] $identity = $manifest.runtimeVersion + '/' + $runtimePlatform + '/' + $artifact.sha256 + '/' + $artifact.size
        [string] $artifactAttemptId = ''
        if ($isExplicit -and (Test-RetainedPreparationArtifact $script:activePreparation $identity)) {
            $artifactAttemptId = $script:activePreparation.artifactAttemptId
            if ($artifactAttemptId.Length -eq 0) { $artifactAttemptId = $script:activePreparation.attemptId }
        }
        [long] $startedAt = Get-UnixTime
        [string] $downloadOrigin = 'primary'
        if ($hostName -eq 'workbuddy' -and $mirrorUrl.Length -gt 0) { $downloadOrigin = 'mirror' }
        [string] $attemptId = [Guid]::NewGuid().ToString('N')
        # An atomic journal reference preserves the prefix without a crash-prone
        # copy or move; verification starts again under the new attempt budget.
        if ($artifactAttemptId.Length -eq 0) { $artifactAttemptId = $attemptId }
        $script:activePreparation = [pscustomobject] @{attemptId = $attemptId; startedAtUnixSeconds = $startedAt; deadlineAtUnixSeconds = $startedAt + $downloadTimeoutSeconds; state = 'preparing'; phase = 'download'; networkFailures = 0; downloadedBytes = 0; lastErrorCode = ''; downloadOrigin = $downloadOrigin; originFallbacks = 0; artifactIdentity = $identity; artifactAttemptId = $artifactAttemptId}
        Save-PreparationState $script:activePreparation
        try { [IO.File]::Delete($publicationErrorPath) } catch { }
        Write-Diagnostic 'preparation_started' 'started'
    }
}

function Initialize-Runtime([bool] $isExplicit = $false, [long] $deadline = 0) {
    if (Test-RuntimeReady) { return }
    if (-not (Get-PreparationLock)) { return }
    try {
        Set-PreparationAttempt $isExplicit
        if ($script:activePreparation.state -eq 'failed') { return }
        $script:callDeadline = $script:activePreparation.deadlineAtUnixSeconds
        if ($deadline -gt 0) { $script:callDeadline = [Math]::Min($deadline, $script:callDeadline) }
        $env:HIPO_RUNTIME_PREPARATION_DEADLINE = [string] $script:activePreparation.deadlineAtUnixSeconds
        $env:HIPO_SETUP_DEADLINE_UNIX_SECONDS = [string] $script:callDeadline
        Assert-PreparationTime
        $script:temporaryDirectory = Get-PreparationDirectory $script:activePreparation
        [void] [IO.Directory]::CreateDirectory($script:temporaryDirectory)
        [string] $archivePath = Join-Path $script:temporaryDirectory 'runtime.gz'
        [string] $stagedPath = Join-Path $script:temporaryDirectory 'hipohipo.exe'
        if ($script:activePreparation.phase -eq 'download') {
            Invoke-RuntimeDownload $archivePath
            $script:activePreparation.phase = 'verify'; Save-PreparationState $script:activePreparation
        }
        if ($script:activePreparation.phase -eq 'verify') {
            if (-not (Test-PreparationFile $archivePath $artifact.size $artifact.sha256)) { throw 'digest_mismatch' }
            [IO.FileStream] $compressed = [IO.File]::OpenRead($archivePath)
            [IO.Compression.GZipStream] $reader = New-Object IO.Compression.GZipStream($compressed, [IO.Compression.CompressionMode]::Decompress)
            [IO.FileStream] $output = [IO.File]::Create($stagedPath)
            try {
                [byte[]] $buffer = New-Object byte[] 65536
                [long] $count = 0; [int] $readCount = 0
                while (($readCount = $reader.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    Assert-PreparationTime
                    $count += $readCount
                    if ($count -gt $artifact.executableSize) { throw 'size_mismatch' }
                    $output.Write($buffer, 0, $readCount)
                }
            } finally { $output.Dispose(); $reader.Dispose(); $compressed.Dispose() }
            if (-not (Test-PreparationFile $stagedPath $artifact.executableSize $artifact.executableSha256)) { throw 'digest_mismatch' }
            $script:activePreparation.phase = 'publish'; Save-PreparationState $script:activePreparation
        }
        if (-not (Test-PreparationFile $stagedPath $artifact.executableSize $artifact.executableSha256)) { throw 'digest_mismatch' }
        [string] $publishError = Join-Path $script:temporaryDirectory 'publish.stderr'
        [int] $publishExit = Invoke-PreparationProcess $stagedPath @('__runtime-publish') $publishError
        if ($publishExit -eq -1) { Assert-PreparationTime; throw 'preparation_slice_complete' }
        if ($publishExit -ne 0) { Save-PublicationError $publishError; Assert-PreparationTime; throw 'runtime_publish_failed' }
        Assert-PreparationTime
        if (-not (Test-PreparationFile $runtimePath $artifact.executableSize $artifact.executableSha256)) { throw 'runtime_publish_failed' }
        $script:activePreparation.state = 'ready'; $script:activePreparation.phase = 'ready'; $script:activePreparation.lastErrorCode = ''
        Save-PreparationState $script:activePreparation
        Write-Diagnostic 'preparation_completed' 'success' '' $artifact.executableSize
    } catch {
        [string] $code = 'bootstrap_error'
        if ($_.Exception.Message -match '^[a-z]+[a-z0-9_]*$') { $code = $_.Exception.Message }
        if ($code -ne 'preparation_slice_complete') {
            if ($null -eq $script:activePreparation) { throw }
            Write-Failure $code
        }
    } finally { Close-PreparationLock }
}

function Start-Preparation([bool] $isExplicit = $false) {
    if (Test-RuntimeReady) { return }
    if (-not (Get-PreparationLock)) { return }
    try {
        Set-PreparationAttempt $isExplicit
        if ($script:activePreparation.state -eq 'failed') { throw 'retry_cooldown' }
    } finally { Close-PreparationLock }
    [string] $sourcePath = Join-Path $PSScriptRoot 'launch.ps1'
    [string] $encodedSource = "& '" + $sourcePath.Replace("'", "''") + "' '__runtime-prepare'"
    [Diagnostics.ProcessStartInfo] $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $start.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($encodedSource))
    $start.UseShellExecute = $true
    $start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    [Diagnostics.Process] $child = [Diagnostics.Process]::Start($start)
    $child.Dispose()
    Write-Diagnostic 'preparation_requested' 'started'
}

function Select-RuntimePlatform([string] $architecture) {
    switch ($architecture) {
        'X64' { return 'windows-amd64' }
        'AMD64' { return 'windows-amd64' }
        'Arm64' { return 'windows-arm64' }
        default { throw 'platform_unsupported' }
    }
}

function Write-RuntimeStatus {
    [object] $attempt = Read-PreparationState
    [bool] $isReady = Test-RuntimeReady
    [string] $state = 'not_prepared'
    [string] $nextAction = 'continue_setup'
    [string] $lastErrorCode = ''
    if ($script:hasPreparationCompetition) { $state = 'preparing' }
    if ($null -ne $attempt) {
        $state = $attempt.state
        $lastErrorCode = $attempt.lastErrorCode
        if ($state -eq 'ready' -and -not $isReady) { $state = 'not_prepared' }
        if ($state -eq 'preparing' -and (Get-UnixTime) -ge $attempt.deadlineAtUnixSeconds) { $state = 'failed'; $lastErrorCode = 'preparation_timeout' }
    }
    if ($state -eq 'failed') { $nextAction = $(if (Test-PreparationInspectionError $lastErrorCode) { 'inspect_error' } else { 'request_runtime_retry' }) }
    if ($isReady) { $state = 'ready'; $nextAction = 'none'; $lastErrorCode = '' }
    @{state = $state; nextAction = $nextAction; runtimeVersion = $manifest.runtimeVersion; launcherVersion = $manifest.runtimeVersion; platform = $runtimePlatform; isReady = $isReady; executablePath = $runtimePath; logPath = $logPath; publicationErrorPath = $(if ([IO.File]::Exists($publicationErrorPath)) { $publicationErrorPath } else { '' }); lastErrorCode = $lastErrorCode; retryEligibleAt = $null; attemptId = $(if ($null -ne $attempt) { $attempt.attemptId } else { $null }); startedAtUnixSeconds = $(if ($null -ne $attempt) { $attempt.startedAtUnixSeconds } else { $null }); deadlineAtUnixSeconds = $(if ($null -ne $attempt) { $attempt.deadlineAtUnixSeconds } else { $null }); phase = $(if ($isReady) { 'ready' } elseif ($state -eq 'not_prepared') { '' } elseif ($null -ne $attempt) { $attempt.phase } else { '' }); downloadedBytes = $(if ($null -ne $attempt) { $attempt.downloadedBytes } else { 0 })} | ConvertTo-Json -Compress
}

function Write-SetupStatus {
    [object] $status = Write-RuntimeStatus | ConvertFrom-Json
    if ($commandName -in @('login', 'login-device')) {
        $status | Add-Member -NotePropertyName operationExecuted -NotePropertyValue $false
        $status | Add-Member -NotePropertyName message -NotePropertyValue 'Login has not executed. Continue the same login command while preparation is pending; after failure inspect the error and request runtime-retry explicitly.'
    }
    $status | ConvertTo-Json -Depth 6 -Compress
}

function Wait-SetupPreparation([bool] $isExplicit) {
    [int] $waitSeconds = 30
    if ($env:HIPO_SETUP_WAIT_TIMEOUT_SECONDS -and -not [int]::TryParse($env:HIPO_SETUP_WAIT_TIMEOUT_SECONDS, [ref] $waitSeconds)) { throw 'configuration_invalid' }
    if ($waitSeconds -lt 1 -or $waitSeconds -gt 30) { throw 'configuration_invalid' }
    [long] $deadline = ([DateTimeOffset] $invocationStarted).ToUnixTimeSeconds() + $waitSeconds
    if ($env:HIPO_SETUP_DEADLINE_UNIX_SECONDS) {
        [long] $inheritedDeadline = 0
        if (-not [long]::TryParse($env:HIPO_SETUP_DEADLINE_UNIX_SECONDS, [ref] $inheritedDeadline)) { throw 'configuration_invalid' }
        $deadline = [Math]::Min($deadline, $inheritedDeadline)
    }
    if ($commandName -in @('login', 'login-device')) {
        $deadline = [Math]::Min($deadline, [long] [Math]::Floor(([long] $env:HIPO_LOGIN_DEADLINE_UNIX_MILLISECONDS) / 1000.0))
    }
    $env:HIPO_SETUP_DEADLINE_UNIX_SECONDS = $deadline.ToString()
    Initialize-Runtime $isExplicit ([long] $env:HIPO_SETUP_DEADLINE_UNIX_SECONDS)
    if (Test-RuntimeReady) { return 0 }
    if (Test-Cooldown) { return 1 }
    return 2
}

try {
    Initialize-LoginDeadline
    Assert-LoginTime
    # Emulated PowerShell can report its x64 compatibility architecture as the OS
    # architecture. The shared system registry retains the native machine value
    # even when a host filters or changes inherited environment variables.
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'platform_unsupported' }
    [string] $nativeArchitecture = [Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'PROCESSOR_ARCHITECTURE', $null)
    $runtimePlatform = Select-RuntimePlatform $nativeArchitecture
    if ((Get-Item -LiteralPath $manifestPath).Length -gt 65536) { throw 'manifest_invalid' }
    [object] $manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or $manifest.runtimeVersion -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,80}$') { throw 'manifest_invalid' }
    [object] $artifact = $manifest.artifacts.$runtimePlatform
    [string] $mirrorUrl = ''
    if ($null -ne $artifact.PSObject.Properties['mirrorUrl'] -and $artifact.mirrorUrl) {
        [Uri] $mirrorAddress = $null
        if (-not [Uri]::TryCreate($artifact.mirrorUrl, 'Absolute', [ref] $mirrorAddress) -or $mirrorAddress.Scheme -ne 'https' -or $mirrorAddress.Host.Length -eq 0 -or $mirrorAddress.UserInfo.Length -gt 0 -or $mirrorAddress.Query.Length -gt 0 -or $mirrorAddress.Fragment.Length -gt 0 -or $artifact.mirrorUrl -match '\s') { throw 'manifest_invalid' }
        $mirrorUrl = $artifact.mirrorUrl
    }
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
    [string] $cacheKey = $manifest.runtimeVersion + '-' + $runtimePlatform + '-' + $artifact.sha256.Substring(0, 16)
    [string] $runtimeDirectory = Join-Path $cacheDirectory ('versions\' + $manifest.runtimeVersion + '\' + $runtimePlatform + '\' + $artifact.sha256.Substring(0, 16))
    [string] $runtimePath = Join-Path $runtimeDirectory 'hipohipo.exe'
    [string] $preparationLock = Join-Path $cacheDirectory ('locks\' + $cacheKey + '-preparation.lock')
    [string] $preparationStatePath = Join-Path $cacheDirectory ('state\' + $cacheKey + '-preparation.json')
    $logPath = Join-Path $configDirectory 'logs\bootstrap.jsonl'
    [string] $publicationErrorPath = Join-Path $configDirectory ('logs\' + $cacheKey + '-publication.stderr')
    [int] $downloadTimeoutSeconds = 600
    [int] $downloadMaximumAttempts = 3
    if ($env:HIPO_RUNTIME_DOWNLOAD_TIMEOUT_SECONDS -and -not [int]::TryParse($env:HIPO_RUNTIME_DOWNLOAD_TIMEOUT_SECONDS, [ref] $downloadTimeoutSeconds)) { throw 'configuration_invalid' }
    if ($env:HIPO_RUNTIME_DOWNLOAD_ATTEMPTS -and -not [int]::TryParse($env:HIPO_RUNTIME_DOWNLOAD_ATTEMPTS, [ref] $downloadMaximumAttempts)) { throw 'configuration_invalid' }
    if ($downloadTimeoutSeconds -lt 1 -or $downloadTimeoutSeconds -gt 600 -or $downloadMaximumAttempts -lt 1 -or $downloadMaximumAttempts -gt 3) { throw 'configuration_invalid' }
    $env:HIPO_RUNTIME_CACHE_DIR = $cacheDirectory
    $env:HIPO_RUNTIME_CONFIG_DIR = $configDirectory
    $env:HIPO_RUNTIME_MANIFEST = $manifestPath
    $env:HIPO_CAPTURE_HOST = $hostName
    switch ($commandName) {
        'install' {
            [string] $destination = Join-Path $env:USERPROFILE '.cursor\plugins\local\hipohipo'
            if ([IO.Path]::GetFullPath($destination) -eq [IO.Path]::GetFullPath($pluginRoot)) { throw 'already_installed' }
            [object] $packageManifest = [IO.File]::ReadAllText((Join-Path $pluginRoot '.cursor-plugin\plugin.json')) | ConvertFrom-Json
            if ($packageManifest.name -ne 'hipohipo' -or $packageManifest.version -ne $manifest.runtimeVersion) { throw 'installation_invalid' }
            [string] $hookFile = 'hooks.json'
            if ($null -ne $packageManifest.PSObject.Properties['hooks']) {
                if ($packageManifest.hooks -eq './hooks/cursor.json') { $hookFile = 'cursor.json' }
                elseif ($packageManifest.hooks -ne './hooks/hooks.json') { throw 'installation_invalid' }
            }
            if (Get-ChildItem -LiteralPath $pluginRoot -Recurse -Force | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }) { throw 'installation_invalid' }
            [void] [IO.Directory]::CreateDirectory((Split-Path $destination -Parent))
            [string] $candidateLock = $destination + '-install.lock'
            try { $installLock = [IO.File]::Open($candidateLock, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None) }
            catch { throw 'installation_busy' }
            $installLockPath = $candidateLock
            if (Test-Path -LiteralPath $destination) {
                if (-not [IO.Directory]::Exists($destination) -or ((Get-Item -LiteralPath $destination).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'installation_invalid' }
                [string] $previousManifestPath = Join-Path $destination '.cursor-plugin\plugin.json'
                if (-not [IO.File]::Exists($previousManifestPath)) { throw 'installation_invalid' }
                [object] $previousManifest = [IO.File]::ReadAllText($previousManifestPath) | ConvertFrom-Json
                if ($previousManifest.name -ne 'hipohipo') { throw 'installation_invalid' }
            }
            [string] $packageWorkingDirectory = Split-Path (Split-Path $destination -Parent) -Parent
            $installStaging = Join-Path $packageWorkingDirectory ('.hipohipo-stage.' + [Guid]::NewGuid().ToString('N'))
            [void] [IO.Directory]::CreateDirectory($installStaging)
            Get-ChildItem -LiteralPath $pluginRoot -Force | Copy-Item -Destination $installStaging -Recurse -Force
            if ([IO.Directory]::Exists((Join-Path $installStaging 'bin'))) { Remove-Item -LiteralPath (Join-Path $installStaging 'bin') -Recurse -Force }
            [IO.File]::Delete((Join-Path $installStaging 'hipohipo.exe'))
            [string] $configuration = @{mcpServers = @{hipohipo = @{command = (Join-Path $destination 'hipohipo.cmd'); args = @('mcp'); cwd = $destination}}} | ConvertTo-Json -Depth 5
            [IO.File]::WriteAllText((Join-Path $installStaging 'mcp.json'), $configuration)
            [void] [IO.Directory]::CreateDirectory((Join-Path $installStaging 'hooks'))
            [hashtable] $hooks = @{}
            foreach ($hookEvent in @('sessionStart', 'beforeSubmitPrompt', 'afterAgentResponse', 'stop', 'sessionEnd')) {
                $hooks[$hookEvent] = @(@{command = ('cmd.exe /d /c call "' + (Join-Path $destination 'scripts\run.cmd') + '" hook --event ' + $hookEvent); timeout = 5})
            }
            [IO.File]::WriteAllText((Join-Path $installStaging ('hooks\' + $hookFile)), (@{version = 1; hooks = $hooks} | ConvertTo-Json -Depth 6))
            if ([IO.Directory]::Exists($destination)) {
                $installBackup = Join-Path $packageWorkingDirectory ('.hipohipo-backup.' + [Guid]::NewGuid().ToString('N'))
                [IO.Directory]::Move($destination, $installBackup)
            }
            [IO.Directory]::Move($installStaging, $destination)
            $installStaging = ''
            if ($installBackup.Length -gt 0) { Remove-Item -LiteralPath $installBackup -Recurse -Force; $installBackup = '' }
            [Console]::WriteLine('Installed local plugin: ' + $destination + ' (version ' + $packageManifest.version + ")`nContinue sign-in in this conversation through MCP or the installed CLI; check MCP access separately: https://raw.githubusercontent.com/Ontos-AI/hipohipo-plugins/main/install/README.md")
            @{installedVersion = $packageManifest.version; host = 'cursor'; installationDirectory = $destination; login = @{command = (Join-Path $destination 'hipohipo.cmd'); args = @('login', '--host', 'cursor')}} | ConvertTo-Json -Depth 4 -Compress
            exit 0
        }
        'runtime-status' { Write-RuntimeStatus; exit 0 }
        'auth-status' {
            if (-not (Test-RuntimeReady)) {
                [object] $status = Write-RuntimeStatus | ConvertFrom-Json
                @{status = 'runtime_not_prepared'; nextAction = $status.nextAction; operationExecuted = $false; message = 'Runtime is not prepared; authorization was not checked.'; runtime = $status} | ConvertTo-Json -Depth 6 -Compress
                exit 0
            }
        }
        { $_ -in @('runtime-prepare', 'runtime-retry', 'login', 'login-device') } {
            [int] $setupResult = Wait-SetupPreparation ($commandName -eq 'runtime-retry')
            if ($setupResult -ne 0) {
                Write-SetupStatus
                if ($setupResult -eq 1) { exit 1 }
                exit 0
            }
            if ($commandName -in @('runtime-prepare', 'runtime-retry')) { Write-RuntimeStatus; exit 0 }
        }
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
        '__runtime-prepare' { Initialize-Runtime ($RuntimeArguments.Count -gt 1 -and $RuntimeArguments[1] -eq 'explicit'); exit 0 }
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
    Assert-LoginTime
    $ErrorActionPreference = 'Continue'
    & $runtimePath '__runtime-run' @RuntimeArguments
    [int] $runtimeExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    exit $runtimeExit
}
catch {
    if ($_.Exception.Message -eq 'login_timeout') {
        @{status = 'setup_pending'; state = 'preparing'; nextAction = 'continue_setup'; lastErrorCode = 'login_timeout'; operationExecuted = $false; message = 'The total login deadline elapsed before authorization could execute. Continue the same login command.'} | ConvertTo-Json -Compress
        exit 0
    }
    if ($commandName -eq 'install') { [Console]::Error.WriteLine('Installation failed: ' + $_.Exception.Message) }
    [string] $code = 'bootstrap_error'
    if ($_.Exception.Message -match '^[a-z]+[a-z0-9_]*$') { $code = $_.Exception.Message }
    if ($hasPreparationLock) { try { Write-Failure $code } catch { } }
    if ($logPath.Length -gt 0) { Write-Diagnostic 'command_failed' 'failed' $code }
    if ($isHook) { Write-HookResponse; exit 0 }
    if ($code -eq 'invalid_arguments' -or $commandName -in @('runtime-status', 'auth-status', 'runtime-prepare', 'runtime-retry', 'login', 'login-device')) {
        @{state = 'failed'; nextAction = 'inspect_error'; lastErrorCode = $code; isReady = $false; operationExecuted = $false; logPath = $logPath} | ConvertTo-Json -Compress
    }
    [Console]::Error.WriteLine('Hipohipo bootstrap [' + $code + ']. Inspect this error before retrying; use runtime-retry only for an explicit preparation retry. Local log: ' + $logPath)
    exit 1
}
finally {
    if ($installBackup.Length -gt 0 -and [IO.Directory]::Exists($installBackup)) {
        try {
            if (-not (Test-Path -LiteralPath $destination)) { [IO.Directory]::Move($installBackup, $destination) }
            else { [Console]::Error.WriteLine('Previous package retained at ' + $installBackup) }
        } catch { [Console]::Error.WriteLine('Previous package retained at ' + $installBackup + '; restore failed: ' + $_.Exception.Message) }
    }
    if ($installStaging.Length -gt 0 -and [IO.Directory]::Exists($installStaging)) { Remove-Item -LiteralPath $installStaging -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -ne $installLock) { $installLock.Dispose() }
    if ($installLockPath.Length -gt 0) { [IO.File]::Delete($installLockPath) }

    Close-PreparationLock
}
