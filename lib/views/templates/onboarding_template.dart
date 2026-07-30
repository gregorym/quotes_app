import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quotes_app/controllers/reminder_controller.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';
import 'package:quotes_app/controllers/user_controller.dart';
import 'package:quotes_app/models/reminder_model.dart';
import 'package:quotes_app/repositories/onboarding_repository.dart';
import 'package:quotes_app/views/themes/colors.dart';
import 'package:quotes_app/views/themes/typography.dart';
import 'package:quotes_app/widgets/reminder.dart';

const _goalCategories = [
  'Career',
  'Business & Entrepreneurship',
  'Fitness',
  'Education & Skills',
  'Money & Finance',
  'Personal Growth',
  'Other',
];

const _frictions = [
  'Procrastination',
  'Distraction',
  'Inconsistency',
  'Perfectionism',
  'Low energy',
  'Too many priorities',
  'Fear of failing',
  'Something else',
];

const _canvas = MyColors.background;
const _paper = MyColors.ink;
const _quiet = MyColors.muted;
const _gold = MyColors.primary;
const _goalGreen = Color(0xFF22C55E);
const _panel = MyColors.surface;
const _hairline = MyColors.disabled;

class OnboardingTemplate extends ConsumerStatefulWidget {
  const OnboardingTemplate({super.key});

  @override
  ConsumerState<OnboardingTemplate> createState() => _OnboardingTemplateState();
}

class _OnboardingTemplateState extends ConsumerState<OnboardingTemplate> {
  static const _lastPage = 11;

  final _answers = <String, dynamic>{};
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _goalDaysController = TextEditingController();
  final _frictionController = TextEditingController();

  late final Future<void> _answersFuture;
  var _page = 0;
  var _permissionBusy = false;
  var _permissionDenied = false;
  var _movingForward = true;
  var _customFrictionSelected = false;
  var _scheduleBusy = false;
  String? _permissionError;
  String? _nameError;
  String? _goalError;
  String? _goalDaysError;
  String? _categoryError;
  String? _frictionError;
  String? _scheduleError;
  Reminder? _reminder;

  String get _firstName {
    final name = _answers['name']?.toString().trim();
    return name == null || name.isEmpty ? 'You' : name.split(' ').first;
  }

  String get _goal => _answers['primary_goal']?.toString().trim() ?? '';

  int get _goalDays {
    final typed = int.tryParse(_goalDaysController.text);
    final stored = _answers['goal_days'];
    return typed ?? (stored is num ? stored.round() : 30);
  }

  List<String> get _selectedFrictions => onboardingFrictions(_answers);

  String get _friction {
    final summary = onboardingFrictionSummary(_answers);
    return summary.isEmpty ? 'Drift' : summary;
  }

  String get _pressureMessage => _answers['tone'] == 'extra hard'
      ? '$_firstName, tired? Nobody cares. Get the f*** up and finish.'
      : '$_firstName, stop waiting to feel ready. Move.';

  String get _deliveryMessage => _answers['tone'] == 'extra hard'
      ? '$_firstName, nobody is coming to save you. Get to work.'
      : '$_firstName, your goal does not care how you feel. Get to work.';

  bool _isPresetFriction(String friction) =>
      friction != 'Something else' && _frictions.contains(friction);

  @override
  void initState() {
    super.initState();
    _answersFuture = _loadAnswers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _goalDaysController.dispose();
    _frictionController.dispose();
    super.dispose();
  }

  Future<void> _loadAnswers() async {
    final repository = ref.read(onboardingRepositoryProvider);
    final stored = await repository.fetchAnswers();
    try {
      _reminder = await ref.read(reminderControllerProvider).fetchReminder();
    } catch (_) {
      _reminder = const Reminder();
    }
    _answers.addAll(stored);
    _answers['categories'] = _selectedCategories.take(1).toList();
    _nameController.text = _answers['name']?.toString() ?? '';
    _goalController.text = _answers['primary_goal']?.toString() ?? '';
    final storedDays = _answers['goal_days'];
    final goalDays = storedDays is num
        ? storedDays.round()
        : int.tryParse(storedDays?.toString() ?? '');
    _goalDaysController.text =
        '${goalDays != null && goalDays >= 5 ? goalDays : 30}';
    _answers['frictions'] = onboardingFrictions(_answers);
    _answers.remove('friction');
    if (_answers['tone'] == 'firm') _answers['tone'] = 'hard';
    for (final friction in _selectedFrictions) {
      if (!_isPresetFriction(friction)) {
        _customFrictionSelected = true;
        _frictionController.text = friction;
        break;
      }
    }
  }

