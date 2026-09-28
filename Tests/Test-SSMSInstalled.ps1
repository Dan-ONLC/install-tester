<#
.SYNOPSIS  Test: SQL Server Management Studio is installed.
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'SQL Server Management Studio installed'

try {
    $p = Get-InstalledProgram -NameLike "*SQL Server Management Studio*" | Select-Object -First 1
    $found = if ($p) { "$($p.DisplayName) $($p.DisplayVersion)" }
    if (-not $found) {
        $exe = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio*\Common7\IDE\Ssms.exe", "$env:ProgramFiles\Microsoft SQL Server Management Studio*\Common7\IDE\Ssms.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) { $found = $exe.FullName }
    }
    $passed  = [bool]$found
    $details = if ($found) { $found } else { 'not found' }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
