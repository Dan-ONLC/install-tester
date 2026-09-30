# install-tester

Modular PowerShell checks for a Windows machine (works in Windows PowerShell 5.1 and PowerShell 7).

- `VERSION` / `CHANGELOG.md` – current version (shown in the banner and log) and release history; bump both with each change.
- `Run-Tests.ps1 [-ConfigPath tests.config.json] [-NoPause]` – parent runner. Reads the JSON config, runs each enabled test,
  prints AllPassed / SomeFailed / AllFailed, sets `$global:OverallResult`, logs to `logPath`, exits 1 unless all passed.
- `Tests/Test-*.ps1` – one condition each. Each prints a colored PASSED/FAILED line, sets `$global:TestPassed`,
  appends to the log, and returns `{TestName, Passed, Details}`. Run standalone, e.g.
  `.\Tests\Test-SqlDatabaseExists.ps1 -DatabaseName pub1` or `.\Tests\Test-FilesPresent.ps1 -Path C:\CourseFiles`.
- `Tests/TestCommon.ps1` – shared helpers.

Config: each entry has `script`, optional `name`, `enabled` (default true) and `arguments` (object passed as named
parameters). New tests = drop a script in `Tests/` that dot-sources `TestCommon.ps1` and ends with `Complete-Test`, then list it in the config.
The SQL tests use Windows authentication against `.` unless `ServerInstance` is given in `arguments`. See the sample file, `tests-config.json` 
for reference.