  Future<void> _save(String key, Object? value) async {
    if (mounted) {
      setState(() {
        if (value == null ||
            value is String && value.trim().isEmpty ||
            value is List && value.isEmpty) {
          _answers.remove(key);
        } else {
          _answers[key] = value;
        }
      });
    }
    await ref.read(onboardingRepositoryProvider).saveAnswer(key, value);
  }

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_page >= _lastPage) return;
    setState(() {
      _movingForward = true;
      _page++;
    });
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_page == 0) return;
    setState(() {
      _movingForward = false;
      _page--;
    });
  }

  Future<void> _continueName() async {
    final name = _nameController.text.trim();
    final error = _textError(name, field: 'name', min: 1, max: 30);
    if (error != null) {
      setState(() => _nameError = error);
      HapticFeedback.warningNotification();
      return;
    }

    setState(() => _nameError = null);
    await _save('name', name);
    await UserController().updateUserName(name);
    ref.invalidate(userProvider);
    if (mounted) _next();
  }

  Future<void> _continueGoal() async {
    final goal = _goalController.text.trim();
    final error = _textError(goal, field: 'goal', min: 6, max: 80);
    if (error != null) {
      setState(() => _goalError = error);
      HapticFeedback.warningNotification();
      return;
    }

    setState(() => _goalError = null);
    await _save('primary_goal', goal);
    if (mounted) _next();
  }

  Future<void> _continueGoalDays() async {
    final days = int.tryParse(_goalDaysController.text);
    if (days == null || days < 5) {
      setState(() => _goalDaysError = 'Enter at least 5 days.');
      HapticFeedback.warningNotification();
      return;
    }

    setState(() => _goalDaysError = null);
    await _save('goal_days', days);
    if (mounted) _next();
  }

  String? _textError(
    String value, {
    required String field,
    required int min,
    required int max,
  }) {
    if (value.runes.length < min) {
      if (field == 'name') return 'Enter the name you want us to use.';
      if (field == 'friction') return 'Name the pattern in a few words.';
      return 'Make the result a little more specific.';
    }
    if (value.runes.length > max) {
      return 'Keep your $field under $max characters.';
    }
    if (field == 'name' && (value.contains('\n') || value.contains('\r'))) {
      return 'Use one line for your name.';
    }
    if (value.runes.any(
      (rune) => rune < 32 && !(field == 'goal' && rune == 10),
    )) {
      return 'Remove unsupported characters.';
    }
    return null;
  }

  Future<void> _selectCategory(String category) async {
    setState(() => _categoryError = null);
    await _save('categories', [category]);
  }

  List<String> get _selectedCategories => List<String>.from(
        (_answers['categories'] as List? ?? const []).map((value) => '$value'),
      );

  Future<void> _continueCategories() async {
    if (_selectedCategories.isEmpty) {
      setState(() => _categoryError = 'Choose one area.');
      HapticFeedback.warningNotification();
      return;
    }
    _next();
  }

  Future<void> _continueFriction() async {
    final selected = _selectedFrictions.where(_isPresetFriction).toList();
    if (_customFrictionSelected) {
      final friction = _frictionController.text.trim();
      final error = _textError(friction, field: 'friction', min: 3, max: 50);
      if (error != null) {
        setState(() => _frictionError = error);
        HapticFeedback.warningNotification();
        return;
      }
      selected.add(friction);
    }
    setState(() => _frictionError = null);
    await _save('frictions', selected);
    if (mounted) _next();
  }

  Future<void> _toggleFriction(String friction) async {
    final selected = _selectedFrictions;
    if (friction == 'Something else') {
      setState(() {
        _customFrictionSelected = !_customFrictionSelected;
        _frictionError = null;
      });
      if (!_customFrictionSelected) {
        selected.removeWhere((value) => !_isPresetFriction(value));
        _frictionController.clear();
        await _save('frictions', selected);
      }
      return;
    }
    selected.contains(friction)
        ? selected.remove(friction)
        : selected.add(friction);
    await _save('frictions', selected);
  }

  Future<void> _continueSchedule() async {
    final reminder = _reminder ?? const Reminder();
    final error = reminder.validationError;
    if (error != null) {
      setState(() => _scheduleError = error);
      HapticFeedback.warningNotification();
      return;
    }
    setState(() {
      _scheduleBusy = true;
      _scheduleError = null;
    });
    try {
      final saved =
          await ref.read(reminderControllerProvider).saveSchedule(reminder);
      ref.invalidate(reminderProvider);
      if (!mounted) return;
      setState(() => _reminder = saved);
      _next();
    } catch (_) {
      if (mounted) {
        setState(() => _scheduleError = 'Could not save. Try again.');
      }
    } finally {
      if (mounted) setState(() => _scheduleBusy = false);
    }
  }

  Future<void> _enableNotifications() async {
    if (_permissionBusy) return;
    setState(() {
      _permissionBusy = true;
      _permissionDenied = false;
      _permissionError = null;
    });

    try {
      final granted =
          await ref.read(reminderControllerProvider).enableNotifications();
      if (!mounted) return;
      await _save('notifications', granted);
      if (!mounted) return;
      setState(() {
        _permissionDenied = !granted;
        _permissionError =
            granted ? null : 'Notifications are off. Your schedule is saved.';
      });
      if (granted) _next();
    } catch (_) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _permissionError =
              'We could not schedule your prompts. Check Settings and retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _permissionBusy = false);
    }
  }

  Future<void> _skipNotifications() async {
    try {
      await ref.read(reminderControllerProvider).disableNotifications();
    } catch (_) {
      // The user can still finish onboarding; settings remain available later.
    }
    await _save('notifications', false);
    if (mounted) _next();
  }

  Future<void> _complete() async {
    _answers['onboarding_version'] = 5;
    await ref.read(onboardingRepositoryProvider).complete(_answers);
    if (!mounted) return;
    HapticFeedback.successNotification();
    context.go(
      !subscriptionPlatformSupported || ref.read(subscribedProvider)
          ? '/quotes'
          : '/subscription',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _answersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: MyColors.background,
            body: Center(
              child: CircularProgressIndicator(color: MyColors.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _canvas,
          resizeToAvoidBottomInset: true,
          body: ColoredBox(
            color: _canvas,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey(_page);
                final direction = _movingForward ? 1.0 : -1.0;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(
                        (incoming ? direction : -direction) * 0.055,
                        0,
                      ),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_page),
                child: _buildPage(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 0:
        return _promisePage();
      case 1:
        return _namePage();
      case 2:
        return _categoriesPage();
      case 3:
        return _goalPage();
      case 4:
        return _goalDaysPage();
      case 5:
        return _frictionPage();
      case 6:
        return _tonePage();
      case 7:
        return _schedulePage();
      case 8:
        return _permissionPage();
      case 9:
        return _contractPage();
      case 10:
        return _valuePage();
      default:
        return _pricePerspectivePage();
    }
  }

  Widget _promisePage() {
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: null,
      eyebrow: 'MOTIVATION WITHOUT THE BS',
      headline: 'Your excuses are about to get called out.',
      footer: _PrimaryButton(label: 'I can handle it', onTap: _next),
      children: [
        Image.asset(
          'assets/images/onboarding/mascot_effort.png',
          height: 190,
          fit: BoxFit.contain,
          semanticLabel: 'A man pushing a block uphill',
        ),
        const SizedBox(height: 10),
        Text(
          'No gentle affirmations. No empty hype. You’ll get hard, no-BS '
          'quotes and reminders that call out your excuses and push you back '
          'to work.',
          style: MyTypography.body1.copyWith(
            color: _quiet,
            fontSize: 18,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _namePage() {
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'MAKE IT PERSONAL',
      headline: 'What should we call you?',
      footer: _PrimaryButton(label: 'Continue', onTap: _continueName),
      children: [
        Text(
          'Your first name is enough. We’ll use it in your reminders.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 34),
        TextField(
          key: const Key('onboarding-name'),
          controller: _nameController,
          autofocus: false,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 30,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _continueName(),
          cursorColor: _gold,
          style: MyTypography.h2.copyWith(
            color: _paper,
            fontFamily: MyTypography.quoteFontFamily,
            fontSize: 30,
          ),
          decoration: _fieldDecoration(
            label: 'Your name',
            error: _nameError,
          ),
        ),
      ],
    );
  }

  Widget _categoriesPage() {
    final selected = _selectedCategories;
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'DIRECTION',
      headline: 'Where do you want results?',
      protocolNote: 'GOOD TO HAVE YOU  ·  $_firstName',
      footer: _PrimaryButton(label: 'Continue', onTap: _continueCategories),
      children: [
        Text(
          'Choose the one area your goal belongs to.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _goalCategories
                  .map(
                    (category) => SizedBox(
                      width: tileWidth,
                      child: _ChoiceTile(
                        icon: _categoryIcon(category),
                        label: category,
                        selected: selected.contains(category),
                        onTap: () => _selectCategory(category),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        if (_categoryError != null) ...[
          const SizedBox(height: 14),
          _ErrorText(_categoryError!),
        ],
      ],
    );
  }

  Widget _goalPage() {
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'THE GOAL',
      headline: 'What exactly are you going after?',
      protocolNote:
          'FOCUS  ·  ${_selectedCategories.join('  ·  ').toUpperCase()}',
      footer: _PrimaryButton(label: 'That’s the goal', onTap: _continueGoal),
      children: [
        Text(
          'Make it specific enough that you’ll know when it’s done.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 28),
        TextField(
          key: const Key('onboarding-goal'),
          controller: _goalController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          maxLines: 1,
          maxLength: 80,
          onChanged: (_) {
            if (_goalError != null) setState(() => _goalError = null);
          },
          onSubmitted: (_) => _continueGoal(),
          cursorColor: _gold,
          style: MyTypography.h3.copyWith(
            color: _paper,
            fontFamily: MyTypography.quoteFontFamily,
            fontSize: 22,
            height: 1.35,
          ),
          decoration: _fieldDecoration(
            label: 'e.g. Ship my first product',
            error: _goalError,
          ),
        ),
      ],
    );
  }

  Widget _goalDaysPage() {
    final sliderValue = _goalDays.clamp(5, 100).toDouble();
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'COMMITMENT',
      headline: 'How many days are you giving yourself?',
      protocolNote: 'GOAL  ·  $_goal',
      footer: _PrimaryButton(
        label: 'Commit to $_goalDays days',
        onTap: _continueGoalDays,
      ),
      children: [
        Text(
          'Pick a deadline. We’ll keep the pressure on until you get there.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 28),
        TextField(
          key: const Key('onboarding-goal-days'),
          controller: _goalDaysController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            final days = int.tryParse(value);
            setState(() {
              if (days != null) _answers['goal_days'] = days;
              _goalDaysError = null;
            });
          },
          onSubmitted: (_) => _continueGoalDays(),
          cursorColor: _goalGreen,
          textAlign: TextAlign.center,
          style: MyTypography.h1.copyWith(
            color: _goalGreen,
            fontFamily: MyTypography.displayFontFamily,
            fontSize: 52,
          ),
          decoration: _fieldDecoration(
            label: 'Number of days',
            error: _goalDaysError,
          ),
        ),
        const SizedBox(height: 26),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _goalGreen,
            inactiveTrackColor: _panel,
            thumbColor: _paper,
            overlayColor: _goalGreen.withValues(alpha: 0.14),
            trackHeight: 6,
          ),
          child: Slider(
            key: const Key('onboarding-goal-days-slider'),
            value: sliderValue,
            min: 5,
            max: 100,
            divisions: 95,
            label: '${sliderValue.round()} days',
            semanticFormatterCallback: (value) => '${value.round()} days',
            onChanged: (value) {
              final days = value.round();
              HapticFeedback.selectionClick();
              setState(() {
                _answers['goal_days'] = days;
                _goalDaysController.text = '$days';
                _goalDaysError = null;
              });
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '5 days',
                style: MyTypography.body2.copyWith(color: _quiet),
              ),
            ),
            Expanded(
              child: Text(
                '100 days',
                textAlign: TextAlign.right,
                style: MyTypography.body2.copyWith(color: _quiet),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _frictionPage() {
    final selected = _selectedFrictions;
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'THE OBSTACLE',
      headline: 'What usually gets in the way?',
      protocolNote: 'COMMITMENT  ·  $_goalDays DAYS',
      footer: _PrimaryButton(
        label: 'Continue',
        onTap: selected.isEmpty && !_customFrictionSelected
            ? null
            : _continueFriction,
      ),
      children: [
        Center(
          child: Image.asset(
            'assets/images/onboarding/mascot_breakthrough.png',
            height: 132,
            fit: BoxFit.contain,
            semanticLabel: 'A man breaking through a rope barrier',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pick every pattern that tends to pull you off course.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 24),
        ..._frictions.map(
          (friction) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoiceRow(
              label: friction,
              selected: friction == 'Something else'
                  ? _customFrictionSelected
                  : selected.contains(friction),
              onTap: () => _toggleFriction(friction),
            ),
          ),
        ),
        if (_customFrictionSelected) ...[
          const SizedBox(height: 2),
          TextField(
            key: const Key('onboarding-custom-friction'),
            controller: _frictionController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: 50,
            onChanged: (_) {
              if (_frictionError != null) {
                setState(() => _frictionError = null);
              }
            },
            onSubmitted: (_) => _continueFriction(),
            cursorColor: _gold,
            style: MyTypography.body1.copyWith(color: _paper, fontSize: 18),
            decoration: _fieldDecoration(
              label: 'Name the pattern',
              error: _frictionError,
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        Text(
          'That’s the obstacle. Not an excuse.',
          style: MyTypography.body2.copyWith(color: _quiet),
        ),
      ],
    );
  }

  Widget _tonePage() {
    final tone = _answers['tone']?.toString();
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'PRESSURE',
      headline: 'How hard should we push?',
      protocolNote: 'OBSTACLE  ·  ${_friction.toUpperCase()}',
      footer: _PrimaryButton(
        label: tone == null ? 'Choose a pressure' : 'Use ${_titleCase(tone)}',
        onTap: tone == null ? null : _next,
      ),
      children: [
        Text(
          'Both are direct. Pick the level you’ll actually respond to.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: _ToneCard(
                title: 'Hard',
                description: 'Straight. Focused.',
                selected: tone == 'hard',
                onTap: () => _save('tone', 'hard'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToneCard(
                title: 'Extra Hard',
                description: 'Blunt. Relentless.',
                selected: tone == 'extra hard',
                onTap: () => _save('tone', 'extra hard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _NotificationPreview(message: _pressureMessage),
      ],
    );
  }

  Widget _schedulePage() {
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'THE SCHEDULE',
      headline: 'When should we call you out?',
      protocolNote:
          'TONE  ·  ${_titleCase(_answers['tone']?.toString() ?? 'hard')}',
      footer: _PrimaryButton(
        label: _scheduleBusy ? 'Saving…' : 'Save my schedule',
        onTap: _scheduleBusy ? null : _continueSchedule,
      ),
      children: [
        Text(
          'Choose the days, time window, and number of reminders.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 22),
        ReminderWidget(
          initialValue: _reminder ?? const Reminder(),
          showHeader: false,
          showAction: false,
          onChanged: (reminder) {
            _reminder = reminder;
            if (_scheduleError != null) {
              setState(() => _scheduleError = null);
            }
          },
        ),
        if (_scheduleError != null) ...[
          const SizedBox(height: 14),
          _ErrorText(_scheduleError!),
        ],
      ],
    );
  }

  Widget _permissionPage() {
    final reminder = _reminder;
    final summary = reminder == null
        ? 'We’ll follow the schedule you just set.'
        : '${reminder.count} ${reminder.count == 1 ? 'prompt' : 'prompts'} '
            'on ${_daysSummary(reminder.weekdays)}, between '
            '${_formatMinute(context, reminder.startMinute)} and '
            '${_formatMinute(context, reminder.endMinute)}.';

    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'DELIVERY',
      headline: 'Ready to be held to it?',
      protocolNote: reminder == null
          ? null
          : 'WINDOW LOCKED  ·  ${_daysSummary(reminder.weekdays)}',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryButton(
            label: _permissionBusy ? 'Requesting…' : 'Turn on reminders',
            onTap: _permissionBusy ? null : _enableNotifications,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _permissionBusy ? null : _skipNotifications,
            child: Text(
              _permissionDenied ? 'Continue without notifications' : 'Not now',
              style: MyTypography.body1.copyWith(color: _quiet),
            ),
          ),
        ],
      ),
      children: [
        Text(
          summary,
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 30),
        _NotificationPreview(message: _deliveryMessage),
        if (_permissionError != null) ...[
          const SizedBox(height: 20),
          _ErrorText(_permissionError!),
          if (_permissionDenied)
            TextButton(
              onPressed: () =>
                  ref.read(reminderControllerProvider).openSystemSettings(),
              child: const Text('Open Settings'),
            ),
        ],
      ],
    );
  }

  Widget _contractPage() {
    final reminder = _reminder ?? const Reminder();
    final focus = _selectedCategories.join(' · ');
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'YOUR COMMITMENT',
      headline: '$_firstName, this is the deal.',
      footer: _PrimaryButton(label: 'See what this is worth', onTap: _next),
      children: [
        Center(
          child: Image.asset(
            'assets/images/onboarding/mascot_victory.png',
            height: 105,
            fit: BoxFit.contain,
            semanticLabel: 'A man standing on stacked blocks',
          ),
        ),
        const SizedBox(height: 12),
        _ProtocolDocument(
          rows: [
            _ProtocolRow('OUTCOME', _goal),
            _ProtocolRow('TIMELINE', '$_goalDays days'),
            _ProtocolRow('FOCUS', focus.isEmpty ? 'Not set' : focus),
            _ProtocolRow('KNOWN FRICTION', _friction),
            _ProtocolRow(
              'PRESSURE',
              _titleCase(_answers['tone']?.toString() ?? 'hard'),
            ),
            _ProtocolRow(
              'WINDOW',
              '${_daysSummary(reminder.weekdays)} · '
                  '${_formatMinute(context, reminder.startMinute)}–'
                  '${_formatMinute(context, reminder.endMinute)} · '
                  '${reminder.count} prompts',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'The plan is set. Now earn the result.',
          style: MyTypography.h3.copyWith(
            color: _paper,
            fontFamily: MyTypography.quoteFontFamily,
            height: 1.22,
          ),
        ),
      ],
    );
  }

  Widget _valuePage() {
    final focusHours =
        (_goalDays / 3).toStringAsFixed(_goalDays % 3 == 0 ? 0 : 1);
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'YOUR TIME',
      headline: 'Your time is worth more than this app.',
      protocolNote: 'YOUR OUTCOME  ·  ${_goal.toUpperCase()}',
      footer: _PrimaryButton(label: 'Put that in perspective', onTap: _next),
      children: [
        Text(
          'You gave yourself $_goalDays days. Protecting just 20 focused '
          'minutes a day would put:',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _hairline),
          ),
          child: Column(
            children: [
              Text(
                'FOCUSED TIME BACK ON YOUR GOAL',
                textAlign: TextAlign.center,
                style: MyTypography.caption1.copyWith(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$focusHours HOURS',
                textAlign: TextAlign.center,
                style: MyTypography.h1.copyWith(
                  color: _paper,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'toward “$_goal” before your deadline.',
                textAlign: TextAlign.center,
                style: MyTypography.body1.copyWith(
                  color: _quiet,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'That is not a promise. It is the value of showing up for the '
          'schedule you already built.',
          style: MyTypography.body1.copyWith(
            color: _paper,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _pricePerspectivePage() {
    return _PageFrame(
      page: _page,
      pageCount: _lastPage + 1,
      onBack: _back,
      eyebrow: 'BEFORE THE PRICE',
      headline: 'Another $_goalDays days of drift costs more.',
      protocolNote: 'KNOWN FRICTION  ·  ${_friction.toUpperCase()}',
      footer: _PrimaryButton(label: 'Show me the price', onTap: _complete),
      children: [
        Text(
          'The price on the next screen is high. Compare it to delaying '
          '“$_goal” again—not to another app icon.',
          style: MyTypography.body1.copyWith(color: _quiet, height: 1.45),
        ),
        const SizedBox(height: 26),
        _ProtocolDocument(
          rows: [
            const _ProtocolRow('NOT FOR', 'More quotes to scroll past'),
            const _ProtocolRow(
              'FOR',
              'A system built around your goal, friction, and schedule',
            ),
            const _ProtocolRow(
              'WORTH IT IF',
              'Protecting this goal matters more than staying comfortable',
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'No app can promise the result. Only continue if you are ready to '
          'use it.',
          style: MyTypography.h3.copyWith(
            color: _paper,
            fontFamily: MyTypography.quoteFontFamily,
            height: 1.22,
          ),
        ),
      ],
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.page,
    required this.pageCount,
    required this.onBack,
    required this.eyebrow,
    required this.headline,
    required this.children,
    this.footer,
    this.protocolNote,
  });

  final int page;
  final int pageCount;
  final VoidCallback? onBack;
  final String eyebrow;
  final String headline;
  final List<Widget> children;
  final Widget? footer;
  final String? protocolNote;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
                child: _ProgressHeader(
                  page: page,
                  pageCount: pageCount,
                  onBack: onBack,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: page == 0 ? 30 : 22),
                      if (protocolNote != null) ...[
                        _ProtocolLock(protocolNote!),
                        const SizedBox(height: 26),
                      ] else if (page != 0)
                        const SizedBox(height: 10),
                      Text(
                        eyebrow,
                        style: MyTypography.caption1.copyWith(
                          color: _gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TypedHeadline(
                        key: ValueKey('$page:$headline'),
                        text: headline,
                      ),
                      const SizedBox(height: 22),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (footer != null)
                DecoratedBox(
                  decoration: const BoxDecoration(color: _canvas),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 14, 26, 12),
                    child: footer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypedHeadline extends StatefulWidget {
  const _TypedHeadline({super.key, required this.text});

  final String text;

  @override
  State<_TypedHeadline> createState() => _TypedHeadlineState();
}

class _TypedHeadlineState extends State<_TypedHeadline> {
  static const _characterSpeed = Duration(milliseconds: 28);
  static const _hapticInterval = Duration(milliseconds: 84);

  Timer? _hapticTimer;
  DateTime? _startedAt;
  var _lastIndex = 0;
  var _motionDisabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_motionDisabled == disabled && _startedAt != null) return;
    _motionDisabled = disabled;
    _hapticTimer?.cancel();
    if (!disabled) _startHaptics();
  }

  void _startHaptics() {
    final runes = widget.text.runes.toList();
    _startedAt = DateTime.now();
    _lastIndex = 0;
    _hapticTimer = Timer.periodic(_hapticInterval, (timer) {
      final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
      final nextIndex = (elapsed ~/ _characterSpeed.inMilliseconds).clamp(
        0,
        runes.length,
      );
      final crossedWordBoundary = runes
          .sublist(_lastIndex, nextIndex)
          .any((rune) => rune == 32 || rune == 10);
      _lastIndex = nextIndex;
      if (crossedWordBoundary) HapticFeedback.selectionClick();
      if (nextIndex == runes.length) timer.cancel();
    });
  }

  void _stopHaptics() => _hapticTimer?.cancel();

  @override
  void dispose() {
    _hapticTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final style = MyTypography.h1.copyWith(
      color: _paper,
      fontFamily: MyTypography.displayFontFamily,
      fontSize: scale > 1.3 ? 36 : 43,
      fontWeight: FontWeight.w400,
      height: 1.02,
      letterSpacing: -0.7,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: '${widget.text}▍', style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        return Semantics(
          header: true,
          label: widget.text,
          excludeSemantics: true,
          child: SizedBox(
            height: painter.height,
            child: Align(
              alignment: Alignment.topLeft,
              child: _motionDisabled
                  ? Text(widget.text, textAlign: TextAlign.left, style: style)
                  : AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          widget.text,
                          textAlign: TextAlign.left,
                          textStyle: style,
                          speed: _characterSpeed,
                          cursor: '▍',
                        ),
                      ],
                      isRepeatingAnimation: false,
                      displayFullTextOnTap: true,
                      stopPauseOnTap: true,
                      onTap: _stopHaptics,
                      onFinished: _stopHaptics,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ProtocolLock extends StatelessWidget {
  const _ProtocolLock(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: _gold, width: 2)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MyTypography.caption1.copyWith(
            color: _quiet,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.page,
    required this.pageCount,
    required this.onBack,
  });

  final int page;
  final int pageCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: onBack == null
                    ? null
                    : IconButton(
                        tooltip: 'Back',
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          side: const BorderSide(color: _hairline),
                          shape: const CircleBorder(),
                        ),
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back, size: 19),
                        color: _paper,
                      ),
              ),
              const SizedBox(width: 14),
              const Expanded(child: _Wordmark()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Step ${page + 1} of $pageCount',
          child: Row(
            children: List.generate(
              pageCount,
              (index) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index == pageCount - 1 ? 0 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: index <= page ? MyColors.primary : MyColors.surface,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'NO EXCUSES.',
      maxLines: 1,
      overflow: TextOverflow.fade,
      style: MyTypography.caption1.copyWith(
        color: MyColors.ink,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(60),
          backgroundColor: MyColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MyColors.disabled,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? MyColors.primary : _panel,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: selected ? Colors.white : _quiet,
                      size: 18,
                    ),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? Colors.white : _quiet,
                      size: 17,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  maxLines: 2,
                  style: MyTypography.body2.copyWith(
                    color: selected ? Colors.white : _paper,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? MyColors.primary : _panel,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: MyTypography.body1.copyWith(
                      color: selected ? Colors.white : _paper,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.arrow_forward,
                  color: selected ? Colors.white : _quiet,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToneCard extends StatelessWidget {
  const _ToneCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? MyColors.primary : _panel,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 106),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: MyTypography.h3.copyWith(
                          color: selected ? Colors.white : _paper,
                          fontFamily: MyTypography.quoteFontFamily,
                        ),
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected ? Colors.white : _quiet,
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: MyTypography.body2.copyWith(
                    color: selected ? Colors.white70 : _quiet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'N',
                    style: MyTypography.caption1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'NO EXCUSES',
                    style: MyTypography.caption1.copyWith(
                      color: _paper,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Text(
                  'now',
                  style: MyTypography.caption1.copyWith(color: _quiet),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: MyTypography.body1.copyWith(
                color: _paper,
                fontSize: 16,
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolDocument extends StatelessWidget {
  const _ProtocolDocument({required this.rows});

  final List<_ProtocolRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const Divider(height: 25, color: _hairline),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 94,
                    child: Text(
                      rows[index].label,
                      style: MyTypography.caption1.copyWith(
                        color: MyColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[index].value,
                      style: MyTypography.body2.copyWith(
                        color: _paper,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProtocolRow {
  const _ProtocolRow(this.label, this.value);

  final String label;
  final String value;
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: MyTypography.body2.copyWith(
          color: MyColors.pink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required String? error,
}) {
  return InputDecoration(
    hintText: label,
    errorText: error,
    filled: true,
    fillColor: _panel,
    hintStyle: MyTypography.body1.copyWith(color: _quiet),
    counterText: '',
    errorStyle: MyTypography.body2.copyWith(color: MyColors.pink),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: MyColors.primary, width: 1.5),
    ),
  );
}

String _titleCase(String value) => value
    .split(' ')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Career':
      return Icons.trending_up;
    case 'Business & Entrepreneurship':
      return Icons.business_center_outlined;
    case 'Fitness':
      return Icons.fitness_center;
    case 'Education & Skills':
      return Icons.school_outlined;
    case 'Money & Finance':
      return Icons.account_balance_outlined;
    case 'Personal Growth':
      return Icons.self_improvement;
    default:
      return Icons.more_horiz;
  }
}

String _daysSummary(List<int> weekdays) {
  if (weekdays.length == 7) return 'every day';
  if (weekdays.length == 5 && weekdays.every((day) => day <= DateTime.friday)) {
    return 'Monday–Friday';
  }
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return weekdays.map((day) => names[day - 1]).join(', ');
}

String _formatMinute(BuildContext context, int minute) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
  );
}
