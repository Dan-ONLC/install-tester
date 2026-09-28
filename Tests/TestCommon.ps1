# Shared helpers, dot-sourced by every test script and by the parent runner.

$script:PassIcon = [string][char]0x2714   # check mark
$script:FailIcon = [string][char]0x2718   # ballot X

function Get-DefaultLogPath {
    $dir = Join-Path (Split-Path -Parent $PSScriptRoot) 'logs'
    Join-Path $dir 'install-tests.log'
}

function Write-LogLine {
    param([string]$LogPath, [string]$Message)
    if (-not $LogPath) { $LogPath = Get-DefaultLogPath }
    $dir = Split-Path -Parent $LogPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $line = '{0:yyyy-MM-dd HH:mm:ss} [{1}] {2}' -f (Get-Date), $env:COMPUTERNAME, $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

# Prints the colored result, logs it, sets $global:TestPassed and returns a result object.
function Complete-Test {
    param(
        [Parameter(Mandatory)][string]$TestName,
        [Parameter(Mandatory)][bool]$Passed,
        [string]$Details = '',
        [string]$LogPath
    )
    if ($Passed) {
        Write-Host "  $script:PassIcon PASSED " -ForegroundColor Green -NoNewline
    } else {
        Write-Host "  $script:FailIcon FAILED " -ForegroundColor Red -NoNewline
    }
    Write-Host $TestName -NoNewline
    if ($Details) { Write-Host " - $Details" -ForegroundColor DarkGray } else { Write-Host '' }

    $outcome = if ($Passed) { 'Passed' } else { 'Failed' }
    $msg = "TEST $TestName : $outcome"
    if ($Details) { $msg += " ($Details)" }
    Write-LogLine -LogPath $LogPath -Message $msg

    $global:TestPassed = $Passed
    [pscustomobject]@{ TestName = $TestName; Passed = $Passed; Details = $Details }
}

# Finds installed programs (machine + per-user uninstall keys, 32/64-bit) whose DisplayName matches a wildcard.
function Get-InstalledProgram {
    param([Parameter(Mandatory)][string]$NameLike)
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like $NameLike } |
        Select-Object DisplayName, DisplayVersion, InstallLocation
}

# Runs a scalar/query against SQL Server with Windows auth; returns rows as objects.
function Invoke-SqlQuery {
    param(
        [Parameter(Mandatory)][string]$Query,
        [string]$ServerInstance = '.',
        [hashtable]$Parameters = @{}
    )
    $cs = "Server=$ServerInstance;Database=master;Integrated Security=True;Connect Timeout=10;TrustServerCertificate=True"
    $conn = New-Object System.Data.SqlClient.SqlConnection $cs
    try {
        $conn.Open()
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $Query
        foreach ($k in $Parameters.Keys) { [void]$cmd.Parameters.AddWithValue("@$k", $Parameters[$k]) }
        $table = New-Object System.Data.DataTable
        [void](New-Object System.Data.SqlClient.SqlDataAdapter $cmd).Fill($table)
        , $table.Rows
    } finally { $conn.Dispose() }
}
