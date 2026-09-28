<#
.SYNOPSIS  Test: expected files exist under a directory.
.PARAMETER Path          Root directory.
.PARAMETER ExpectedFiles Relative paths (e.g. 'data\a.csv','docs\readme.txt') that must exist under Path.
                         If omitted, the test requires Path to exist and contain at least one file (recursively).
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param(
    [Parameter(Mandatory)][string]$Path,
    [string[]]$ExpectedFiles,
    [string]$LogPath
)
. "$PSScriptRoot\TestCommon.ps1"
$testName = "Files present in '$Path'"

try {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        $passed = $false; $details = 'directory not found'
    } elseif ($ExpectedFiles) {
        $missing = @($ExpectedFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Path $_) -PathType Leaf) })
        $passed  = ($missing.Count -eq 0)
        $details = if ($passed) { "all $($ExpectedFiles.Count) expected file(s) found" } else { "missing: " + ($missing -join ', ') }
    } else {
        $count   = @(Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction Stop).Count
        $passed  = ($count -gt 0)
        $details = "$count file(s) found"
    }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
