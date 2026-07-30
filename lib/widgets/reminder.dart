import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quotes_app/controllers/reminder_controller.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';
import 'package:quotes_app/models/reminder_model.dart';
import 'package:quotes_app/views/themes/colors.dart';
import 'package:quotes_app/views/themes/typography.dart';

class ReminderWidget extends ConsumerStatefulWidget {
  const ReminderWidget({
    super.key,
    this.initialValue,
    this.onSaved,
    this.onChanged,
    this.saveButtonLabel = 'Lock it in',
    this.showHeader = true,
    this.showAction = true,
    this.requiresSubscription = false,
  });

  final Reminder? initialValue;
  final ValueChanged<Reminder>? onSaved;
  final ValueChanged<Reminder>? onChanged;
  final String saveButtonLabel;
  final bool showHeader;
  final bool showAction;
  final bool requiresSubscription;

  @override
  ConsumerState<ReminderWidget> createState() => _ReminderWidgetState();
}

class _ReminderWidgetState extends ConsumerState<ReminderWidget> {
  late final Future<Reminder> _initialValue;
  Reminder? _reminder;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue == null
        ? ref.read(reminderControllerProvider).fetchReminder()
        : Future.value(widget.initialValue);
    if (widget.requiresSubscription && !ref.read(subscribedProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/subscription');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Reminder>(
      future: _initialValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: MyColors.primary),
          );
        }
        _reminder ??= snapshot.requireData;
        return _editor(_reminder!);
      },
    );
  }

  Widget _editor(Reminder reminder) {
    final localizations = MaterialLocalizations.of(context);
    final start = _timeOfDay(reminder.startMinute);
    final end = _timeOfDay(reminder.endMinute);

    final content = Container(
      decoration: BoxDecoration(
        color: widget.showHeader ? MyColors.darkPanel : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: widget.showHeader ? Border.all(color: MyColors.disabled) : null,
      ),
      padding: widget.showHeader
          ? const EdgeInsets.fromLTRB(20, 22, 20, 20)
          : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Text(
              'Pressure window',
              style: MyTypography.h2.copyWith(color: MyColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose exactly when scheduled prompts may reach you.',
              style: MyTypography.body1.copyWith(color: MyColors.muted),
            ),
            const SizedBox(height: 24),
          ],
          _sectionLabel('ACTIVE DAYS'),
          const SizedBox(height: 10),
          _weekdayPicker(reminder),
          const SizedBox(height: 10),
          _shortcutRow(reminder),
          const SizedBox(height: 22),
          _sectionLabel('TIME WINDOW'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _timeTile(
                  label: 'START',
                  value: localizations.formatTimeOfDay(start),
                  onTap: () => _pickTime(start, isStart: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: MyColors.muted,
                ),
              ),
              Expanded(
                child: _timeTile(
                  label: 'END',
                  value: localizations.formatTimeOfDay(end),
                  onTap: () => _pickTime(end, isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _countRow(reminder),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (_error == null ? MyColors.primary : MyColors.pink)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error ?? _summary(reminder, localizations),
                style: MyTypography.body2.copyWith(
                  color: _error == null ? MyColors.ink : MyColors.pink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (widget.showAction) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: MyColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: MyColors.disabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.saveButtonLabel,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
          ],
          if (widget.showAction &&
              widget.onSaved == null &&
              reminder.enabled) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _saving ? null : _disable,
                child: const Text('Turn off reminders'),
              ),
            ),
          ],
        ],
      ),
    );

    if (!widget.showHeader) return content;
    return SafeArea(child: SingleChildScrollView(child: content));
  }

  Widget _shortcutRow(Reminder reminder) {
    return Wrap(
      spacing: 8,
      children: [
        _shortcut(
          'Weekdays',
          selected: reminder.weekdays.length == 5 &&
              reminder.weekdays.every((day) => day <= DateTime.friday),
          weekdays: const [1, 2, 3, 4, 5],
        ),
        _shortcut(
          'Every day',
          selected: reminder.weekdays.length == 7,
          weekdays: const [1, 2, 3, 4, 5, 6, 7],
        ),
      ],
    );
  }

  Widget _shortcut(
    String label, {
    required bool selected,
    required List<int> weekdays,
  }) {
    return OutlinedButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        _update(_reminder!.copyWith(weekdays: weekdays));
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: selected ? Colors.white : MyColors.ink,
        backgroundColor: selected ? MyColors.primary : Colors.transparent,
        side: BorderSide(
          color: selected ? MyColors.primary : MyColors.disabled,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      child: Text(label),
    );
  }

  Widget _weekdayPicker(Reminder reminder) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Row(
      children: List.generate(DateTime.daysPerWeek, (index) {
        final weekday = index + DateTime.monday;
        final selected = reminder.weekdays.contains(weekday);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == DateTime.daysPerWeek - 1 ? 0 : 6,
            ),
            child: Semantics(
              label: names[index],
              button: true,
              selected: selected,
              excludeSemantics: true,
              child: Material(
                color: selected ? MyColors.primary : MyColors.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final weekdays = [...reminder.weekdays];
                    selected ? weekdays.remove(weekday) : weekdays.add(weekday);
                    weekdays.sort();
                    _update(reminder.copyWith(weekdays: weekdays));
                  },
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 44),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? MyColors.primary : MyColors.disabled,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: selected ? Colors.white : MyColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: MyTypography.caption1.copyWith(
        color: MyColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: Material(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: MyColors.disabled),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: MyTypography.caption1.copyWith(
                    color: MyColors.muted,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  style: MyTypography.h3.copyWith(
                    color: MyColors.ink,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countRow(Reminder reminder) {
    return Semantics(
      label: '${reminder.count} prompts per day',
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyColors.disabled),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROMPTS PER DAY',
                    style: MyTypography.caption1.copyWith(
                      color: MyColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Evenly spaced in your window',
                    style: MyTypography.body2.copyWith(color: MyColors.ink),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Fewer prompts per day',
              onPressed: reminder.count == 1
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _update(reminder.copyWith(count: reminder.count - 1));
                    },
              icon: const Icon(Icons.remove, size: 19),
              color: MyColors.ink,
            ),
            SizedBox(
              width: 24,
              child: Text(
                reminder.count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MyColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'More prompts per day',
              onPressed: reminder.count == 6
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _update(reminder.copyWith(count: reminder.count + 1));
                    },
              icon: const Icon(Icons.add, size: 19),
              color: MyColors.ink,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(TimeOfDay initial, {required bool isStart}) async {
    final value = defaultTargetPlatform == TargetPlatform.iOS
        ? await _showCupertinoTimePicker(initial)
        : await showTimePicker(context: context, initialTime: initial);
    if (value == null || !mounted) return;
    HapticFeedback.selectionClick();
    final minute = value.hour * 60 + value.minute;
    _update(
      isStart
          ? _reminder!.copyWith(startMinute: minute)
          : _reminder!.copyWith(endMinute: minute),
    );
  }

  Future<TimeOfDay?> _showCupertinoTimePicker(TimeOfDay initial) async {
    var selected = initial;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => Container(
        height: 310,
        color: MyColors.darkPanel,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    Text(
                      'Choose time',
                      style: MyTypography.body1.copyWith(
                        color: MyColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: MyColors.disabled),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.light,
                    primaryColor: MyColors.primary,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                    initialDateTime:
                        DateTime(2026, 1, 1, initial.hour, initial.minute),
                    onDateTimeChanged: (date) {
                      selected =
                          TimeOfDay(hour: date.hour, minute: date.minute);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed == true ? selected : null;
  }

  void _update(Reminder reminder) {
    setState(() {
      _reminder = reminder;
      _error = null;
    });
    widget.onChanged?.call(reminder);
  }

  Future<void> _save() async {
    if (widget.requiresSubscription && !ref.read(subscribedProvider)) {
      context.go('/subscription');
      return;
    }

    final reminder = _reminder!;
    final validationError = reminder.validationError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(reminderControllerProvider);
      var saved = await controller.saveSchedule(reminder);
      var active = saved.enabled;
      if (widget.onSaved == null) {
        active = active && await controller.hasPermission();
        if (!active) active = await controller.enableNotifications();
        if (active) saved = await controller.fetchReminder();
        if (mounted) setState(() => _reminder = saved);
      }
      ref.invalidate(reminderProvider);
      widget.onSaved?.call(saved);
      if (mounted && widget.onSaved == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              active
                  ? 'Pressure window active.'
                  : 'Schedule saved. Enable notifications in Settings.',
            ),
            action: active
                ? null
                : SnackBarAction(
                    label: 'Settings',
                    onPressed: controller.openSystemSettings,
                  ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save the schedule. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _saving = true);
    try {
      final controller = ref.read(reminderControllerProvider);
      await controller.disableNotifications();
      final reminder = await controller.fetchReminder();
      ref.invalidate(reminderProvider);
      if (!mounted) return;
      setState(() => _reminder = reminder);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminders are off.')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not turn off reminders. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TimeOfDay _timeOfDay(int minute) =>
      TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

  String _summary(Reminder reminder, MaterialLocalizations localizations) {
    final daySummary = reminder.weekdays.length == 7
        ? 'every day'
        : reminder.weekdays.length == 5 &&
                reminder.weekdays.every((day) => day <= DateTime.friday)
            ? 'Monday–Friday'
            : '${reminder.weekdays.length} selected days';
    final start = localizations.formatTimeOfDay(
      _timeOfDay(reminder.startMinute),
    );
    final end = localizations.formatTimeOfDay(_timeOfDay(reminder.endMinute));
    return '${reminder.count} ${reminder.count == 1 ? 'prompt' : 'prompts'} a day · '
        '$daySummary · $start–$end';
  }
}
