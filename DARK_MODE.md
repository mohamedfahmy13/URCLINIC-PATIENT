# Light and dark themes

Both apps share the same semantic palette and component theme structure.

- app_theme.dart builds light and dark ThemeData from the correct base brightness. Text styles, fields, dialogs, sheets, menus, pickers, navigation and actions inherit those colors.
- utils/colors.dart provides context.themeSurface, themeSubtleSurface, themeText, themeMuted, themeBorder and themePrimary. Use these for app content instead of fixed white/black backgrounds or dark brand colors as foregrounds.
- Keep white text on solid appColorPrimary buttons and brand headers. themePrimary is intended for foregrounds on surfaces; the dark variant is brighter.
- Use context.themeSuccess, themeWarning and themeDanger for readable status labels, with a matching subtle background.
- Call toggleThemeMode to change and save a user preference. AppThemeModeController resolves system brightness without overwriting that preference, and keeps legacy nb_utils text styles synchronized before rebuilding.
- Image placeholders and local map styles follow the current theme.
- Theme getters use BuildContext at runtime, so their parent widgets cannot be const constructors.

Restart both Flutter apps after updating the shared theme and theme preference handling. There are no new dependencies or backend changes.

Verification:

    flutter test
    dart analyze lib test

The dark mode tests cover text/field/button contrast, live platform brightness changes, explicit overrides, legacy form errors, custom system bar icons, image placeholders and map JSON. App-specific checks also cover banner moderation labels or clinic status badges. Widget checks and rendered previews were used; native device builds were not run.
