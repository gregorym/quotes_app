import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:quotes_app/controllers/user_controller.dart';
import 'package:quotes_app/repositories/onboarding_repository.dart';

const _appName = 'No Excuses';
const _bg = Color(0x00000000);
const _surface = Color(0xE016120C);
const _ink = Color(0xFFFFFFFF);
const _muted = Color(0xFFC9BCA2);
const _green = Color(0xFF8F641D);
const _teal = Color(0xFFDFC16A);
const _orange = Color(0xFFE0A32D);
const _pink = Color(0xFFE07A7A);
const _disabled = Color(0xFF5D5549);
const _darkPanel = Color(0xF20A0704);
const _selectedPill = Color(0xFF332512);
const _ctaWidth = 300.0;
const _ctaHeight = 58.0;
const _pillWidth = 262.0;

class OnboardingTemplate extends ConsumerStatefulWidget {
  const OnboardingTemplate({super.key});

  @override
  ConsumerState<OnboardingTemplate> createState() => _OnboardingTemplateState();
}

class _OnboardingTemplateState extends ConsumerState<OnboardingTemplate> {
  final _introKey = GlobalKey<IntroductionScreenState>();
  final _answers = <String, dynamic>{};
  final _nameController = TextEditingController();

  late final Future<void> _answersFuture;
  var _page = 0;
  var _likes = 0;
  var _trialSheetSeen = false;
  var _loadingStarted = false;

  String get _firstName {
    final name = _answers['name']?.toString().trim();
    return name == null || name.isEmpty ? 'Greg' : name.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _answersFuture = _loadAnswers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAnswers() async {
    final stored = await ref.read(onboardingRepositoryProvider).fetchAnswers();
    _answers.addAll(stored);
    _nameController.text = _answers['name']?.toString() ?? '';
    _likes = int.tryParse(_answers['liked_punchlines']?.toString() ?? '') ?? 0;
  }

  Future<void> _save(String key, Object? value) async {
    setState(() {
      if (value == null ||
          value is String && value.trim().isEmpty ||
          value is List && value.isEmpty) {
        _answers.remove(key);
      } else {
        _answers[key] = value;
      }
    });
    await ref.read(onboardingRepositoryProvider).saveAnswer(key, value);
  }

  void _next() => _introKey.currentState?.next();

  void _back() => _introKey.currentState?.previous();

  Future<void> _saveAndNext(String key, Object? value) async {
    await _save(key, value);
    if (mounted) _next();
  }

  Future<void> _continueName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await _save('name', name);
    await UserController().updateUserName(name);
    ref.invalidate(userProvider);
    if (mounted) _next();
  }

  Future<void> _likePunchline() async {
    final nextLikes = (_likes + 1).clamp(0, 3);
    setState(() => _likes = nextLikes);
    await _save('liked_punchlines', nextLikes);
    if (mounted && nextLikes == 3) _next();
  }

  Future<void> _finish({required bool trial}) async {
    await _save('trial_started', trial);
    await ref.read(onboardingRepositoryProvider).complete(_answers);
    if (!mounted) return;
    context.go('/quotes');
  }

