<#
.SYNOPSIS  Test: VS Code is installed.
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'VS Code installed'

try {
    $p = Get-InstalledProgram -NameLike "*Microsoft Visual Studio Code*" | Select-Object -First 1
    $found = if ($p) { "$($p.DisplayName) $($p.DisplayVersion)" }
    if (-not $found) {
        $exe = @("$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($exe) { $found = $exe }
    }
    $passed  = [bool]$found
    $details = if ($found) { $found } else { 'not found' }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
