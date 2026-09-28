<#
.SYNOPSIS  Test: Power BI Desktop is installed.
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'Power BI Desktop installed'

try {
    $p = Get-InstalledProgram -NameLike "*Power BI Desktop*" | Select-Object -First 1
    $found = if ($p) { "$($p.DisplayName) $($p.DisplayVersion)" }
    if (-not $found) {   # Microsoft Store edition
        $pkg = Get-AppxPackage -Name "Microsoft.MicrosoftPowerBIDesktop" -AllUsers -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pkg) { $found = "Store package $($pkg.Version)" }
    }
    $passed  = [bool]$found
    $details = if ($found) { $found } else { 'not found' }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
