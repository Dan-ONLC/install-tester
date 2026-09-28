<#
.SYNOPSIS  Test: SQL Server instance is installed.
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'SQL Server instance installed'

try {
    $reg = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
    $names = if (Test-Path $reg) { (Get-Item $reg).Property } else { @() }
    $found = if ($names) { "instance(s): " + ($names -join ", ") }
    if (-not $found) {
        $svc = Get-Service -Name "MSSQL`$*", "MSSQLSERVER" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($svc) { $found = "service $($svc.Name)" }
    }
    $passed  = [bool]$found
    $details = if ($found) { $found } else { 'not found' }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
