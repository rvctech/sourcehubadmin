# Aesthetic improvements TODO

- [x] Update `lib/core/theme.dart` to add missing global theming (AppBarTheme, SnackBarTheme, DividerTheme, listTileTheme/card polish, text button styles, etc.).
- [x] Refactor `lib/features/dashboard/dashboard_view.dart`:
  - [x] Remove hardcoded text styles/colors where possible
  - [x] Reuse `Theme.of(context)` tokens (`colorScheme`, `textTheme`)
  - [x] Make stat cards use theme-consistent `Card`/`Surface` styling
- [ ] (Next after dashboard) Audit one screen + one dialog per feature area to remove duplicated styling.
- [x] Run `flutter analyze` and `flutter test` (if available) and visually verify light/dark mode consistency.
- [x] Resolve any analyzer warnings reported in `analysis_report.txt`
- [x] Rerun `flutter analyze` until clean (no warnings)
