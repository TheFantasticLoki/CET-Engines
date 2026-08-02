## Description

<!-- Provide a brief description of the changes in this PR -->

## Type of Change

<!-- Check the relevant option(s) -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Refactor (code restructuring without behavior change)
- [ ] Test update
- [ ] Chore (maintenance, cleanup, tooling)

## Related Issues

<!-- Link to related issues: Fixes #123, Relates to #456 -->

## Checklist

### Code Quality
- [ ] All code follows `docs/CODESTYLE.md` conventions
- [ ] No `goto`, `__gc`, `table.pack`, or `table.unpack` (Lua 5.1 only)
- [ ] All variables and functions are `local` (except `_G.UIEngine`)
- [ ] Module pattern: `local M = {} ... return M`
- [ ] No dead code left in the file
- [ ] No tabs — 4 spaces only
- [ ] No trailing whitespace
- [ ] Max line length 120 characters

### Testing
- [ ] Unit tests added for new modules in `tests/unit/`
- [ ] All existing tests still pass: `./scripts/test.sh`
- [ ] Test covers both success and error cases
- [ ] Theme push/pop balance tested if applicable

### Documentation
- [ ] `docs/API.md` updated if public API changed
- [ ] `docs/ARCHITECTURE.md` updated if module structure changed
- [ ] `docs/FILEMAP.md` updated if new files added
- [ ] `AGENTS.md` updated if guidelines changed

### CET Compatibility
- [ ] No Lua 5.2+ features used
- [ ] Cross-mod dependencies use `GetMod()`, not `require()`
- [ ] `onInit` is idempotent (safe to call multiple times)
- [ ] Event subscriptions are cleaned up on `Unregister()`

### Error Handling
- [ ] ImGui calls wrapped in pcall where needed
- [ ] No silent failures — all errors logged via Logger
- [ ] ErrorBoundary wraps mod draw functions
- [ ] Graceful degradation when modules fail to load

### Theme System
- [ ] `PushTheme()` always balanced with `PopTheme()`
- [ ] No direct ImGui style calls bypassing Theme engine
- [ ] Color combinations meet WCAG 2.0 contrast ratios

## Screenshots

<!-- If applicable, add screenshots to help explain your changes -->

## Additional Notes

<!-- Add any other context about the PR here -->
