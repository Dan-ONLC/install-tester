<#
.SYNOPSIS  Test: a database with the given name exists on a SQL Server instance.
.PARAMETER DatabaseName    Database to look for (e.g. pub1, pub2, AdventureWorksDW2020).
.PARAMETER ServerInstance  Defaults to the local default instance ('.').
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param(
    [Parameter(Mandatory)][string]$DatabaseName,
    [string]$ServerInstance = '.',
    [string]$LogPath
)
. "$PSScriptRoot\TestCommon.ps1"
$testName = "SQL database '$DatabaseName' exists"

try {
    $rows = Invoke-SqlQuery -ServerInstance $ServerInstance -Query 'SELECT name FROM sys.databases WHERE name = @n' -Parameters @{ n = $DatabaseName }
    $passed  = ($rows.Count -gt 0)
    $details = if ($passed) { "found on $ServerInstance" } else { "not found on $ServerInstance" }
} catch { $passed = $false; $details = "query failed: $($_.Exception.Message)" }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
