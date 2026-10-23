import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../locale/languages.dart';
import '../../../utils/colors.dart';

enum _DayPeriod { night, morning, afternoon, evening }

/// Keeps the API's time values intact; periods only filter their presentation.
class TimeSlotPicker extends StatefulWidget {
  const TimeSlotPicker({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSelected,
    required this.language,
    this.emptyMessage,
  });

  final List<String> slots;
  final String selectedSlot;
  final ValueChanged<String> onSelected;
  final BaseLanguage language;
  final String? emptyMessage;

  @override
  State<TimeSlotPicker> createState() => _TimeSlotPickerState();
}

class _TimeSlotPickerState extends State<TimeSlotPicker> {
  _DayPeriod? _period;

  _DayPeriod _periodOf(String slot) {
    final hour = int.tryParse(slot.split(':').first) ?? 0;
    if (hour < 6) return _DayPeriod.night;
    if (hour < 12) return _DayPeriod.morning;
    if (hour < 17) return _DayPeriod.afternoon;
    return _DayPeriod.evening;
  }

  @override
  void initState() {
    super.initState();
    _syncPeriod();
  }

  @override
  void didUpdateWidget(covariant TimeSlotPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPeriod(followSelection: oldWidget.selectedSlot != widget.selectedSlot);
  }

  void _syncPeriod({bool followSelection = true}) {
    if (widget.slots.isEmpty) {
      _period = null;
    } else if (followSelection && widget.slots.contains(widget.selectedSlot)) {
      _period = _periodOf(widget.selectedSlot);
    } else if (_period == null ||
        !widget.slots.any((slot) => _periodOf(slot) == _period)) {
      _period = _periodOf(widget.slots.first);
    }
  }

  String _label(_DayPeriod period) => switch (period) {
        _DayPeriod.night => widget.language.nightAppointments,
        _DayPeriod.morning => widget.language.morningAppointments,
        _DayPeriod.afternoon => widget.language.afternoonAppointments,
        _DayPeriod.evening => widget.language.eveningAppointments,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = _DayPeriod.values
        .where(
            (period) => widget.slots.any((slot) => _periodOf(slot) == period))
        .toList();
    final visibleSlots =
        widget.slots.where((slot) => _periodOf(slot) == _period).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.language.chooseTime,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(widget.language.availableAppointmentTimes(widget.slots.length),
            style:
                theme.textTheme.bodySmall?.copyWith(color: context.themeMuted)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.themeBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (periods.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: periods.map((period) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(_label(period)),
                          selected: _period == period,
                          showCheckmark: false,
                          selectedColor: context.themeSoftPrimary,
                          backgroundColor: context.themeSubtleSurface,
                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                            color: _period == period
                                ? context.themeOnSoftPrimary
                                : context.themeMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                              color: _period == period
                                  ? context.themePrimary
                                  : context.themeBorder),
                          onSelected: (_) => setState(() => _period = period),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (visibleSlots.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                      widget.emptyMessage?.trim().isNotEmpty == true
                          ? widget.emptyMessage!
                          : widget.language.noTimeSlotsAvailable,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: context.themeMuted)),
                )
              else
                LayoutBuilder(builder: (context, constraints) {
                  const gap = 8.0;
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(14) / 14;
                  final columns = ((constraints.maxWidth + gap) /
                          (82 * math.max(1, textScale) + gap))
                      .floor()
                      .clamp(1, 4);
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: visibleSlots.map((slot) {
                      final selected = slot == widget.selectedSlot;
                      return SizedBox(
                        width: width,
                        child: Semantics(
                          selected: selected,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 12),
                              backgroundColor: selected
                                  ? appColorPrimary
                                  : context.themeSubtleSurface,
                              foregroundColor:
                                  selected ? Colors.white : context.themeText,
                              side: BorderSide(
                                  color: selected
                                      ? appColorPrimary
                                      : context.themeBorder),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => widget.onSelected(slot),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (selected) ...[
                                  const Icon(Icons.check_rounded, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(slot,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
