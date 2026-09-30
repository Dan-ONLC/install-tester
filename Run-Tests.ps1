<#
.SYNOPSIS  Parent runner: runs the test scripts listed in a JSON config and reports overall results.
.PARAMETER ConfigPath  JSON config file (default: tests.config.json next to this script).
.PARAMETER NoPause     Skip the final "Press any key to continue" prompt (for unattended/scheduled runs).
.NOTES
  Sets $global:OverallResult to 'AllPassed', 'SomeFailed' or 'AllFailed' (and 'NoTests' if none ran).
  Also returns that string on the pipeline and exits 0 only when all tests passed.
#>
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'tests.config.json'),
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Tests\TestCommon.ps1')

$versionFile = Join-Path $PSScriptRoot 'VERSION'
$version = if (Test-Path -LiteralPath $versionFile) { (Get-Content -LiteralPath $versionFile -Raw).Trim() } else { 'unknown' }
$global:TesterVersion = $version

function Show-Banner {
    param([string]$Version)
    $title = 'ONLC Machine Configuration Tester'
    $sub   = "Version $Version"
    $width = 54
    $h = [string][char]0x2550; $v = [string][char]0x2551
    $tl = [string][char]0x2554; $tr = [string][char]0x2557; $bl = [string][char]0x255A; $br = [string][char]0x255D
    $rainbow = 'Red','Yellow','Green','Cyan','Blue','Magenta'
    $center = { param($t) $l = [int][math]::Floor(($width - $t.Length) / 2); (' ' * $l) + $t + (' ' * ($width - $t.Length - $l)) }

    Write-Host ''
    Write-Host ($tl + ($h * $width) + $tr) -ForegroundColor Cyan
    Write-Host $v -ForegroundColor Cyan -NoNewline
    Write-Host (& $center '') -NoNewline
    Write-Host $v -ForegroundColor Cyan
    Write-Host $v -ForegroundColor Cyan -NoNewline
    # Title: one color per character, cycling through the rainbow.
    $padded = & $center $title
    $i = 0
    foreach ($ch in $padded.ToCharArray()) {
        if ($ch -eq ' ') { Write-Host ' ' -NoNewline }
        else { Write-Host $ch -ForegroundColor $rainbow[$i % $rainbow.Count] -NoNewline; $i++ }
    }
    Write-Host $v -ForegroundColor Cyan
    Write-Host $v -ForegroundColor Cyan -NoNewline
    Write-Host (& $center $sub) -ForegroundColor Yellow -NoNewline
    Write-Host $v -ForegroundColor Cyan
    Write-Host $v -ForegroundColor Cyan -NoNewline
    Write-Host (& $center '') -NoNewline
    Write-Host $v -ForegroundColor Cyan
    Write-Host ($bl + ($h * $width) + $br) -ForegroundColor Cyan
}

Show-Banner -Version $version

$config   = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$testsDir = if ($config.testsDirectory) { $config.testsDirectory } else { 'Tests' }
if (-not [System.IO.Path]::IsPathRooted($testsDir)) { $testsDir = Join-Path $PSScriptRoot $testsDir }
$logPath  = if ($config.logPath) { $config.logPath } else { Get-DefaultLogPath }
if (-not [System.IO.Path]::IsPathRooted($logPath)) { $logPath = Join-Path $PSScriptRoot $logPath }

Write-Host "Running install tests (config: $ConfigPath)" -ForegroundColor Cyan
Write-LogLine -LogPath $logPath -Message "===== RUN START (ONLC Machine Configuration Tester v$version; config: $ConfigPath) ====="

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

if (-not $NoPause) {
    Write-Host "`nPress any key to continue . . ." -ForegroundColor Cyan -NoNewline
    try { [void]$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }
    catch { [void](Read-Host) }   # hosts without raw key input (e.g. ISE): require Enter instead
    Write-Host ''
}

if ($MyInvocation.InvocationName -ne '.' -and $overall -ne 'AllPassed') { exit 1 }
