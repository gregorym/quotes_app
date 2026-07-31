import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/quotes_controller.dart';
import '../../controllers/streak_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../models/quotable_model.dart';
import '../../models/quote_model.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/onboarding_repository.dart';
import '../../repositories/top_tasks_repository.dart';
import '../../utils/external_links.dart';
import '../../utils/quote_share.dart';
import '../../widgets/reminder.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';
import '../widgets/snackbar.dart';
import '../widgets/streak_card.dart';

class QuotesPage extends ConsumerStatefulWidget {
  const QuotesPage({super.key});

  @override
  ConsumerState<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends ConsumerState<QuotesPage>
    with WidgetsBindingObserver {
  static const _fallbackQuote =
      "You don't need more time. You need more balls.";
  late final PageController _quotePageController;
  final _topTasksRepository = TopTasksRepository();
  Timer? _taskCleanupTimer;
  int _quoteIndex = 0;
  bool _showTopTasks = true;
  bool _tasksLoaded = false;
  bool _tasksLoading = false;
  bool _tasksSaving = false;
  List<TopTask> _topTasks = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quotePageController = PageController();
    _scheduleTaskCleanup();
    unawaited(_loadTopTasks());
    unawaited(_loadTopTasksVisibility());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskCleanupTimer?.cancel();
    _quotePageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _scheduleTaskCleanup();
    if (_tasksLoaded) unawaited(_loadTopTasks());
  }

