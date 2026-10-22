import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/app_theme.dart';
import 'package:kivicare_patient/components/app_scaffold.dart';
import 'package:kivicare_patient/components/cached_image_widget.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/colors.dart';
import 'package:kivicare_patient/utils/common_base.dart';
import 'package:kivicare_patient/utils/theme_mode_controller.dart';
import 'package:kivicare_patient/utils/map_styles.dart';
import 'dart:convert';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light and dark text, fields and actions have readable contrast', () {
    for (final brightness in Brightness.values) {
      final theme = AppTheme.create(brightness, fontFamily: 'Test');
      final colors = theme.colorScheme;
      expect(theme.brightness, brightness);
      expect(contrast(colors.onSurface, colors.surface),
          greaterThanOrEqualTo(4.5));
      expect(contrast(colors.onSurfaceVariant, colors.surface),
          greaterThanOrEqualTo(4.5));
      expect(
          contrast(colors.primary, colors.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(theme.textTheme.bodyMedium!.color!, colors.surface),
          greaterThanOrEqualTo(4.5));
      expect(
          contrast(theme.inputDecorationTheme.hintStyle!.color!,
              theme.inputDecorationTheme.fillColor!),
          greaterThanOrEqualTo(4.5));
      final style = theme.filledButtonTheme.style!;
      expect(
          contrast(style.foregroundColor!.resolve({})!,
              style.backgroundColor!.resolve({})!),
          greaterThanOrEqualTo(4.5));
      if (brightness == Brightness.dark) {
        expect(colors.surface.computeLuminance(), lessThan(.05));
        expect(theme.dialogTheme.backgroundColor!.computeLuminance(),
            lessThan(.08));
        expect(theme.bottomSheetTheme.backgroundColor!.computeLuminance(),
            lessThan(.05));
      }
    }
  });

  testWidgets(
      'system preference follows live platform changes and manual mode remains selected',
      (tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue);
    final resolved = <bool>[];
    final preference =
        AppThemeModeController(onBrightnessChanged: resolved.add);
    preference.setMode(ThemeMode.system);
    await tester.pumpWidget(ListenableBuilder(
        listenable: preference,
        builder: (context, _) => MaterialApp(
              theme: AppTheme.create(Brightness.light, fontFamily: 'Test'),
              darkTheme: AppTheme.create(Brightness.dark, fontFamily: 'Test'),
              themeMode: preference.mode,
              home: Builder(
                  builder: (context) =>
                      Text(Theme.of(context).brightness.name)),
            )));
    await tester.pumpAndSettle();
    expect(find.text('light'), findsOneWidget);
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    await tester.pumpAndSettle();
    expect(find.text('dark'), findsOneWidget);
    expect(preference.mode, ThemeMode.system);
    expect(resolved.last, isTrue);
    preference.setMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(find.text('light'), findsOneWidget);
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    await tester.pumpAndSettle();
    expect(find.text('light'), findsOneWidget);
    expect(preference.mode, ThemeMode.light);
    preference.setMode(ThemeMode.system);
    await tester.pumpAndSettle();
    expect(find.text('dark'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    preference.dispose();
  });

  testWidgets(
      'legacy form decoration uses the active theme and supports validation errors',
      (tester) async {
    themeModeController.setMode(ThemeMode.dark);
    addTearDown(() => themeModeController.setMode(ThemeMode.light));
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.create(Brightness.dark, fontFamily: 'Test'),
      home: Scaffold(
          body: Builder(
              builder: (context) => Form(
                  key: formKey,
                  child: TextFormField(
                    decoration: inputDecoration(context, hintText: 'Phone'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  )))),
    ));
    final field = tester.widget<TextField>(find.byType(TextField));
    final context = tester.element(find.byType(TextFormField));
    expect(field.decoration!.hintStyle!.color, context.themeMuted);
    expect(contrast(textPrimaryColorGlobal, context.themeSurface),
        greaterThanOrEqualTo(4.5));
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    expect(field.decoration!.errorStyle!.color, context.themeDanger);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'image placeholders stay dark instead of flashing random light colors',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.create(Brightness.dark, fontFamily: 'Test'),
      home: const Scaffold(
          body: CachedImageWidget(url: '', width: 64, height: 64)),
    ));
    final placeholder =
        tester.widget<PlaceHolderWidget>(find.byType(PlaceHolderWidget));
    expect(placeholder.color, isNotNull);
    expect(placeholder.color!.computeLuminance(), lessThan(.06));
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom header has readable system icons and a dark surface',
      (tester) async {
    Get.testMode = true;
    themeModeController.setMode(ThemeMode.dark);
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.create(Brightness.dark, fontFamily: 'Test'),
      home: const AppScaffoldNew(
        appBarChild: Text('Header'),
        body: Text('Body'),
      ),
    ));
    await tester.pumpAndSettle();
    final regions = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
        .toList();
    expect(
        regions.any((r) => r.value.statusBarIconBrightness == Brightness.light),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
    themeModeController.setMode(ThemeMode.light);
  });

  test('dark map style is valid local JSON with dark geometry', () {
    final style = jsonDecode(darkMapStyle) as List;
    expect(style, isNotEmpty);
    expect(style.first['stylers'].first['color'], '#1b2431');
  });
}