  void _startLoading() {
    if (_loadingStarted) return;
    _loadingStarted = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _page == 11) _next();
    });
  }

  Future<void> _showTrialSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      builder: (context) => _TrialSheet(
        onClose: () => Navigator.pop(context),
        onStart: () async {
          Navigator.pop(context);
          await _finish(trial: true);
        },
      ),
    );
    if (mounted) setState(() => _trialSheetSeen = true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _answersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _green)),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          resizeToAvoidBottomInset: false,
          body: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: IntroductionScreen(
              key: _introKey,
              rawPages: _pages,
              showBottomPart: false,
              showDoneButton: false,
              showNextButton: false,
              resizeToAvoidBottomInset: false,
              globalBackgroundColor: _bg,
              onChange: (page) {
                setState(() => _page = page);
                if (page == 11) _startLoading();
              },
            ),
          ),
        );
      },
    );
  }

  List<Widget> get _pages => [
        _welcome(),
        _source(),
        _name(),
        _socialProof(),
        _likePunchlines(),
        _notifications(),
        _singleChoice(
          index: 6,
          progress: 0.10,
          title: 'How old are you?',
          subtitle: 'Helps personalize your experience',
          answerKey: 'age',
          options: const [
            'Under 18 years old',
            '18-24 years old',
            '25-34 years old',
            '35-44 years old',
            '45-54 years old',
            '55+ years old',
          ],
        ),
        _singleChoice(
          index: 7,
          progress: 0.25,
          title: 'Which team are you on?',
          subtitle: 'Helps personalize your experience',
          answerKey: 'gender',
          options: const ['Male', 'Female', "It's not that simple!"],
        ),
        _singleChoice(
          index: 8,
          progress: 0.40,
          title: "What's your professional\nsituation?",
          subtitle: 'Choose the option that best describes you',
          answerKey: 'professional_situation',
          showSkip: true,
          topGap: 42,
          options: const [
            'Student',
            'Job seeker',
            'Employee',
            'Freelancer',
            'Retired',
            'Stay-at-home parent',
            'Other',
          ],
        ),
        _habit(),
        _categories(),
        _loading(),
        _paywall(),
      ];

  Widget _welcome() {
    return _Screen(
      child: Column(
        children: [
          const Spacer(flex: 16),
          Text(_appName, style: _titleStyle(38)),
          const SizedBox(height: 10),
          Text('Your new mental hygiene.', style: _bodyStyle(22)),
          const Spacer(flex: 12),
          _heroIcon(Icons.sentiment_satisfied_alt, size: 88),
          const Spacer(flex: 20),
          _primaryButton('Change my world', color: _green, onTap: _next),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              text: 'by continuing, you accept the ',
              children: [
                TextSpan(
                  text: 'terms of use',
                  style: _bodyStyle(12).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '\nand '),
                TextSpan(
                  text: 'privacy policy',
                  style: _bodyStyle(12).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: _bodyStyle(12),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _source() {
    final options = [
      'TikTok',
      'Instagram',
      'Facebook',
      'App Store',
      'Friends / Family',
      'My therapist / coach /\nshaman',
      'Other',
    ];

    return _Screen(
      child: Column(
        children: [
          const SizedBox(height: 44),
          _heroIcon(Icons.menu_book, size: 54),
          const SizedBox(height: 12),
          Text(
            'How did you hear about\n$_appName?',
            textAlign: TextAlign.center,
            style: _titleStyle(24),
          ),
          const SizedBox(height: 22),
          Text('Select an option to continue', style: _bodyStyle(15)),
          const SizedBox(height: 34),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _optionPill(
                option,
                selected: _answers['source'] == option,
                onTap: () =>
                    _saveAndNext('source', option.replaceAll('\n', ' ')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _name() {
    final canContinue = _nameController.text.trim().isNotEmpty;

    return _Screen(
      child: Column(
        children: [
          const SizedBox(height: 68),
          _heroIcon(Icons.person_outline, size: 60),
          const SizedBox(height: 18),
          Text("What's your name?", style: _titleStyle(32)),
          const SizedBox(height: 94),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _nameController,
              onChanged: (value) => setState(() {}),
              textAlign: TextAlign.left,
              cursorColor: _ink,
              style: _titleStyle(30),
              decoration: InputDecoration(
                hintText: 'Enter your first name',
                hintStyle: _bodyStyle(24).copyWith(color: Colors.white38),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _ink, width: 2),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _ink, width: 2),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _ink, width: 2),
                ),
              ),
            ),
          ),
          const Spacer(),
          _primaryButton(
            canContinue ? 'Continue' : 'Fill in to continue',
            color: canContinue ? _green : _disabled,
            onTap: canContinue ? _continueName : null,
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _socialProof() {
    return _Screen(
      child: Column(
        children: [
          const SizedBox(height: 150),
          Text(
            "You're truly in the right\nplace, $_firstName!",
            textAlign: TextAlign.center,
            style: _titleStyle(34),
          ),
          const SizedBox(height: 112),
          Text('140,000+', style: _titleStyle(46).copyWith(color: _orange)),
          const SizedBox(height: 10),
          Text(
            'people have downloaded $_appName\nsince its launch in May 2025.',
            textAlign: TextAlign.center,
            style: _bodyStyle(18),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: _pink, size: 20),
              const SizedBox(width: 24),
              Text('4.8/5', style: _titleStyle(42).copyWith(color: _pink)),
              const SizedBox(width: 24),
              const Icon(Icons.favorite, color: _pink, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'is our average rating on the App Store\nfrom over 2,000 reviews <3',
            textAlign: TextAlign.center,
            style: _bodyStyle(17),
          ),
          const Spacer(),
          _primaryButton('Continue', color: _teal, onTap: _next),
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  Widget _likePunchlines() {
    return _Screen(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -200) _next();
        },
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text('Like 3 punchlines', style: _bodyStyle(18)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  child: Icon(
                    index < _likes ? Icons.favorite : Icons.favorite_border,
                    size: 24,
                    color: _ink,
                  ),
                ),
              ),
            ),
            const Spacer(flex: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                "Don’t believe every\nthought. Some are just\nechoes.",
                textAlign: TextAlign.center,
                style: _titleStyle(31),
              ),
            ),
            const SizedBox(height: 72),
            GestureDetector(
              onTap: _likePunchline,
              child: Icon(
                _likes > 0 ? Icons.favorite : Icons.favorite_border,
                color: _ink,
                size: 44,
              ),
            ),
            const Spacer(flex: 6),
            Text('Swipe to skip', style: _bodyStyle(20)),
            const SizedBox(height: 22),
            const Icon(Icons.keyboard_arrow_up, size: 42, color: _ink),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  Widget _notifications() {
    return _Screen(
      child: Column(
        children: [
          const SizedBox(height: 44),
          _heroIcon(Icons.fitness_center, size: 68),
          const SizedBox(height: 12),
          Text(
            'Get strength delivered during\nthe day',
            textAlign: TextAlign.center,
            style: _titleStyle(25),
          ),
          const SizedBox(height: 40),
          _notificationPreview(),
          const SizedBox(height: 34),
          _notificationControls(),
          const Spacer(),
          _primaryButton(
            'Enable notifications',
            color: _green,
            onTap: () => _saveAndNext('notifications', true),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => _saveAndNext('notifications', false),
            child:
                Text('Not now', style: _bodyStyle(20).copyWith(color: _muted)),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _singleChoice({
    required int index,
    required double progress,
    required String title,
    required String subtitle,
    required String answerKey,
    required List<String> options,
    bool showSkip = false,
    double topGap = 42,
  }) {
    final answer = _answers[answerKey]?.toString();
    final canContinue = answer != null && answer.isNotEmpty;

    return _Screen(
      child: Column(
        children: [
          _TopBar(
            progress: progress,
            showSkip: showSkip,
            onBack: _back,
            onSkip: _next,
          ),
          SizedBox(height: topGap),
          if (!showSkip) _heroIcon(Icons.menu_book, size: 54),
          if (!showSkip) const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: _titleStyle(29)),
          const SizedBox(height: 15),
          Text(subtitle, textAlign: TextAlign.center, style: _bodyStyle(18)),
          const SizedBox(height: 28),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _optionPill(
                option,
                selected: answer == option,
                onTap: () => _save(answerKey, option),
              ),
            ),
          ),
          const Spacer(),
          _primaryButton(
            'Continue',
            color: canContinue ? _teal : _disabled,
            onTap: canContinue ? _next : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _habit() {
    return _Screen(
      child: Column(
        children: [
          const SizedBox(height: 125),
          _heroIcon(Icons.local_fire_department, size: 76),
          const SizedBox(height: 54),
          Text(
            'Build a real daily habit',
            textAlign: TextAlign.center,
            style: _titleStyle(30),
          ),
          const SizedBox(height: 72),
          _streakCard(),
          const SizedBox(height: 30),
          Text('Build a streak, one day at a time.', style: _bodyStyle(20)),
          const Spacer(),
          _primaryButton('Continue', color: _teal, onTap: _next),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _categories() {
    final selected = Set<String>.from(
      (_answers['categories'] as List? ?? const []).map((value) => '$value'),
    );
    final canContinue = selected.isNotEmpty;
    final categories = [
      'Self-confidence',
      'Self-love',
      'Motivation',
      'Goals',
      'Attracting success',
      'Relationships',
      'Financial abundance',
      'Gratitude',
      'Staying positive',
      'Serenity',
      'Mental clarity',
      'Dream big',
    ];

    return _Screen(
      child: Column(
        children: [
          _TopBar(
            progress: 0.82,
            showSkip: true,
            onBack: _back,
            onSkip: _next,
          ),
          const SizedBox(height: 30),
          _heroIcon(Icons.interests, size: 52),
          const SizedBox(height: 8),
          Text(
            'Which categories interest you?',
            textAlign: TextAlign.center,
            style: _titleStyle(26),
          ),
          const SizedBox(height: 8),
          Text(
            'This information will be used to personalize\nyour feed',
            textAlign: TextAlign.center,
            style: _bodyStyle(15),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: categories.map((category) {
                final checked = selected.contains(category);
                return GestureDetector(
                  onTap: () {
                    checked
                        ? selected.remove(category)
                        : selected.add(category);
                    _save('categories', selected.toList()..sort());
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: checked ? _selectedPill : _surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            checked ? '✓' : '+',
                            style: _titleStyle(14).copyWith(color: _teal),
                          ),
                          const SizedBox(width: 7),
                          Text(category, style: _titleStyle(13)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          _primaryButton(
            'Continue',
            color: canContinue ? _teal : _disabled,
            onTap: canContinue ? _next : null,
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _loading() {
    return _Screen(
      child: Column(
        children: [
          const SizedBox(height: 260),
          _heroIcon(Icons.auto_awesome, size: 86),
          const SizedBox(height: 68),
          Text(
            'Gathering your answers...',
            textAlign: TextAlign.center,
            style: _titleStyle(28),
          ),
        ],
      ),
    );
  }

  Widget _paywall() {
    return _Screen(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 70,
            child: Center(child: _heroIcon(Icons.workspace_premium, size: 72)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 238, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_firstName, your personalized\nversion of $_appName is\nready!',
                  style: _titleStyle(27),
                ),
                const SizedBox(height: 24),
                const _Benefit(
                  icon: Icons.timer_outlined,
                  color: _teal,
                  text: '5 minutes a day',
                ),
                const _Benefit(
                  icon: Icons.track_changes,
                  color: _pink,
                  text: 'Thousands of affirmations matched\nto your profile',
                ),
                const _Benefit(
                  icon: Icons.auto_awesome,
                  color: Color(0xFFE2C84E),
                  text: 'A simple routine to follow',
                ),
                const _Benefit(
                  icon: Icons.phone_iphone,
                  color: _orange,
                  text: 'A widget on your lock screen',
                ),
                const _Benefit(
                  icon: Icons.check_box,
                  color: _green,
                  text: 'First effects within 3 days',
                ),
                const Spacer(),
                if (_trialSheetSeen) ...[
                  _primaryButton(
                    'Continue without trial',
                    color: _teal,
                    onTap: () => _finish(trial: false),
                  ),
                  const SizedBox(height: 16),
                ],
                _primaryButton(
                  'Start for free',
                  color: _green,
                  onTap: _showTrialSheet,
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Included in your free trial',
                    style: _bodyStyle(14).copyWith(color: _muted),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _heroIcon(IconData icon, {required double size}) {
  return Container(
    width: size * 1.75,
    height: size * 1.75,
    decoration: BoxDecoration(
      color: _surface,
      shape: BoxShape.circle,
      border: Border.all(color: _teal.withValues(alpha: 0.42), width: 1.5),
    ),
    child: Icon(icon, color: _teal, size: size),
  );
}

class _Screen extends StatelessWidget {
  const _Screen({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 30),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.progress,
    required this.onBack,
    this.showSkip = false,
    this.onSkip,
  });

  final double progress;
  final VoidCallback onBack;
  final bool showSkip;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.chevron_left, size: 42, color: _ink),
          ),
          const SizedBox(width: 46),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: showSkip
                ? Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        'Ignore',
                        style: _bodyStyle(14).copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: _bodyStyle(18))),
        ],
      ),
    );
  }
}

class _TrialSheet extends StatelessWidget {
  const _TrialSheet({required this.onClose, required this.onStart});

  final VoidCallback onClose;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: _darkPanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close, size: 28, color: _muted),
                    ),
                    Text('Restore',
                        style: _bodyStyle(18).copyWith(color: _muted)),
                  ],
                ),
                const SizedBox(height: 52),
                Text(
                  'Start your 7-day free trial',
                  style: _titleStyle(23),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text(
                  '✓  Unique offer applied',
                  style: _titleStyle(18).copyWith(color: Color(0xFF58A760)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                const _Timeline(),
                const Spacer(),
                _billingReminder(),
                const SizedBox(height: 18),
                Text(
                  '7 days of unlimited free access\nthen 44.99USD/an (i.e. \$3.75/mois).',
                  textAlign: TextAlign.center,
                  style: _bodyStyle(14),
                ),
                const SizedBox(height: 18),
                _primaryButton(
                  'Start my free trial',
                  color: _green,
                  onTap: onStart,
                ),
                const SizedBox(height: 16),
                Text(
                  'Terms · Privacy Policy',
                  textAlign: TextAlign.center,
                  style: _bodyStyle(12).copyWith(
                    color: _muted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _billingReminder() {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 10, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none, color: _ink, size: 24),
              const SizedBox(width: 14),
              Text('Billing reminder', style: _bodyStyle(16)),
              const SizedBox(width: 14),
              Container(
                width: 70,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFB7B7B7),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          height: 242,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 28,
                bottom: 0,
                child: Container(
                  width: 20,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_green, _green, _teal, Color(0x00000000)],
                    ),
                  ),
                ),
              ),
              _timelineIcon(0, Icons.lock, _green),
              _timelineIcon(96, Icons.notifications, _green),
              _timelineIcon(192, Icons.workspace_premium, _teal),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _timelineText(
                'Today',
                'Get full access and see how it\nchanges your life.',
              ),
              const SizedBox(height: 30),
              _timelineText(
                'Day 5',
                'You receive a notification that your\ntrial is ending.',
              ),
              const SizedBox(height: 30),
              _timelineText(
                'Day 7',
                "You'll be billed on 7 July, you can\ncancel freely before.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineIcon(double top, IconData icon, Color color) {
    return Positioned(
      top: top,
      child: CircleAvatar(
        radius: 21,
        backgroundColor: color.withValues(alpha: 0.72),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _timelineText(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle(18)),
        const SizedBox(height: 6),
        Text(body, style: _bodyStyle(15)),
      ],
    );
  }
}

Widget _primaryButton(String label,
    {required Color color, VoidCallback? onTap}) {
  return Center(
    child: SizedBox(
      width: _ctaWidth,
      height: _ctaHeight,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.38),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
        child:
            Text(label, style: _titleStyle(19).copyWith(color: Colors.white)),
      ),
    ),
  );
}

Widget _optionPill(
  String label, {
  required bool selected,
  required VoidCallback onTap,
}) {
  return Center(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: _pillWidth,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _selectedPill : _surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _bodyStyle(19),
        ),
      ),
    ),
  );
}

Widget _notificationPreview() {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          offset: const Offset(10, 14),
          blurRadius: 0,
        ),
      ],
    ),
    child: SizedBox(
      width: 330,
      height: 74,
      child: Row(
        children: [
          const SizedBox(width: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _selectedPill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 54,
              height: 54,
              child: Center(
                child: Icon(Icons.thumb_up_alt_outlined, color: _ink, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(_appName, style: _titleStyle(16))),
                    Text('now', style: _bodyStyle(14).copyWith(color: _muted)),
                  ],
                ),
                const SizedBox(height: 5),
                Text('I own my peace.', style: _bodyStyle(18)),
              ],
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    ),
  );
}

Widget _notificationControls() {
  return Column(
    children: [
      _darkSettingRow(
        label: 'How many per day?',
        control: _stepperText('3x'),
        roundedTop: true,
        roundedBottom: true,
      ),
      const SizedBox(height: 20),
      _darkSettingRow(label: 'Start time', control: _stepperText('09:00')),
      Container(width: 330, height: 1, color: Colors.white54),
      _darkSettingRow(
        label: 'End time',
        control: _stepperText('22:00'),
        roundedBottom: true,
      ),
    ],
  );
}

Widget _darkSettingRow({
  required String label,
  required Widget control,
  bool roundedTop = true,
  bool roundedBottom = false,
}) {
  return Container(
    width: 330,
    height: 56,
    decoration: BoxDecoration(
      color: _darkPanel,
      borderRadius: BorderRadius.vertical(
        top: roundedTop ? const Radius.circular(16) : Radius.zero,
        bottom: roundedBottom ? const Radius.circular(16) : Radius.zero,
      ),
    ),
    child: Row(
      children: [
        const SizedBox(width: 22),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _bodyStyle(18).copyWith(color: Colors.white),
          ),
        ),
        control,
        const SizedBox(width: 16),
      ],
    ),
  );
}

Widget _stepperText(String text) {
  return Container(
    width: 104,
    height: 34,
    decoration: BoxDecoration(
      color: _selectedPill,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('−', style: _titleStyle(21)),
        Text(text, style: _bodyStyle(19)),
        Text('+', style: _titleStyle(21)),
      ],
    ),
  );
}

Widget _streakCard() {
  const days = ['Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim', 'Lun'];

  return Container(
    width: 330,
    height: 96,
    decoration: BoxDecoration(
      color: _darkPanel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(days.length, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(days[index],
                style: _bodyStyle(16).copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 15,
              backgroundColor: index == 0 ? _green : _surface,
              child: index == 0
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : null,
            ),
          ],
        );
      }),
    ),
  );
}

TextStyle _titleStyle(double size) {
  return GoogleFonts.getFont(
    'Nunito Sans',
    color: _ink,
    fontSize: size,
    fontWeight: FontWeight.w900,
    height: 1.12,
  );
}

TextStyle _bodyStyle(double size) {
  return GoogleFonts.getFont(
    'Nunito Sans',
    color: _ink,
    fontSize: size,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );
}