  @override
  Widget build(BuildContext context) {
    final quotesState = ref.watch(getQuotesProvider);
    final favoritesState = ref.watch(favoriteQuotesProvider);
    final subscription = ref.watch(subscriptionProvider);
    if (subscriptionPlatformSupported && !subscription.entitlementChecked) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: MyColors.orange),
        ),
      );
    }
    if (subscriptionPlatformSupported &&
        subscription.entitlementChecked &&
        !subscription.canAccessContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/subscription');
      });
    }
    final quotes = quotesState.maybeWhen(
      data: (quotes) => quotes,
      orElse: () => const <Quotable>[],
    );
    final quote = quotes.isEmpty ? null : quotes[_quoteIndex % quotes.length];
    final quoteText = quotesState.maybeWhen(
      data: (_) => quote?.content ?? _fallbackQuote,
      loading: () => 'Finding your next punchline...',
      orElse: () => _fallbackQuote,
    );
    final favorites = favoritesState.maybeWhen(
      data: (quotes) => quotes,
      orElse: () => const <Quote>[],
    );
    final favoriteIds =
        favorites.map((quote) => quote.id ?? quote.content).toSet();
    final quoteId = _quoteId(quote, quoteText);
    final isFavorite = favoriteIds.contains(quoteId);
    final motionDisabled = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              const StreakCard(),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            key: const Key('home-quote-card'),
                            clipBehavior: Clip.antiAlias,
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF17181B),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: PageView.builder(
                                    controller: _quotePageController,
                                    itemCount:
                                        quotes.isEmpty ? 1 : quotes.length,
                                    onPageChanged: (index) {
                                      if (quotes.isEmpty) return;
                                      setState(() => _quoteIndex = index);
                                    },
                                    itemBuilder: (context, index) {
                                      final pageQuote =
                                          quotes.isEmpty ? null : quotes[index];
                                      final pageQuoteText =
                                          quotesState.maybeWhen(
                                        data: (_) =>
                                            pageQuote?.content ??
                                            _fallbackQuote,
                                        loading: () =>
                                            'Finding your next punchline...',
                                        orElse: () => _fallbackQuote,
                                      );

                                      return Semantics(
                                        button: true,
                                        label: 'Open quote full screen',
                                        child: GestureDetector(
                                          onTap: () => _showQuoteDialog(
                                            context,
                                            pageQuote,
                                            pageQuoteText,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: quotes.isNotEmpty &&
                                                        index == _quoteIndex
                                                    ? _TypewriterQuote(
                                                        key: ValueKey(
                                                            pageQuoteText),
                                                        text: pageQuoteText,
                                                        onTap: () =>
                                                            _showQuoteDialog(
                                                          context,
                                                          pageQuote,
                                                          pageQuoteText,
                                                        ),
                                                      )
                                                    : _QuoteText(
                                                        text: pageQuoteText),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: _quoteActions(
                                    context,
                                    quote,
                                    quoteText,
                                    isFavorite,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: motionDisabled
                              ? Duration.zero
                              : const Duration(milliseconds: 360),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.bottomCenter,
                          child: _showTopTasks
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _TopThreeCard(
                                    tasks: _topTasks,
                                    loading: _tasksLoading,
                                    saving: _tasksSaving,
                                    onSave: _saveTaskEdit,
                                    onDelete: _deleteTask,
                                    onToggle: _toggleTask,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            right: 12,
            child: IconButton(
              tooltip: 'Open settings',
              onPressed: () => _showProfileSheet(context),
              icon: const Icon(Icons.settings),
              color: Colors.white,
              iconSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _quoteId(Quotable? quote, String quoteText) {
    return quote?.id ?? quoteText;
  }

  Quote _favoriteQuoteFrom(Quotable? quote, String quoteText) {
    return Quote(
      id: _quoteId(quote, quoteText),
      content: quoteText,
      categories: quote?.tags ?? const [],
    );
  }

  void _showQuoteDialog(
    BuildContext context,
    Quotable? quote,
    String quoteText,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) => GestureDetector(
        key: const Key('quote-dialog'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(dialogContext),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.72),
            child: SafeArea(
              child: Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(dialogContext).height * 0.62,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _TypewriterQuote(
                              key: ValueKey('dialog-$quoteText'),
                              text: quoteText,
                              onTap: () => Navigator.pop(dialogContext),
                            ),
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final isFavorite =
                                ref.watch(favoriteQuotesProvider).maybeWhen(
                                      data: (favorites) => favorites.any(
                                        (favorite) =>
                                            (favorite.id ?? favorite.content) ==
                                            _quoteId(quote, quoteText),
                                      ),
                                      orElse: () => false,
                                    );
                            return _quoteActions(
                              context,
                              quote,
                              quoteText,
                              isFavorite,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  Widget _quoteActions(
    BuildContext context,
    Quotable? quote,
    String quoteText,
    bool isFavorite, {
    bool compact = false,
  }) {
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Share quote',
          onPressed: () => _shareQuote(context, quote, quoteText),
          icon: const Icon(Icons.ios_share),
          color: Colors.white,
          iconSize: compact ? 24 : 34,
        ),
        SizedBox(width: compact ? 4 : 44),
        IconButton(
          tooltip: isFavorite ? 'Remove from bookmarks' : 'Add to bookmarks',
          onPressed: () =>
              _toggleFavorite(context, quote, quoteText, isFavorite),
          icon: Icon(
            isFavorite ? Icons.bookmark : Icons.bookmark_border,
          ),
          color: isFavorite ? MyColors.orange : Colors.white,
          iconSize: compact ? 26 : 36,
        ),
      ],
    );
  }

  Future<void> _loadTopTasksVisibility() async {
    final visible = await _topTasksRepository.fetchVisible();
    if (mounted) setState(() => _showTopTasks = visible);
  }

  Future<bool> _setTopTasksVisibility(bool visible) async {
    final previous = _showTopTasks;
    setState(() => _showTopTasks = visible);
    try {
      await _topTasksRepository.saveVisible(visible);
      if (visible && !_tasksLoaded && !_tasksLoading) {
        unawaited(_loadTopTasks());
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _showTopTasks = previous);
        showSnackbar(context, 'Could not update your settings.', isError: true);
      }
      return false;
    }
  }

  Future<void> _loadTopTasks() async {
    setState(() => _tasksLoading = true);
    try {
      final tasks = await _topTasksRepository.fetchActive();
      if (!mounted) return;
      setState(() {
        _topTasks = tasks;
        _tasksLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        showSnackbar(context, 'Could not load your top three.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _tasksLoading = false);
    }
  }

  Future<bool> _saveTaskEdit(TopTask? task, String text) async {
    final trimmed = text.trim();
    if (_tasksSaving || trimmed.isEmpty || !mounted) return false;

    final updated = task == null
        ? [
            ..._topTasks,
            TopTask(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              text: trimmed,
            ),
          ]
        : _topTasks
            .map((item) =>
                item.id == task.id ? item.copyWith(text: trimmed) : item)
            .toList();
    return _saveTasks(updated);
  }

  Future<void> _toggleTask(TopTask task) async {
    if (!task.completed && !ref.read(subscribedProvider)) {
      context.push('/subscription');
      return;
    }

    final updated = _topTasks
        .map((item) => item.id != task.id
            ? item
            : item.completed
                ? item.copyWith(completed: false, clearCompletedAt: true)
                : item.copyWith(
                    completed: true,
                    completedAt: DateTime.now(),
                  ))
        .toList();
    if (!await _saveTasks(updated)) return;
    if (task.completed) return;

    final allCompleted =
        updated.length == 3 && updated.every((item) => item.completed);
    if (!allCompleted) {
      HapticFeedback.selectionClick();
      return;
    }

    HapticFeedback.successNotification();
    try {
      await ref
          .read(streakControllerProvider)
          .completeToday(topThreeCompleted: true);
      ref.invalidate(streakProvider);
    } catch (_) {
      if (mounted) {
        showSnackbar(context, 'Could not update your streak.', isError: true);
      }
    }
  }

  Future<void> _deleteTask(TopTask task) async {
    await _saveTasks(
      _topTasks.where((item) => item.id != task.id).toList(),
    );
  }

  Future<bool> _saveTasks(List<TopTask> tasks) async {
    if (_tasksSaving) return false;
    final previous = _topTasks;
    final ordered = orderTopTasks(tasks);
    var saved = false;
    setState(() {
      _topTasks = ordered;
      _tasksSaving = true;
    });
    try {
      final savedTasks = await _topTasksRepository.saveActive(ordered);
      if (mounted) setState(() => _topTasks = savedTasks);
      saved = true;
    } catch (_) {
      if (mounted) {
        setState(() => _topTasks = previous);
        showSnackbar(context, 'Could not save your top three.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _tasksSaving = false);
    }
    return saved;
  }

  void _scheduleTaskCleanup() {
    _taskCleanupTimer?.cancel();
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 6);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    _taskCleanupTimer = Timer(next.difference(now), () {
      if (!mounted) return;
      unawaited(_loadTopTasks());
      _scheduleTaskCleanup();
    });
  }

  Future<void> _shareQuote(
    BuildContext context,
    Quotable? quote,
    String quoteText,
  ) async {
    try {
      await shareQuoteImage(context, _favoriteQuoteFrom(quote, quoteText));
    } catch (error) {
      if (!context.mounted) return;
      showSnackbar(context, error.toString(), isError: true);
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Quotable? quote,
    String quoteText,
    bool isFavorite,
  ) async {
    final repository = ref.read(favoriteRepositoryProvider);
    final favoriteQuote = _favoriteQuoteFrom(quote, quoteText);

    if (isFavorite) {
      await repository.deleteFavoriteQuote(favoriteQuote);
    } else {
      await repository.addFavoriteQuote(favoriteQuote);
    }

    ref.invalidate(favoriteQuotesProvider);
    if (!context.mounted) return;
    showSnackbar(
      context,
      isFavorite ? 'Removed from bookmarks.' : 'Added to bookmarks.',
      isError: false,
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      isScrollControlled: true,
      builder: (context) => _ProfileSheet(
        showTopTasks: _showTopTasks,
        onShowTopTasksChanged: _setTopTasksVisibility,
      ),
    );
  }
}

class _TopThreeCard extends StatefulWidget {
  const _TopThreeCard({
    required this.tasks,
    required this.loading,
    required this.saving,
    required this.onSave,
    required this.onDelete,
    required this.onToggle,
  });

  final List<TopTask> tasks;
  final bool loading;
  final bool saving;
  final Future<bool> Function(TopTask?, String) onSave;
  final ValueChanged<TopTask> onDelete;
  final ValueChanged<TopTask> onToggle;

  @override
  State<_TopThreeCard> createState() => _TopThreeCardState();
}

class _TopThreeCardState extends State<_TopThreeCard> {
  final _controller = TextEditingController();
  TopTask? _editingTask;
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _edit([TopTask? task]) {
    final text = task?.text ?? '';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _editingTask = task;
      _adding = task == null;
    });
  }

  void _cancelEdit() => setState(() {
        _editingTask = null;
        _adding = false;
      });

  Future<void> _saveEdit() async {
    if (_controller.text.trim().isEmpty) return;
    final task = _editingTask;
    final adding = _adding;
    final text = _controller.text;
    _cancelEdit();
    if (!await widget.onSave(task, text) && mounted) {
      setState(() {
        _editingTask = task;
        _adding = adding;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final motionDisabled = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return Container(
      key: const Key('top-three-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17181B),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "TODAY'S TOP 3",
                style: MyTypography.body2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.tasks.length}/3',
                style: MyTypography.caption1.copyWith(color: Colors.white54),
              ),
            ],
          ),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  color: MyColors.orange,
                  strokeWidth: 2,
                ),
              ),
            )
          else ...[
            if (widget.tasks.isEmpty && !_adding)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 6, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pick the few things that make today count.',
                    style: MyTypography.body2.copyWith(color: Colors.white54),
                  ),
                ),
              ),
            AnimatedSwitcher(
              duration: motionDisabled
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              layoutBuilder: (currentChild, _) =>
                  currentChild ?? const SizedBox.shrink(),
              child: Column(
                key: ValueKey([
                  ...widget.tasks.map((task) => '${task.id}:${task.completed}'),
                  _adding ? 'new' : _editingTask?.id ?? '',
                ].join('|')),
                children: [
                  for (final task in widget.tasks)
                    if (_editingTask?.id == task.id)
                      _editorRow()
                    else
                      _TopTaskRow(
                        task: task,
                        enabled: !widget.saving,
                        onEdit: () => _edit(task),
                        onDelete: () => widget.onDelete(task),
                        onToggle: () => widget.onToggle(task),
                      ),
                  if (_adding) _editorRow(),
                ],
              ),
            ),
            if (!_adding && _editingTask == null && widget.tasks.length < 3)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.saving ? null : _edit,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(widget.tasks.isEmpty
                      ? 'ADD YOUR FIRST TASK'
                      : 'ADD TASK'),
                  style: TextButton.styleFrom(
                    foregroundColor: MyColors.orange,
                    padding: const EdgeInsets.only(right: 8),
                    textStyle: MyTypography.caption1.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _editorRow() => SizedBox(
        key: const Key('inline-task-editor'),
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                enabled: !widget.saving,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveEdit(),
                style: MyTypography.body1.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'What matters most today?',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: MyColors.orange, width: 1.5),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Save task',
              onPressed: widget.saving ? null : _saveEdit,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.check_rounded, size: 21),
              color: MyColors.orange,
            ),
            IconButton(
              tooltip: 'Cancel task edit',
              onPressed: widget.saving ? null : _cancelEdit,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 19),
              color: Colors.white54,
            ),
          ],
        ),
      );
}

class _TopTaskRow extends StatelessWidget {
  const _TopTaskRow({
    required this.task,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final TopTask task;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 43,
        child: Row(
          children: [
            Transform.translate(
              offset: const Offset(-14, 0),
              child: Semantics(
                label: task.text,
                child: Checkbox(
                  value: task.completed,
                  onChanged: enabled ? (_) => onToggle() : null,
                  activeColor: MyColors.orange,
                  checkColor: Colors.white,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Colors.white54, width: 1.5),
                ),
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(-14, 0),
                child: InkWell(
                  onTap: enabled ? onEdit : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AnimatedDefaultTextStyle(
                      duration: MediaQuery.disableAnimationsOf(context) ||
                              MediaQuery.accessibleNavigationOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      style: MyTypography.body1.copyWith(
                        color: task.completed ? Colors.white38 : Colors.white,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Colors.white54,
                      ),
                      child: Text(
                        task.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(12, 0),
              child: IconButton(
                tooltip: 'Delete ${task.text}',
                onPressed: enabled ? onDelete : null,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 19),
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
}

class _QuoteText extends StatelessWidget {
  const _QuoteText({required this.text});

  final String text;

  static final style = MyTypography.quote.copyWith(
    color: Colors.white,
    fontSize: 36,
    height: 1.12,
  );

  @override
  Widget build(BuildContext context) => AutoSizeText(
        text,
        textAlign: TextAlign.center,
        maxLines: 5,
        maxFontSize: 36,
        minFontSize: 18,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
}

class _TypewriterQuote extends StatefulWidget {
  const _TypewriterQuote({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  State<_TypewriterQuote> createState() => _TypewriterQuoteState();
}

class _TypewriterQuoteState extends State<_TypewriterQuote> {
  static const _characterSpeed = Duration(milliseconds: 28);
  static const _hapticInterval = Duration(milliseconds: 84);

  Timer? _hapticTimer;
  bool? _motionDisabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_motionDisabled == disabled) return;
    _motionDisabled = disabled;
    _hapticTimer?.cancel();
    if (!disabled) _startHaptics();
  }

  void _startHaptics() {
    final finishAt = DateTime.now().add(
      _characterSpeed * widget.text.runes.length,
    );
    _hapticTimer = Timer.periodic(_hapticInterval, (timer) {
      if (DateTime.now().isAfter(finishAt) ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        timer.cancel();
      } else {
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _hapticTimer?.cancel();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    if (_motionDisabled ?? true) return _QuoteText(text: widget.text);

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = _QuoteText.style.copyWith(
          fontSize: _fittingFontSize(context, constraints),
        );
        return Semantics(
          label: widget.text,
          excludeSemantics: true,
          child: AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                widget.text,
                textAlign: TextAlign.center,
                textStyle: style,
                speed: _characterSpeed,
                cursor: '▍',
              ),
            ],
            isRepeatingAnimation: false,
            onTap: _handleTap,
          ),
        );
      },
    );
  }

  double _fittingFontSize(BuildContext context, BoxConstraints constraints) {
    for (var size = 36.0; size >= 18; size--) {
      final painter = TextPainter(
        text: TextSpan(
          text: '${widget.text}▍',
          style: _QuoteText.style.copyWith(fontSize: size),
        ),
        maxLines: 5,
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      if (!painter.didExceedMaxLines &&
          painter.height <= constraints.maxHeight) {
        return size;
      }
    }
    return 18;
  }
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet({
    required this.showTopTasks,
    required this.onShowTopTasksChanged,
  });

  final bool showTopTasks;
  final Future<bool> Function(bool) onShowTopTasksChanged;

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  late bool _showTopTasks = widget.showTopTasks;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteQuotesProvider).maybeWhen(
          data: (favorites) => favorites,
          orElse: () => const <Quote>[],
        );

    return FractionallySizedBox(
      heightFactor: 0.96,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MyColors.darkPanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: MyColors.disabled,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My profile',
                        maxLines: 2,
                        style: MyTypography.h1.copyWith(fontSize: 38),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close profile',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: MyColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Settings',
                  rows: [
                    _ProfileAction(
                      label: 'Personalization',
                      onTap: () => _showPersonalizationSheet(context, ref),
                    ),
                    _ProfileAction(
                      label: 'Widgets',
                      onTap: () => _showWidgetInstructions(context),
                    ),
                    _ProfileAction(
                      label: 'Notifications',
                      onTap: () => _showReminderSheet(context),
                    ),
                    _ProfileAction.toggle(
                      label: 'Show Top 3',
                      value: _showTopTasks,
                      onChanged: (visible) async {
                        if (await widget.onShowTopTasksChanged(visible) &&
                            mounted) {
                          setState(() => _showTopTasks = visible);
                        }
                      },
                    ),
                    _ProfileAction(
                      label: 'Task history',
                      onTap: () => _showTaskHistorySheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  rows: [
                    _ProfileAction(
                      label: 'Bookmarks (${favorites.length})',
                      onTap: () => _showFavoritesSheet(context, favorites),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Support',
                  rows: [
                    _ProfileAction(
                      label: 'Help & support',
                      onTap: () => openExternalUrl(supportUrl),
                    ),
                    _ProfileAction(
                      label: 'Terms & privacy',
                      onTap: () => _showTermsAndPrivacy(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAction {
  const _ProfileAction({
    required this.label,
    required this.onTap,
  })  : value = null,
        onChanged = null;

  const _ProfileAction.toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  }) : onTap = null;

  final String label;
  final VoidCallback? onTap;
  final bool? value;
  final ValueChanged<bool>? onChanged;
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({this.title, required this.rows});

  final String? title;
  final List<_ProfileAction> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 18, bottom: 14),
            child: Text(
              title!,
              style: MyTypography.body1.copyWith(
                color: MyColors.muted,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: MyColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                _ProfileRow(action: rows[index]),
                if (index != rows.length - 1)
                  const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: MyColors.disabled,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.action});

  final _ProfileAction action;

  @override
  Widget build(BuildContext context) {
    final value = action.value;
    return Semantics(
      button: value == null,
      toggled: value,
      label: action.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: value == null ? action.onTap : () => action.onChanged!(!value),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  action.label,
                  style: MyTypography.h3.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (value == null)
                const Icon(Icons.chevron_right, color: MyColors.ink, size: 30)
              else
                Switch(
                  key: const Key('show-top-three-toggle'),
                  value: value,
                  onChanged: action.onChanged,
                  activeTrackColor: MyColors.orange,
                ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskHistorySheet extends StatefulWidget {
  const _TaskHistorySheet();

  @override
  State<_TaskHistorySheet> createState() => _TaskHistorySheetState();
}

class _TaskHistorySheetState extends State<_TaskHistorySheet> {
  late final Future<List<TopTask>> _history =
      TopTasksRepository().fetchHistory();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      key: const Key('task-history'),
      heightFactor: 0.82,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: MyColors.disabled,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: Text('Task history', style: MyTypography.h2)),
                    IconButton(
                      tooltip: 'Close task history',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'Completed tasks leave your Top 3 at 6:00 a.m.',
                  style: MyTypography.body2.copyWith(color: MyColors.muted),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: FutureBuilder<List<TopTask>>(
                    future: _history,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: MyColors.orange,
                          ),
                        );
                      }
                      final groups = <DateTime, List<TopTask>>{};
                      for (final task in snapshot.data!) {
                        final completedAt = task.completedAt!;
                        final date = DateTime(
                          completedAt.year,
                          completedAt.month,
                          completedAt.day,
                        );
                        groups.putIfAbsent(date, () => []).add(task);
                      }
                      if (groups.isEmpty) {
                        return Center(
                          child: Text(
                            'No completed tasks yet.',
                            style: MyTypography.body1.copyWith(
                              color: MyColors.muted,
                            ),
                          ),
                        );
                      }
                      return ListView(
                        children: [
                          for (final group in groups.entries) ...[
                            Padding(
                              key: ValueKey(
                                'task-history-${group.key.year}-${group.key.month}-${group.key.day}',
                              ),
                              padding: const EdgeInsets.only(top: 8, bottom: 6),
                              child: Text(
                                MaterialLocalizations.of(context)
                                    .formatFullDate(group.key),
                                style: MyTypography.caption1.copyWith(
                                  color: MyColors.orange,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            for (final task in group.value)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: MyColors.orange,
                                ),
                                title: Text(
                                  task.text,
                                  style: MyTypography.body1.copyWith(
                                    color: Colors.white70,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      );
                    },
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

void _showTaskHistorySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    isScrollControlled: true,
    builder: (context) => const _TaskHistorySheet(),
  );
}

class _FavoritesSheet extends ConsumerWidget {
  const _FavoritesSheet({required this.favorites});

  final List<Quote> favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listHeight = favorites.isEmpty
        ? 110.0
        : (favorites.length > 4 ? 330.0 : favorites.length * 82.0);

    return FractionallySizedBox(
      heightFactor: favorites.isEmpty ? 0.34 : 0.52,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: MyColors.disabled,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Bookmarks', style: MyTypography.h2),
                const SizedBox(height: 18),
                SizedBox(
                  height: listHeight,
                  child: favorites.isEmpty
                      ? Center(
                          child: Text(
                            'No bookmarks yet.',
                            style: MyTypography.body1.copyWith(
                              color: MyColors.muted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: favorites.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: MyColors.disabled,
                          ),
                          itemBuilder: (context, index) {
                            final quote = favorites[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                quote.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: MyTypography.quote,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref
                                      .read(favoriteRepositoryProvider)
                                      .deleteFavoriteQuote(quote);
                                  ref.invalidate(favoriteQuotesProvider);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  showSnackbar(
                                    context,
                                    'Removed from bookmarks.',
                                    isError: false,
                                  );
                                },
                              ),
                            );
                          },
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

void _showFavoritesSheet(BuildContext context, List<Quote> favorites) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    isScrollControlled: true,
    builder: (context) => _FavoritesSheet(favorites: favorites),
  );
}

Future<void> _showPersonalizationSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final answers = await ref.read(onboardingRepositoryProvider).fetchAnswers();
  if (!context.mounted) return;
  final categories = (answers['categories'] as List? ?? const []).join(' · ');
  final frictions = onboardingFrictionSummary(answers);
  final router = GoRouter.of(context);
  _showInfoSheet(
    context,
    title: 'Your protocol',
    children: [
      _InfoLine('Name', answers['name']?.toString() ?? 'Not set'),
      _InfoLine(
          'Primary goal', answers['primary_goal']?.toString() ?? 'Not set'),
      _InfoLine('Focus', categories.isEmpty ? 'Not set' : categories),
      _InfoLine(
        'Frictions',
        frictions.isEmpty ? 'Not set' : frictions,
      ),
      _InfoLine(
        'Pressure',
        answers['tone'] == 'extra hard' ? 'Extra Hard' : 'Hard',
      ),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route is PageRoute);
            router.go('/onboarding');
          },
          child: const Text('Change my protocol'),
        ),
      ),
    ],
  );
}

void _showWidgetInstructions(BuildContext context) {
  _showInfoSheet(
    context,
    title: 'Daily Home Screen quote',
    children: [
      Text(
        'Touch and hold an empty area of your Home Screen, tap Edit, then Add Widget. Search for No Excuses and choose the square or wide layout.',
        style: MyTypography.body1,
      ),
      SizedBox(height: 14),
      Text(
        'The quote changes automatically at local midnight.',
        style: MyTypography.body1,
      ),
    ],
  );
}

void _showTermsAndPrivacy(BuildContext context) {
  _showInfoSheet(
    context,
    title: 'Terms & privacy',
    children: [
      Text(
        'Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in App Store account settings. Apple’s Standard End User License Agreement applies.',
        style: MyTypography.body1,
      ),
      SizedBox(height: 18),
      Text(
        'Your onboarding answers, reminder schedule, and bookmarks are stored on this device. Apple processes purchases. No Excuses does not sell your personal information.',
        style: MyTypography.body1,
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        children: [
          OutlinedButton(
            onPressed: () => openExternalUrl(termsOfUseUrl),
            child: const Text('Terms of use'),
          ),
          OutlinedButton(
            onPressed: () => openExternalUrl(privacyPolicyUrl),
            child: const Text('Privacy policy'),
          ),
        ],
      ),
    ],
  );
}

void _showInfoSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MyColors.darkPanel,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: MyTypography.h2)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: MyTypography.caption1.copyWith(color: MyColors.muted),
          ),
          const SizedBox(height: 4),
          Text(value, style: MyTypography.body1),
        ],
      ),
    );
  }
}

void _showReminderSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    isScrollControlled: true,
    builder: (context) {
      return const FractionallySizedBox(
        heightFactor: 0.82,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: ReminderWidget(requiresSubscription: true),
        ),
      );
    },
  );
}
