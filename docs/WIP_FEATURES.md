# Dead Code Cleanup — Status & WIP Features

> **Purpose:** Documents what was removed, what was preserved (with reasons), and what WIP features remain.

---

## Cleanup Summary

**Net lines removed: ~724** across 19 files. `config/default_config.lua` deleted entirely.

### What Was Genuinely Dead (Removed)

| Area | Functions Removed | Lines Saved |
|------|-------------------|-------------|
| `config/default_config.lua` | Entire file (1 file) | ~99 |
| `ui/color_engine.lua` | `IsWCAGCompliant`, `GeneratePalette`, `AdjustBrightness`, `AdjustSaturation`, `Blend`, `WithAlpha`, `IsValidColor`, `ClampColor` | ~162 |
| `ui/theme.lua` | `GetContrastReport`, `ImportTheme`, `STYLE_COLOR_COUNT`, `STYLE_VAR_COUNT` | ~88 |
| `ui/tokens.lua` | Class doc annotations cleanup | ~2 |
| `ui/utils.lua` | `CETWorkaround`, `MergeTables`, `FormatColor`, `ValidateComponentParams` | ~87 |
| `ui/components/` | `GetLastBounds`, `UpdateLastBounds`, `CenteredText`, `Count` (glyphs), `GetNames` (glyphs), `_diagAdvLoaded`, `_diagAdvSlider` | ~85 |
| `cfg/core.lua` | `getModsByCategory`, `isSettingsPanelOpen`, `toggleSettingsPanel`, `isWikiViewerOpen`, `openWikiViewer`, `closeWikiViewer`, `addModTag`, `removeModTag`, `hasModTag` | ~105 |
| `cfg/mod_manager.lua` | `getModCount`, `enable`, `disable`, `setPinned`, `setFavorite` | ~48 |
| `cfg/test_results.lua` | `getHistory`, `clear`, `clearAll` | ~22 |
| `cfg/test_runner.lua` | `startupComplete`, `resetStartup` | ~12 |
| `api/windows.lua` | `windowOpen` unused variable | ~1 |

### What Was Preserved (Tests Use Them — Remove When Tests Are Rewritten)

These functions are technically "dead" in production code but are called by the current test suite. **Remove these when tests are rewritten.**

| Function | File | Reason Preserved |
|----------|------|------------------|
| `UndoRedo.getUndoDescription()` | `cfg/undo_redo.lua` | Used by `configengine_undo_redo_test` |
| `UndoRedo.getRedoDescription()` | `cfg/undo_redo.lua` | Used by `configengine_undo_redo_test` |
| `UndoRedo.getUndoCount()` | `cfg/undo_redo.lua` | Used by `configengine_undo_redo_test` |
| `UndoRedo.getRedoCount()` | `cfg/undo_redo.lua` | Used by `configengine_undo_redo_test` |
| `Core.getSettingsVersion()` | `core.lua` | Used by `core_test` |
| `Core.setSettingsVersion()` | `core.lua` | Used by `core_test` |
| `Core.isDetached()` | `cfg/core.lua` | Used by `configengine_core_test` |
| `Logger.Clear()` | `modules/logger.lua` | Used by all `logger_test` tests |
| `Logger.SetFrame()` | `modules/logger.lua` | Used by `logger_test` |
| `Logger.SetLevel()` | `modules/logger.lua` | Used by `logger_test` |
| `Logger.GetLevel()` | `modules/logger.lua` | Used by `logger_test` |
| `Logger.GetEntries()` | `modules/logger.lua` | Used by `logger_test` |
| `Logger.SetOverlay()` | `modules/logger.lua` | Used by `logger_test` |
| `Logger.IsOverlayEnabled()` | `modules/logger.lua` | Used by `logger_test` |
| `Logger.SetMaxDebugPerFrame()` | `modules/logger.lua` | Used by `logger_test` |
| `Logger.GetMaxDebugPerFrame()` | `modules/logger.lua` | Used by `logger_test` |
| `Display.InfoRow()` | `ui/components/display.lua` | Used by `display_test` |
| `Display.Notification()` | `ui/components/display.lua` | Used by `display_test` |
| `Display.RenderNotifications()` | `ui/components/display.lua` | Used by `display_test` |
| `Compose.GetAvailableSpace()` | `ui/components/compose.lua` | Used by `compose_test` |
| `Theme.SetThemeOverride()` | `ui/theme.lua` | Used by `theme_test` |
| `Theme.ClearThemeOverrides()` | `ui/theme.lua` | Used by `theme_test` |
| `Theme.ExportTheme()` | `ui/theme.lua` | Used by `theme_test` |
| `Themes.getRoles()` | `config/themes.lua` | Used by `themes_test` |
| `SettingsSchema.buildIndex()` | `cfg/settings_schema.lua` | Used by `configengine_settings_schema_test` |
| `SettingsSchema.flattenSettings()` | `cfg/settings_schema.lua` | Used by `configengine_settings_schema_test` |
| `Tokens.styleVar()` | `ui/tokens.lua` | Used by `tokens_test` |
| `Tokens.styleVarVec2()` | `ui/tokens.lua` | Used by `tokens_test` |
| `Utils.markDirty()` | `ui/utils.lua` | Used by `utils_auto_save_test` |
| `Utils.isSavePending()` | `ui/utils.lua` | Used by `utils_auto_save_test` |
| `Utils.clearPendingSave()` | `ui/utils.lua` | Used by `utils_auto_save_test` |
| `Utils.isDirty()` | `ui/utils.lua` | Used by `utils_auto_save_test` |

---

## WIP Features (State Exists, Not Yet Wired)

### 1. Wiki Viewer System (`cfg/core.lua`)
- **State:** `wikiViewerOpen`, `wikiModId` fields exist in state
- **What's missing:** No UI rendering, no toggle function
- **Implementation:** Add panel in `cfg/ui/content_area.lua`, wire to sidebar

### 2. Detached Windows (`cfg/core.lua`)
- **State:** `detachMod()`, `reattachMod()`, `getDetachedMods()` exist
- **What's missing:** No UI for detaching, no window rendering
- **Implementation:** Add context menu option, floating window support

### 3. Mod Tag System (`cfg/core.lua`)
- **State:** Tags stored in mod registration spec
- **What's missing:** No add/remove/check functions were removed, no UI
- **Implementation:** Add tag filter in sidebar, tag management in settings

### 4. Theme Overrides (`ui/theme.lua`)
- `SetThemeOverride()` / `ClearThemeOverrides()` exist (preserved for tests)
- **What's missing:** No UI for per-role color overrides
- **Implementation:** Add color picker in theme settings

### 5. Theme Export (`ui/theme.lua`)
- `ExportTheme()` exists (preserved for tests), `ImportTheme()` was removed
- **What's missing:** Import UI, file I/O, clipboard support
- **Implementation:** Export button in theme settings, import dialog

### 6. Theme State Save/Restore (`ui/theme.lua`)
- `SaveThemeState()` / `RestoreThemeState()` / `GetSavedThemeState()` exist
- **What's missing:** "Reset Theme" button in UI
- **Implementation:** Wire to toolbar button

### 7. Logger Configuration (`modules/logger.lua`)
- All config functions preserved (tests use them)
- **What's missing:** Log level selector UI, debug message limit control
- **Implementation:** Add to engine settings panel

### 8. Undo/Redo UI Helpers (`cfg/undo_redo.lua`)
- All 4 functions preserved (tests use them)
- **What's missing:** Toolbar buttons showing undo/redo descriptions
- **Implementation:** Wire to toolbar, enable/disable based on availability

---

*Last updated: 2026-08-08*
