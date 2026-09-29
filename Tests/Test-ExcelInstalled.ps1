<#
.SYNOPSIS  Test: Microsoft Excel is validly installed (registered, executable present, version readable).
.OUTPUTS   Result object; also sets $global:TestPassed.
#>
param([string]$LogPath)
. "$PSScriptRoot\TestCommon.ps1"
$testName = 'Excel installed (valid)'

try {
    # Registered executable path (covers MSI and Click-to-Run, 32/64-bit).
    $exe = $null
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe',
                   'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\excel.exe',
                   'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe') {
        $p = (Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).'(default)'
        if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { $exe = $p; break }
    }
    if (-not $exe) {
        $exe = Get-ChildItem "$env:ProgramFiles\Microsoft Office\root\Office*\EXCEL.EXE",
                             "${env:ProgramFiles(x86)}\Microsoft Office\root\Office*\EXCEL.EXE",
                             "$env:ProgramFiles\Microsoft Office\Office*\EXCEL.EXE",
                             "${env:ProgramFiles(x86)}\Microsoft Office\Office*\EXCEL.EXE" -ErrorAction SilentlyContinue |
               Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $exe) {
        $passed = $false; $details = 'EXCEL.EXE not found'
    } else {
        $ver = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
        if (-not $ver) { $passed = $false; $details = "$exe has no readable version (possibly corrupt)" }
        else {
            $passed = $true; $details = "$exe (version $ver)"
        }
    }
} catch { $passed = $false; $details = $_.Exception.Message }

Complete-Test -TestName $testName -Passed $passed -Details $details -LogPath $LogPath
