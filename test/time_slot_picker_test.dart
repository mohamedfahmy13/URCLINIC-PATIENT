import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivicare_patient/app_theme.dart';
import 'package:kivicare_patient/locale/language_ar.dart';
import 'package:kivicare_patient/locale/language_en.dart';
import 'package:kivicare_patient/screens/slots/components/booking_time_footer.dart';
import 'package:kivicare_patient/screens/slots/components/time_slot_picker.dart';

Widget app(Widget child,
        {Brightness brightness = Brightness.light,
        bool arabic = false,
        double textScale = 1}) =>
    MaterialApp(
      theme: AppTheme.create(brightness, fontFamily: 'Test'),
      locale: Locale(arabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  final language = LanguageEn();

  testWidgets('periods filter slots without automatically choosing a time',
      (tester) async {
    var selected = '';
    await tester.pumpWidget(app(StatefulBuilder(builder: (context, setState) {
      return TimeSlotPicker(
        slots: const ['09:00', '09:15', '11:45', '12:00', '16:45', '17:00'],
        selectedSlot: selected,
        language: language,
        onSelected: (slot) => setState(() => selected = slot),
      );
    })));
    expect(find.text('6 available appointments'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '09:15'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '12:00'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Afternoon'));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(find.widgetWithText(OutlinedButton, '09:15'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '12:00'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '12:00'));
    await tester.pumpAndSettle();
    expect(selected, '12:00'); // Keep the original API value for submission.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Morning'));
    await tester.pumpAndSettle();
    expect(selected, '12:00'); // Browsing a period never changes the booking.
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone layout fits four readable slots across the actual card',
      (tester) async {
    tester.view.physicalSize = const Size(440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(Padding(
      padding: const EdgeInsets.all(16),
      child: TimeSlotPicker(
        slots: const ['09:00', '09:15', '09:30', '09:45'],
        selectedSlot: '',
        language: language,
        onSelected: (_) {},
      ),
    )));
    final first = find.widgetWithText(OutlinedButton, '09:00');
    final fourth = find.widgetWithText(OutlinedButton, '09:45');
    expect(tester.getTopLeft(first).dy, tester.getTopLeft(fourth).dy);
    expect(tester.getSize(first).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('date changes reset the period and removed slots stay absent',
      (tester) async {
    var day = 1;
    var selected = '17:00';
    var slots = ['09:00', '17:00'];
    late StateSetter update;
    await tester.pumpWidget(app(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return TimeSlotPicker(
        key: ValueKey(day),
        slots: slots,
        selectedSlot: selected,
        language: language,
        onSelected: (_) {},
      );
    })));
    expect(find.widgetWithText(OutlinedButton, '17:00'), findsOneWidget);
    update(() {
      day = 2;
      selected = '';
    });
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '09:00'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Evening'));
    await tester.pumpAndSettle();
    update(() => slots = ['10:00']);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '10:00'), findsOneWidget);
    expect(find.text('17:00'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('night slots, an external selection and an empty day are handled',
      (tester) async {
    var slots = ['00:15', '06:00', '12:00', '23:45'];
    var selected = '';
    late StateSetter update;
    await tester.pumpWidget(app(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return TimeSlotPicker(
        slots: slots,
        selectedSlot: selected,
        language: language,
        emptyMessage: 'The doctor is off today',
        onSelected: (_) {},
      );
    })));
    expect(find.widgetWithText(OutlinedButton, '00:15'), findsOneWidget);
    update(() => selected = '23:45');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '23:45'), findsOneWidget);
    update(() => slots = []);
    await tester.pumpAndSettle();
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('The doctor is off today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('compact RTL and large text fit in ${brightness.name} mode',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ar = LanguageAr();
      await tester.pumpWidget(app(
        Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TimeSlotPicker(
                slots: const ['09:00', '09:15', '12:00', '17:00'],
                selectedSlot: '09:15',
                onSelected: (_) {},
                language: ar,
              ),
            ),
          ),
          BookingTimeFooter(
            language: ar,
            date: DateTime(2026, 10, 27),
            selectedSlot: '09:15',
            onNext: () {},
          ),
        ]),
        arabic: true,
        brightness: brightness,
        textScale: 1.8,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the last time stays above the footer and Next requires a choice',
      (tester) async {
    tester.view.physicalSize = const Size(390, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = '';
    var advanced = false;
    final slots = List.generate(
        24,
        (i) =>
            '${(6 + i ~/ 4).toString().padLeft(2, '0')}:${(i % 4 * 15).toString().padLeft(2, '0')}');
    await tester.pumpWidget(app(StatefulBuilder(builder: (context, setState) {
      return Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TimeSlotPicker(
              slots: slots,
              selectedSlot: selected,
              onSelected: (slot) => setState(() => selected = slot),
              language: language,
            ),
          ),
        ),
        BookingTimeFooter(
          language: language,
          date: DateTime(2026, 10, 27),
          selectedSlot: selected,
          onNext: selected.isEmpty ? null : () => advanced = true,
        ),
      ]);
    })));
    final next = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    final last = find.widgetWithText(OutlinedButton, '11:45');
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(
        tester.getBottomLeft(last).dy,
        lessThanOrEqualTo(
            tester.getTopLeft(find.byType(BookingTimeFooter)).dy));
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(selected, '11:45');
    expect(find.text('Selected appointment'), findsOneWidget);
    await tester.tap(next);
    expect(advanced, isTrue);
    expect(tester.takeException(), isNull);
  });
}
