import 'package:flutter/material.dart';

import '../../../locale/languages.dart';
import '../../../utils/colors.dart';

/// Occupies its own layout space so the last appointment never sits under Next.
class BookingTimeFooter extends StatelessWidget {
  const BookingTimeFooter({
    super.key,
    required this.language,
    required this.date,
    required this.selectedSlot,
    required this.onNext,
  });

  final BaseLanguage language;
  final DateTime date;
  final String selectedSlot;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final summary = Row(
      children: [
        Icon(Icons.schedule_rounded, color: context.themePrimary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedSlot.isEmpty
                    ? language.chooseTime
                    : language.selectedAppointmentTime,
                style: textTheme.bodySmall?.copyWith(color: context.themeMuted),
              ),
              const SizedBox(height: 3),
              Text(
                '${MaterialLocalizations.of(context).formatMediumDate(date)}'
                '${selectedSlot.isEmpty ? '' : ' · $selectedSlot'}',
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
    final next = FilledButton(
      onPressed: onNext,
      style: FilledButton.styleFrom(
        minimumSize: const Size(116, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(language.next),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeSurface,
        border: Border(top: BorderSide(color: context.themeBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          if (MediaQuery.textScalerOf(context).scale(14) > 18 ||
              constraints.maxWidth < 300) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 12), next],
            );
          }
          return Row(children: [
            Expanded(child: summary),
            const SizedBox(width: 12),
            next,
          ]);
        }),
      ),
    );
  }
}
