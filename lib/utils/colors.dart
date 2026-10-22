import 'package:flutter/material.dart';

const appColorPrimary = Color(0xFF0074AD);
const appColorSecondary = Color(0xff003C5A);
// Lighter primary for indicators on dark backgrounds (appColorPrimary is too dim there).
const appColorPrimaryOnDark = Color(0xFF7AC9F5);
const lightPrimaryColor = Color(0xFFEBEDFF);
const extraLightPrimaryColor = Color(0xFFF5F6FA);
const lightSecondaryColor = Color(0xFFFEF1F1);

const appBodyColor = Color(0xFF828A90);
const canvasColor = Color(0xFF1E1E24);
const canvasColorDark = Color(0xFF171B23);
const fullDarkCanvasColor = Color(0xFF272B35);
const fullDarkCanvasColorDark = Color(0xFF12161E);
const lightCanvasColor = Color(0xFF384052);
const mediumCanvasColor = Color(0XFF303030);

//Section BG / page BG
const appLayoutBackground = Color(0xFFFAF8FF);
const appSectionBackground = Color(0xFFFFFFFF);
const appScreenBackground = Color(0xFFF5F6FA);
const appScreenGreyBackground = Color(0xFFF7F7F7);
const lightGreenColor = Color(0xFFEFF8F3);

// Tertiary
const bodyWhite = Color(0xFFA6A6A6);
const bodyWhiteType = Color(0xFFFAFAFA);
const appColorlightGray = Color(0xFFF5F5F5);
const dividerColor = Color(0xFF828A90);
const whiteBorderColor = Color(0xFFF3F3FF);
const borderColor = Color(0xFFD8D9D9);
const borderColorDark = Color(0xFF23272F);

// Dark Theme Colors
const appScreenBackgroundDark = Color(0xFF171B23);
const appBackgroundColorDark = Color(0xFF000000);
const appBackgroundSecondaryColorDark = Color(0xFF0D0D0D);
const colorPrimaryBlack = Color(0xFF121212);
const darkHeadingColor = Color(0xFF999999);
const appDarkBodyColor = Color(0xFF666666);
const iconColorPrimaryDark = Color(0xFF5F6060);
const appShadowColorDark = Color(0xFF333333);
const cardBackgroundBlackDark = Color(0xFF1F1F1F);

// Text Colors
const appTransparentColor = Colors.transparent;
const whiteTextColor = Color(0xFFFFFFFF);
const blackTextColor = Color(0xFF000000);
const resetTextColor = Color(0xFF48D0B8);
const deleteTextColor = Color(0xFFD76161);
const redTextColor = Color(0xFFFF3E3E);
const darkGrayGeneral = Color(0xff6C757D);
const darkGrayTextColor = Color(0xff3F414D);

//Text Colors
const primaryTextColor = Color(0xFF11104A);
const secondaryTextColor = Color(0xFF828A90);

//status color
const pendingStatusColor = Color(0xFFFD866E);
const checkoutStatusColor = Color(0xFFFFCE70);
const confirmedStatusColor = appColorPrimary;
const completedStatusColor = Color(0xFF56CC85);
const cancelStatusColor = Color(0xFFF04336);
const defaultStatusColor = Color(0xFF11104A);
const checkInStatusColor = Color(0xFFE56F0F);

//review selection color
const ratingColor = checkoutStatusColor;
const ratingFirstColor = Color(0xFF26C485);
const ratingSecondColor = checkoutStatusColor;
const ratingThirdColor = pendingStatusColor;
const ratingFourthColor = cancelStatusColor;
const ratingFifthColor = checkInStatusColor;

const switchActiveTrackColor = appColorPrimary;
const switchActiveColor = Colors.white;
const switchColor = Color(0xFF808080);
const iconColor = Color(0xFF6E8192);
const browseColor = Color(0xFFEAEAFA);

// Shared semantic surfaces for both light and dark screens.
const appDarkBackground = Color(0xFF10151D);
const appDarkSurface = Color(0xFF1B2431);
const appDarkTextPrimary = Color(0xFFF1F5FB);
const appDarkTextSecondary = Color(0xFFB5C1D0);
const appLightTextSecondary = Color(0xFF566274);
const appDarkOutline = Color(0xFF3D4C60);

extension AppThemeColors on BuildContext {
  Color themeTint(Color color) =>
      Color.alphaBlend(color.withValues(alpha: .12), themeSurface);
  bool get themeIsDark => Theme.of(this).brightness == Brightness.dark;
  Color get themePrimary => Theme.of(this).colorScheme.primary;
  Color get themeText => Theme.of(this).colorScheme.onSurface;
  Color get themeMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get themeSurface => Theme.of(this).colorScheme.surface;
  Color get themeSubtleSurface =>
      Theme.of(this).colorScheme.surfaceContainerLow;
  Color get themeSoftPrimary => Theme.of(this).colorScheme.primaryContainer;
  Color get themeOnSoftPrimary => Theme.of(this).colorScheme.onPrimaryContainer;
  Color get themeBorder => Theme.of(this).colorScheme.outlineVariant;
  Color get themeSuccess =>
      themeIsDark ? const Color(0xFF81D5AA) : const Color(0xFF23734D);
  Color get themeWarning =>
      themeIsDark ? const Color(0xFFFFCA86) : const Color(0xFF875000);
  Color get themeDanger => Theme.of(this).colorScheme.error;
}
