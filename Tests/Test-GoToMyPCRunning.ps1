<#
.SYNOPSIS  Test: GoToMyPC is running (at least one host process).
.PARAMETER ProcessName  Process to look for, without .exe. Default g2tray (the GoToMyPC tray icon process; one per tray icon, so it also shows instances that are listening but not yet connected).
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$ProcessName = 'g2tray', [string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'GoToMyPC running'

try {
    $count   = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue).Count
    $passed  = ($count -ge 1)
    $details = "$count '$ProcessName' process(es) running"
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
