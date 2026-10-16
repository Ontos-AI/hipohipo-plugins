# Cold-start MCP transport adapter. Business tools stay in the verified runtime.
function Get-McpProperty([object] $value, [string] $name) {
    if ($null -eq $value) { return $null }
    [object] $property = $value.PSObject.Properties | Where-Object { $_.Name -ceq $name } | Select-Object -First 1
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Write-McpResult([object] $identifier, [object] $result, [string] $version = '') {
    if ($version -eq '2026-07-28') {
        $result.resultType = 'complete'
        $result.ttlMs = 0
        $result.cacheScope = 'private'
        $result._meta = @{'io.modelcontextprotocol/serverInfo' = @{name = 'hipohipo-plugin'; version = $manifest.runtimeVersion}}
    }
    [Console]::WriteLine((@{jsonrpc = '2.0'; id = $identifier; result = $result} | ConvertTo-Json -Depth 64 -Compress))
}

function Write-McpError([object] $identifier, [int] $code, [string] $message) {
    [Console]::WriteLine((@{jsonrpc = '2.0'; id = $identifier; error = @{code = $code; message = $message}} | ConvertTo-Json -Depth 8 -Compress))
}

function ConvertTo-McpProcessArgument([string] $value) {
    # Windows native command-line quoting, including quotes and trailing slashes.
    return '"' + [regex]::Replace([regex]::Replace($value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}

function Stop-McpRuntime {
    if ($null -ne $script:mcpRuntime) {
        try {
            if (-not $script:mcpRuntime.HasExited) {
                try {
                    if ($null -ne $script:mcpRuntimeInput) { $script:mcpRuntimeInput.Close() }
                    else { $script:mcpRuntime.StandardInput.Close() }
                } catch { }
                if (-not $script:mcpRuntime.WaitForExit(2000)) { $script:mcpRuntime.Kill(); [void] $script:mcpRuntime.WaitForExit(2000) }
            }
        } catch { }
        # A child can close stdout immediately after writing its startup error.
        # Drain completed stderr reads before disposal loses those diagnostics.
        try {
            if ($null -ne $script:mcpErrorOutput -and $script:mcpErrorOutput.Wait(100)) {
                [object] $errorFrame = $script:mcpErrorOutput.GetAwaiter().GetResult()
                if ($null -ne $errorFrame) { [Console]::Error.WriteLine([string] $errorFrame) }
                [object] $remainingErrors = $script:mcpRuntime.StandardError.ReadToEndAsync()
                if ($remainingErrors.Wait(100)) { [Console]::Error.Write([string] $remainingErrors.GetAwaiter().GetResult()) }
            }
        } catch { }
        $script:mcpRuntime.Dispose()
    }
    $script:mcpRuntime = $null
    $script:mcpRuntimeInput = $null
    $script:mcpOutput = $null
    $script:mcpErrorOutput = $null
    $script:mcpRuntimeState = 'stopped'
}

function Set-McpRuntimeFailure([string] $code) {
    $script:mcpRuntimeError = $code
    $script:mcpRetryAt = [DateTime]::UtcNow.AddSeconds(180)
    Stop-McpRuntime
    foreach ($key in @($script:mcpForwarded.Keys)) {
        Write-McpError $script:mcpForwarded[$key] -32000 'Runtime stopped; the connection will retry automatically after three minutes'
    }
    $script:mcpForwarded.Clear()
    Write-Diagnostic 'mcp_runtime_failed' 'failed' $code
    Complete-McpWaits
    [Console]::WriteLine('{"jsonrpc":"2.0","method":"notifications/tools/list_changed"}')
}

function Send-McpRuntimeFrame([string] $frame) {
    try { $script:mcpRuntimeInput.WriteLine($frame) }
    catch { Set-McpRuntimeFailure 'runtime_process_closed' }
}

function Start-McpRuntime {
    if ($script:mcpRuntimeState -ne 'stopped' -or $script:mcpRuntimeError.Length -gt 0 -or $script:mcpInitialization.Length -eq 0 -or -not (Test-RuntimeReady)) { return }
    try {
        [Diagnostics.ProcessStartInfo] $start = New-Object Diagnostics.ProcessStartInfo
        $start.FileName = $runtimePath
        $start.Arguments = ((@('__runtime-run') + $RuntimeArguments | ForEach-Object { ConvertTo-McpProcessArgument $_ }) -join ' ')
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardInput = $true
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        $start.StandardOutputEncoding = New-Object Text.UTF8Encoding $false
        $start.StandardErrorEncoding = New-Object Text.UTF8Encoding $false
        # .NET Framework creates an AutoFlush stdin writer during Process.Start.
        # A UTF-8 console encoding with a BOM writes it before our first frame.
        [Console]::InputEncoding = New-Object Text.UTF8Encoding $false
        $script:mcpRuntime = [Diagnostics.Process]::Start($start)
        # .NET Framework's default StandardInput writer uses the console code
        # page. The MCP wire must stay UTF-8 even on Chinese Windows profiles.
        $script:mcpRuntimeInput = New-Object IO.StreamWriter($script:mcpRuntime.StandardInput.BaseStream, (New-Object Text.UTF8Encoding $false))
        $script:mcpRuntimeInput.AutoFlush = $true
        $script:mcpRuntimeInput.WriteLine($script:mcpInitialization)
        $script:mcpOutput = $script:mcpRuntime.StandardOutput.ReadLineAsync()
        $script:mcpErrorOutput = $script:mcpRuntime.StandardError.ReadLineAsync()
        $script:mcpRuntimeState = 'initializing'
        $script:mcpRuntimeDeadline = [DateTime]::UtcNow.AddSeconds(10)
        $script:mcpRuntimeError = ''
        Write-Diagnostic 'mcp_runtime_started' 'started'
    } catch {
        Set-McpRuntimeFailure 'runtime_start_failed'
    }
}

function Complete-McpWaits {
    [DateTime] $now = [DateTime]::UtcNow
    foreach ($key in @($script:mcpPending.Keys)) {
        [object] $pending = $script:mcpPending[$key]
        [string] $state = 'preparing'
        [bool] $hasError = $false
        if ($script:mcpRuntimeState -eq 'ready') { $state = 'ready' }
        elseif ($script:mcpRuntimeError.Length -gt 0 -or (Test-Cooldown)) { $state = 'failed'; $hasError = $true }
        elseif ($now -lt $pending.deadline) {
            [int] $elapsed = [int] [Math]::Floor(($now - $pending.started).TotalSeconds)
            if ($null -ne $pending.progressToken -and $elapsed -gt $pending.lastProgress) {
                [Console]::WriteLine((@{jsonrpc = '2.0'; method = 'notifications/progress'; params = @{progressToken = $pending.progressToken; progress = $elapsed; total = 30; message = 'Preparing the Hipohipo runtime'}} | ConvertTo-Json -Depth 8 -Compress))
                $pending.lastProgress = $elapsed
            }
            continue
        }
        [object] $status = Write-RuntimeStatus | ConvertFrom-Json
        $status | Add-Member -NotePropertyName state -NotePropertyValue $state
        $status | Add-Member -NotePropertyName waitTimeoutSeconds -NotePropertyValue 30
        $status | Add-Member -NotePropertyName backendErrorCode -NotePropertyValue $script:mcpRuntimeError
        $status | Add-Member -NotePropertyName retryIntervalSeconds -NotePropertyValue 180
        $status | Add-Member -NotePropertyName backendRetryEligibleAt -NotePropertyValue $(if ($script:mcpRuntimeError.Length -gt 0) { $script:mcpRetryAt.ToString('o') } else { $null })
        [string] $message = 'Runtime is still preparing after this bounded wait. Preparation continues in the background. Retry runtime_status later; do not reconnect MCP.'
        if ($state -eq 'ready') { $message = 'Runtime is ready. Refresh tools/list and continue without reconnecting MCP.' }
        if ($state -eq 'failed') { $message = 'Runtime preparation or startup failed. The live MCP connection retries automatically three minutes after failure. Calls share the same download and cooldown. Inspect the error and log path below.' }
        Write-McpResult $pending.id @{content = @(@{type = 'text'; text = $message + ' ' + ($status | ConvertTo-Json -Depth 8 -Compress)}); structuredContent = $status; isError = $hasError} $pending.version
        $script:mcpPending.Remove($key)
    }
}

function Invoke-McpClientFrame([string] $frame) {
    [object] $request = $null
    if ($frame.Length -gt 32000000) { Write-McpError $null -32700 'JSON frame exceeds the size limit'; return }
    try { $request = $frame | ConvertFrom-Json } catch { Write-McpError $null -32700 'Invalid JSON'; return }
    [object] $identifier = Get-McpProperty $request 'id'
    [object] $methodValue = Get-McpProperty $request 'method'
    [object] $parameters = Get-McpProperty $request 'params'
    [object] $metadata = Get-McpProperty $parameters '_meta'
    [object] $progressToken = Get-McpProperty $metadata 'progressToken'
    if ($request -isnot [Management.Automation.PSCustomObject] -or ($null -ne $methodValue -and $methodValue -isnot [string]) -or ($null -ne $parameters -and $parameters -isnot [Management.Automation.PSCustomObject]) -or ($null -ne $metadata -and $metadata -isnot [Management.Automation.PSCustomObject]) -or ($null -ne $progressToken -and $progressToken -isnot [string] -and $progressToken -isnot [int] -and $progressToken -isnot [long] -and $progressToken -isnot [double] -and $progressToken -isnot [decimal])) {
        Write-McpError $null -32600 'Invalid JSON-RPC frame'; return
    }
    [string] $method = $methodValue
    [string] $version = Get-McpProperty $metadata 'io.modelcontextprotocol/protocolVersion'
    if ((Get-McpProperty $request 'jsonrpc') -cne '2.0' -or ($null -ne $identifier -and $identifier -isnot [string] -and $identifier -isnot [int] -and $identifier -isnot [long])) {
        Write-McpError $null -32600 'Invalid JSON-RPC frame'; return
    }
    if ($version.Length -gt 0 -and $version -cne '2026-07-28') { Write-McpError $identifier -32022 'Unsupported protocol version'; return }
    if ($version -ceq '2026-07-28' -and $script:mcpInitialization.Length -eq 0) {
        $script:mcpInitializationMethod = 'server/discover'
        $script:mcpInitialization = '{"jsonrpc":"2.0","id":"hipohipo.bootstrap.initialize","method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}}'
    }
    switch ($method) {
        'server/discover' {
            if ($script:mcpInitialization.Length -eq 0) {
                $request.id = 'hipohipo.bootstrap.initialize'
                $script:mcpInitialization = $request | ConvertTo-Json -Depth 64 -Compress
                $script:mcpInitializationMethod = 'server/discover'
            }
            Write-McpResult $identifier @{supportedVersions = $script:mcpDescriptor.protocolVersions; capabilities = $script:mcpDescriptor.capabilities; instructions = $script:mcpDescriptor.instructions} '2026-07-28'
            Start-McpRuntime
            return
        }
        'initialize' {
            if ($script:mcpInitialization.Length -gt 0) { Write-McpError $identifier -32600 'MCP is already initialized'; return }
            [string] $protocol = Get-McpProperty $parameters 'protocolVersion'
            if ($protocol -notin @('2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05', '2024-10-07')) { $protocol = '2025-11-25' }
            $request.id = 'hipohipo.bootstrap.initialize'
            $script:mcpInitialization = $request | ConvertTo-Json -Depth 64 -Compress
            $script:mcpInitializationMethod = 'initialize'
            $script:mcpNegotiatedVersion = $protocol
            Write-McpResult $identifier @{protocolVersion = $protocol; capabilities = $script:mcpDescriptor.capabilities; serverInfo = @{name = 'hipohipo-plugin'; version = $manifest.runtimeVersion}; instructions = $script:mcpDescriptor.instructions}
            Start-McpRuntime
            return
        }
        'notifications/initialized' {
            $script:mcpHasInitialized = $true
            if ($script:mcpRuntimeState -eq 'ready') { Send-McpRuntimeFrame $frame }
            return
        }
        'notifications/cancelled' {
            [string] $cancelledKey = (Get-McpProperty $parameters 'requestId') | ConvertTo-Json -Compress
            $script:mcpPending.Remove($cancelledKey)
            $script:mcpForwarded.Remove($cancelledKey)
            if ($script:mcpRuntimeState -eq 'ready') { Send-McpRuntimeFrame $frame }
            return
        }
        'ping' { Write-McpResult $identifier @{} $version; return }
        'tools/call' {
            [string] $name = Get-McpProperty $parameters 'name'
            if ($name -in @('runtime_prepare', 'runtime_status')) {
                [string] $key = $identifier | ConvertTo-Json -Compress
                if ($null -eq $identifier -or $script:mcpPending.ContainsKey($key) -or $script:mcpPending.Count -ge 16) { Write-McpError $identifier -32600 'Invalid or duplicate preparation request'; return }
                [object] $arguments = Get-McpProperty $parameters 'arguments'
                if ($null -ne $arguments -and ($arguments -isnot [Management.Automation.PSCustomObject] -or @($arguments.PSObject.Properties).Count -ne 0)) { Write-McpError $identifier -32602 'Preparation tools accept an empty arguments object'; return }
                try { Start-Preparation } catch { }
                if ($script:mcpRuntimeError.Length -eq 0) { Start-McpRuntime }
                [DateTime] $started = [DateTime]::UtcNow
                $script:mcpPending[$key] = @{id = $identifier; progressToken = (Get-McpProperty $metadata 'progressToken'); started = $started; deadline = $started.AddSeconds(30); version = $version; lastProgress = -1}
                Complete-McpWaits
                return
            }
        }
    }
    if ($script:mcpRuntimeState -eq 'ready') {
        if ($method.Length -gt 0 -and $null -ne $identifier) { $script:mcpForwarded[($identifier | ConvertTo-Json -Compress)] = $identifier }
        Send-McpRuntimeFrame $frame
        return
    }
    if ($null -eq $identifier) { return }
    switch ($method) {
        'tools/list' { Write-McpResult $identifier @{tools = $script:mcpDescriptor.tools} $version }
        'resources/list' { Write-McpResult $identifier @{resources = @()} $version }
        'resources/templates/list' { Write-McpResult $identifier @{resourceTemplates = @()} $version }
        default { Write-McpError $identifier -32601 'Runtime is not ready; call runtime_prepare or runtime_status' }
    }
}

function Receive-McpRuntimeFrame([string] $frame) {
    [object] $response = $null
    try { $response = $frame | ConvertFrom-Json } catch { Set-McpRuntimeFailure 'runtime_invalid_response'; return }
    [string] $key = (Get-McpProperty $response 'id') | ConvertTo-Json -Compress
    if ($script:mcpRuntimeState -eq 'initializing' -and $key -eq '"hipohipo.bootstrap.initialize"' -and $null -eq (Get-McpProperty $response 'method')) {
        [object] $result = Get-McpProperty $response 'result'
        [object] $capabilities = Get-McpProperty $result 'capabilities'
        [object] $tools = Get-McpProperty $capabilities 'tools'
        [object] $resources = Get-McpProperty $capabilities 'resources'
        if ($null -ne (Get-McpProperty $response 'error')) { Set-McpRuntimeFailure 'runtime_initialize_failed' }
        elseif ((Get-McpProperty $tools 'listChanged') -ne $true -or (Get-McpProperty $resources 'subscribe') -ne $true -or (Get-McpProperty $resources 'listChanged') -ne $false -or ($script:mcpInitializationMethod -eq 'initialize' -and (Get-McpProperty $result 'protocolVersion') -cne $script:mcpNegotiatedVersion)) { Set-McpRuntimeFailure 'runtime_protocol_mismatch' }
        else {
            $script:mcpRuntimeState = 'ready'
            if ($script:mcpHasInitialized) { Send-McpRuntimeFrame '{"jsonrpc":"2.0","method":"notifications/initialized"}' }
            [Console]::WriteLine('{"jsonrpc":"2.0","method":"notifications/tools/list_changed"}')
            Write-Diagnostic 'mcp_runtime_ready' 'success'
        }
        Complete-McpWaits
        return
    }
    if ($null -eq (Get-McpProperty $response 'method')) { $script:mcpForwarded.Remove($key) }
    [Console]::WriteLine($frame)
}

function Start-McpBootstrap {
    $script:mcpDescriptor = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'mcp-bootstrap.json')) | ConvertFrom-Json
    $script:mcpRuntime = $null
    $script:mcpRuntimeInput = $null
    $script:mcpOutput = $null
    $script:mcpErrorOutput = $null
    $script:mcpRuntimeState = 'stopped'
    $script:mcpRuntimeError = ''
    $script:mcpInitialization = ''
    $script:mcpInitializationMethod = ''
    $script:mcpNegotiatedVersion = ''
    $script:mcpRetryAt = [DateTime]::UtcNow
    $script:mcpHasInitialized = $false
    $script:mcpPending = @{}
    $script:mcpForwarded = @{}
    [IO.StreamReader] $inputReader = New-Object IO.StreamReader([Console]::OpenStandardInput(), (New-Object Text.UTF8Encoding $false), $true, 65536)
    [object] $inputFrame = $inputReader.ReadLineAsync()
    [DateTime] $nextTick = [DateTime]::UtcNow
    try {
        try { Start-Preparation } catch { }
        Write-Diagnostic 'mcp_bootstrap_started' 'success'
        while ($true) {
            if ($inputFrame.IsCompleted) {
                [object] $frame = $inputFrame.GetAwaiter().GetResult()
                if ($null -eq $frame) { return }
                Invoke-McpClientFrame ([string] $frame)
                $inputFrame = $inputReader.ReadLineAsync()
            }
            if ($null -ne $script:mcpOutput -and $script:mcpOutput.IsCompleted) {
                [object] $runtimeFrame = $script:mcpOutput.GetAwaiter().GetResult()
                if ($null -eq $runtimeFrame) {
                    Set-McpRuntimeFailure 'runtime_process_closed'
                } else {
                    Receive-McpRuntimeFrame ([string] $runtimeFrame)
                    if ($null -ne $script:mcpRuntime) { $script:mcpOutput = $script:mcpRuntime.StandardOutput.ReadLineAsync() }
                }
            }
            if ($null -ne $script:mcpErrorOutput -and $script:mcpErrorOutput.IsCompleted) {
                [object] $errorFrame = $script:mcpErrorOutput.GetAwaiter().GetResult()
                if ($null -ne $errorFrame) { [Console]::Error.WriteLine([string] $errorFrame); $script:mcpErrorOutput = $script:mcpRuntime.StandardError.ReadLineAsync() }
                else { $script:mcpErrorOutput = $null }
            }
            if ([DateTime]::UtcNow -ge $nextTick) {
                if ($script:mcpRuntimeState -eq 'initializing' -and [DateTime]::UtcNow -ge $script:mcpRuntimeDeadline) { Set-McpRuntimeFailure 'runtime_initialize_timeout' }
                if ($script:mcpRuntimeError.Length -gt 0 -and [DateTime]::UtcNow -ge $script:mcpRetryAt) { $script:mcpRuntimeError = '' }
                if ($script:mcpRuntimeError.Length -eq 0 -and $script:mcpRuntimeState -eq 'stopped') {
                    try { Start-Preparation } catch { }
                    Start-McpRuntime
                }
                Complete-McpWaits
                $nextTick = [DateTime]::UtcNow.AddSeconds(1)
            }
            Start-Sleep -Milliseconds 20
        }
    } finally { Stop-McpRuntime; $inputReader.Dispose() }
}
