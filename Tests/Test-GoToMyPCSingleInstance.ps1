<#
.SYNOPSIS  Test: exactly one GoToMyPC instance is running (zero or more than one fails).
.PARAMETER ProcessName  Process to count, without .exe. Default g2host (the GoToMyPC host process).
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$ProcessName = 'g2host', [string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'Exactly one GoToMyPC instance running'

try {
    $count   = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue).Count
    $passed  = ($count -eq 1)
    $details = switch ($count) { 0 { "none running ('$ProcessName')" } 1 { "1 '$ProcessName' process" } default { "$count '$ProcessName' processes running (expected 1)" } }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
