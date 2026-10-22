import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/colors.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = create(Brightness.light);
  static final ThemeData darkTheme = create(Brightness.dark);

  /// An explicit family also lets widget tests exercise the production palette
  /// without fetching font files over the network.
  static ThemeData create(Brightness brightness, {String? fontFamily}) {
    final dark = brightness == Brightness.dark;
    final background = dark ? appDarkBackground : appScreenBackground;
    final surface = dark ? appDarkSurface : Colors.white;
    final foreground = dark ? appDarkTextPrimary : primaryTextColor;
    final muted = dark ? appDarkTextSecondary : appLightTextSecondary;
    final outline = dark ? appDarkOutline : const Color(0xFFCFD7E2);
    final primary = dark ? appColorPrimaryOnDark : appColorPrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: appColorPrimary,
      brightness: brightness,
      primary: primary,
      onPrimary: dark ? const Color(0xFF00344C) : Colors.white,
      secondary: dark ? const Color(0xFF9BCBDF) : appColorSecondary,
      surface: surface,
      onSurface: foreground,
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
    ).copyWith(
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: dark ? const Color(0xFF304054) : const Color(0xFFE0E5EC),
      surfaceContainerLowest: background,
      surfaceContainerLow:
          dark ? const Color(0xFF151E29) : const Color(0xFFF4F7FA),
      surfaceContainer: surface,
      surfaceContainerHigh:
          dark ? const Color(0xFF243244) : const Color(0xFFEDF2F7),
      surfaceContainerHighest:
          dark ? const Color(0xFF2B3B4E) : const Color(0xFFE6EDF4),
      primaryContainer:
          dark ? const Color(0xFF153B50) : const Color(0xFFE6F2FA),
      onPrimaryContainer:
          dark ? const Color(0xFFBCE7FF) : const Color(0xFF004C73),
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      cardColor: surface,
      primaryColor: primary,
      dividerColor: scheme.outlineVariant,
      disabledColor: foreground.withValues(alpha: .38),
    );
    final textTheme = fontFamily == null
        ? GoogleFonts.interTightTextTheme(base.textTheme)
        : base.textTheme.apply(fontFamily: fontFamily);
    final family = fontFamily ?? GoogleFonts.interTight().fontFamily;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: outline),
    );
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: background,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
    final actionStyle = FilledButton.styleFrom(
      backgroundColor: appColorPrimary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: scheme.onSurface.withValues(alpha: .10),
      disabledForegroundColor: scheme.onSurface.withValues(alpha: .38),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme:
          textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: background,
        foregroundColor: foreground,
        iconTheme: IconThemeData(color: foreground),
        titleTextStyle: TextStyle(
            fontFamily: family,
            color: foreground,
            fontSize: 20,
            fontWeight: FontWeight.w600),
        systemOverlayStyle: overlay,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: surface),
      iconTheme: IconThemeData(color: muted),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: primary),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: border,
        enabledBorder: border,
        disabledBorder: border.copyWith(
            borderSide: BorderSide(color: outline.withValues(alpha: .45))),
        focusedBorder:
            border.copyWith(borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder:
            border.copyWith(borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: border.copyWith(
            borderSide: BorderSide(color: scheme.error, width: 1.5)),
        errorStyle: TextStyle(color: scheme.error),
        errorMaxLines: 3,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(style: actionStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: actionStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        disabledForegroundColor: foreground.withValues(alpha: .38),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: appColorPrimary, foregroundColor: Colors.white),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: surface,
          modalBackgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          dragHandleColor: muted),
      dialogTheme: DialogThemeData(
          backgroundColor: scheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: textTheme.titleLarge?.copyWith(color: foreground),
          contentTextStyle: textTheme.bodyMedium?.copyWith(color: foreground)),
      popupMenuTheme: PopupMenuThemeData(
          color: scheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          textStyle: textTheme.bodyMedium?.copyWith(color: foreground)),
      dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: textTheme.bodyMedium?.copyWith(color: foreground),
          menuStyle: MenuStyle(
              backgroundColor:
                  WidgetStatePropertyAll(scheme.surfaceContainerHigh))),
      listTileTheme: ListTileThemeData(textColor: foreground, iconColor: muted),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      expansionTileTheme: ExpansionTileThemeData(
          textColor: foreground,
          collapsedTextColor: foreground,
          iconColor: primary,
          collapsedIconColor: muted),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: primary,
          linearTrackColor: scheme.surfaceContainerHighest,
          circularTrackColor: primary.withValues(alpha: .15)),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: primary,
          selectionColor: primary.withValues(alpha: .28),
          selectionHandleColor: primary),
      chipTheme: ChipThemeData(
          backgroundColor: scheme.surfaceContainerLow,
          selectedColor: appColorPrimary,
          disabledColor: scheme.surfaceContainerHighest,
          checkmarkColor: Colors.white,
          labelStyle: textTheme.bodyMedium?.copyWith(color: foreground),
          secondaryLabelStyle:
              textTheme.bodyMedium?.copyWith(color: Colors.white),
          side: BorderSide(color: scheme.outlineVariant)),
      tabBarTheme: TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: muted,
          indicatorColor: primary,
          dividerColor: scheme.outlineVariant),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: muted),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: scheme.primaryContainer,
          labelTextStyle: WidgetStatePropertyAll(
              textTheme.labelMedium?.copyWith(color: foreground))),
      switchTheme: SwitchThemeData(
          trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? scheme.onSurface.withValues(alpha: .12)
                  : states.contains(WidgetState.selected)
                      ? appColorPrimary
                      : scheme.surfaceContainerHighest),
          thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? muted.withValues(alpha: .5)
                  : states.contains(WidgetState.selected)
                      ? Colors.white
                      : muted)),
      datePickerTheme: DatePickerThemeData(
          backgroundColor: surface, surfaceTintColor: Colors.transparent),
      timePickerTheme: TimePickerThemeData(backgroundColor: surface),
      dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          headingTextStyle: textTheme.titleSmall?.copyWith(color: foreground),
          dataTextStyle: textTheme.bodyMedium?.copyWith(color: foreground),
          dividerThickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
