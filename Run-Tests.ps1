<#
.SYNOPSIS  Parent runner: runs the test scripts listed in a JSON config and reports overall results.
.PARAMETER ConfigPath  JSON config file (default: tests.config.json next to this script).
.NOTES
  Sets $global:OverallResult to 'AllPassed', 'SomeFailed' or 'AllFailed' (and 'NoTests' if none ran).
  Also returns that string on the pipeline and exits 0 only when all tests passed.
#>
param([string]$ConfigPath = (Join-Path $PSScriptRoot 'tests.config.json'))

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Tests\TestCommon.ps1')

$config   = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$testsDir = if ($config.testsDirectory) { $config.testsDirectory } else { 'Tests' }
if (-not [System.IO.Path]::IsPathRooted($testsDir)) { $testsDir = Join-Path $PSScriptRoot $testsDir }
$logPath  = if ($config.logPath) { $config.logPath } else { Get-DefaultLogPath }
if (-not [System.IO.Path]::IsPathRooted($logPath)) { $logPath = Join-Path $PSScriptRoot $logPath }

Write-Host "`nRunning install tests (config: $ConfigPath)" -ForegroundColor Cyan
Write-LogLine -LogPath $logPath -Message "===== RUN START (config: $ConfigPath) ====="

$results = @()
foreach ($t in $config.tests) {
    if ($t.PSObject.Properties['enabled'] -and -not $t.enabled) { continue }

    # Convert the JSON "arguments" object into a splattable hashtable.
    $splat = @{}
    if ($t.arguments) { $t.arguments.PSObject.Properties | ForEach-Object { $splat[$_.Name] = $_.Value } }
    $splat['LogPath'] = $logPath

    $scriptPath = Join-Path $testsDir $t.script
    $label = if ($t.name) { $t.name } else { $t.script }
    try {
        $r = & $scriptPath @splat | Where-Object { $_ -and $_.PSObject.Properties['Passed'] } | Select-Object -Last 1
        if (-not $r) { throw "script produced no result object" }
    } catch {
        $r = Complete-Test -TestName $label -Passed $false -Details "script error: $($_.Exception.Message)" -LogPath $logPath
    }
    $results += $r
}

$passCount = @($results | Where-Object { $_.Passed }).Count
$failCount = $results.Count - $passCount

if     ($results.Count -eq 0) { $overall = 'NoTests';    $color = 'Yellow'; $text = 'No tests were run' }
elseif ($failCount -eq 0)     { $overall = 'AllPassed';  $color = 'Green';  $text = "$script:PassIcon ALL TESTS PASSED ($passCount/$($results.Count))" }
elseif ($passCount -eq 0)     { $overall = 'AllFailed';  $color = 'Red';    $text = "$script:FailIcon ALL TESTS FAILED (0/$($results.Count) passed)" }
else                          { $overall = 'SomeFailed'; $color = 'Yellow'; $text = "! SOME TESTS FAILED ($passCount passed, $failCount failed)" }

Write-Host "`n$text" -ForegroundColor $color
Write-LogLine -LogPath $logPath -Message "OVERALL: $overall ($passCount passed, $failCount failed of $($results.Count))"
Write-LogLine -LogPath $logPath -Message "===== RUN END ====="

$global:OverallResult = $overall
$overall
if ($MyInvocation.InvocationName -ne '.' -and $overall -ne 'AllPassed') { exit 1 }
