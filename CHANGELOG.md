# Changelog

Version is recorded in the `VERSION` file (read by `Run-Tests.ps1` for the banner and log).
Follows [Semantic Versioning](https://semver.org): bump PATCH for fixes/tweaks to existing tests,
MINOR for new tests or features, MAJOR for breaking config/behavior changes. Update `VERSION`
and add an entry here with every change.

## [0.9.1] - 2026-09-30
### Added
- Startup banner ("ONLC Machine Configuration Tester") with version; version logged at run start.
- `VERSION` file and this changelog.
### Changed
- GoToMyPC tests now count `g2tray` processes (catches listening-but-not-connected and duplicate tray icons).

## [0.9.0] - 2026-09-29
### Added
- Initial tests: Power BI Desktop, SQL Server (installed / default instance running), SSMS, VS Code,
  Excel, SQL databases (pub1, pub2, AdventureWorksDW2020), file presence, GoToMyPC running / single instance.
- JSON-driven parent runner `Run-Tests.ps1` with overall result, console output and log file.
