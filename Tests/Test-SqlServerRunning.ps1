<#
.SYNOPSIS  Test: the default instance of SQL Server (MSSQLSERVER) is running.
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'Default SQL Server instance running'

try {
    $svc = Get-Service -Name 'MSSQLSERVER' -ErrorAction SilentlyContinue
    if (-not $svc) { $passed = $false; $details = 'service MSSQLSERVER not found (no default instance)' }
    else { $passed = ($svc.Status -eq 'Running'); $details = "service status: $($svc.Status)" }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
