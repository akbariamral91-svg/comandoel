import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/question.dart';
import '../models/game_settings.dart';
import '../services/question_bank_service.dart';

enum GamePhase {
  waitingToShowQuestion, // قبل از شروع بازی - فقط یکبار دکمه نمایش سوال دیده می‌شود
  questionActive, // سوال نمایش داده شده و تایمر در حال شمارش است
  betweenQuestions, // فاصله ۳ ثانیه‌ای بین دو سوال
  paused, // راوی دکمه استپ را زده
  roundScore, // پایان هر دست - نمایش جدول امتیاز کل
  goldenIntro, // تساوی کامل نفرات برتر - صفحه معرفی دور طلایی
  goldenQuestionActive, // سوال دور طلایی
  goldenBetweenQuestions, // فاصله کوتاه بین سوالات دور طلایی
  finished, // بازی تمام شده
}

/// نتیجه نهایی یک بازیکن برای صفحه پایان بازی
class PlayerResult {
  final Player player;
  final int rank; // 1 = برنده، 2، 3 (سوم می‌تواند مشترک باشد)
  final bool wonByFewerMistakes;

  PlayerResult({
    required this.player,
    required this.rank,
    this.wonByFewerMistakes = false,
  });
}

/// برای نمایش انیمیشن "+۷" روی دایره بازیکن. هر رویداد یک شناسه یکتا دارد
/// تا حتی اگر امتیاز تکراری باشد (مثلاً دوبار پشت‌سرهم ۷ امتیاز)، انیمیشن دوباره اجرا شود.
class ScoreEvent {
  final String playerId;
  final int points;
  final int eventId;
  ScoreEvent({required this.playerId, required this.points, required this.eventId});
}

class GameProvider extends ChangeNotifier {
  final QuestionBankService _questionBank = QuestionBankService();

  List<Player> players = [];
  String? narratorId;

  List<Question> _questions = [];
  int _currentQuestionIndex = 0;

  static const int questionDuration = 7; // ثانیه
  static const int fastAnswerThreshold = 3; // زیر ۳ ثانیه = ۷ امتیاز
  static const int fastAnswerScore = 7;
  static const int normalAnswerScore = 5;
  static const int betweenQuestionsDelay = 3; // ثانیه فاصله بین سوالات

  GamePhase phase = GamePhase.waitingToShowQuestion;

  Timer? _countdownTimer;
  Timer? _nextQuestionTimer;
  int _secondsRemaining = questionDuration;
  int get secondsRemaining => _secondsRemaining;
  double get timerProgress => _secondsRemaining / questionDuration;

  // استاپ‌واچ کل سوال - از لحظه نمایش سوال تا پایانش پیوسته کار می‌کند
  // (به‌جز زمانی که بازی استپ شده) تا سرعت واقعی جواب‌دادن اندازه‌گیری شود.
  final Stopwatch _questionStopwatch = Stopwatch();
  double? _selectionElapsedSeconds; // زمان دقیق لحظه‌ای که راوی روی بازیکن کلیک کرد

  // بازیکنی که راوی الان روی دایره‌اش کلیک کرده و منتظر تایید سبز/قرمز است
  String? selectedPlayerId;

  int _scoreEventCounter = 0;
  ScoreEvent? lastScoreEvent;

  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  int get currentQuestionNumber => _currentQuestionIndex + 1;
  int get totalQuestions => _questions.length;

  int get currentRoundNumber => (_currentQuestionIndex ~/ 5) + 1;
  int get totalRounds => (_questions.length / 5).ceil();

  bool get isLastQuestion => _currentQuestionIndex >= _questions.length - 1;

  Player? get narrator {
    try {
      return players.firstWhere((p) => p.id == narratorId);
    } catch (_) {
      return null;
    }
  }

  List<Player> get activePlayers => players;

  Future<void> setupGame({
    required List<Player> gamePlayers,
    required GameSettings settings,
  }) async {
    players = gamePlayers;

    // راوی فقط به‌صورت دستی از صفحه ساخت محیط انتخاب می‌شود.
    if (settings.manualNarratorId == null ||
        !players.any((p) => p.id == settings.manualNarratorId)) {
      throw StateError('A narrator must be selected before starting the game.');
    }
    narratorId = settings.manualNarratorId;
    for (final p in players) {
      p.isNarrator = (p.id == narratorId);
    }

    _questions = await _questionBank.generateGameQuestions(settings.roundsCount);
    _currentQuestionIndex = 0;
    phase = GamePhase.waitingToShowQuestion;
    notifyListeners();
  }

  /// راوی روی دکمه "نمایش سوال" (فقط اول بازی) کلیک می‌کند
  void revealFirstQuestion() {
    if (phase != GamePhase.waitingToShowQuestion) return;
    _startNewQuestion();
  }

  void _startNewQuestion() {
    for (final p in players) {
      p.resetForNewQuestion();
    }
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    _secondsRemaining = questionDuration;
    phase = GamePhase.questionActive;

    _questionStopwatch
      ..reset()
      ..start();

    _startCountdownTimer();
    notifyListeners();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _onQuestionTimeout();
      }
      notifyListeners();
    });
  }

  void _onQuestionTimeout() {
    // هیچ‌کس در زمان مقرر جواب نداد
    _goToNextQuestionAfterDelay();
  }

  /// راوی روی دایره‌ی یک بازیکن کلیک می‌کند (چون آن بازیکن ادعای جواب دادن دارد)
  void selectPlayer(String playerId) {
    if (phase != GamePhase.questionActive) return;
    if (playerId == narratorId) return; // راوی خودش سوال را می‌بیند، نمی‌تواند جواب بدهد
    final player = players.firstWhere((p) => p.id == playerId);
    if (player.isBlockedForCurrentQuestion) return; // قبلاً یک بار اشتباه گفته، دیگر نوبتش نیست

    // زمان دقیق لحظه‌ی جواب‌دادن همین‌جا ثبت می‌شود (نه در لحظه‌ای که راوی بعداً دکمه سبز را می‌زند)
    _selectionElapsedSeconds = _questionStopwatch.elapsed.inMilliseconds / 1000.0;

    _countdownTimer?.cancel(); // تایمر بصری متوقف می‌شود تا راوی تصمیم بگیرد
    selectedPlayerId = playerId;
    notifyListeners();
  }

  /// راوی به‌اشتباه روی دایره‌ای کلیک کرده - لغو انتخاب، بازی از همان لحظه ادامه پیدا می‌کند
  void cancelSelection() {
    if (selectedPlayerId == null) return;
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    _resumeCountdownIfTimeLeft();
  }

  /// راوی تایید می‌کند که جواب درست بوده (دکمه سبز)
  void markCorrect() {
    if (selectedPlayerId == null) return;
    final player = players.firstWhere((p) => p.id == selectedPlayerId);

    final elapsedSeconds = _selectionElapsedSeconds ??
        (_questionStopwatch.elapsed.inMilliseconds / 1000.0);
    final earnedScore =
        elapsedSeconds < fastAnswerThreshold ? fastAnswerScore : normalAnswerScore;

    player.score += earnedScore;
    _scoreEventCounter++;
    lastScoreEvent = ScoreEvent(
      playerId: player.id,
      points: earnedScore,
      eventId: _scoreEventCounter,
    );

    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    _countdownTimer?.cancel();
    _questionStopwatch.stop();
    _goToNextQuestionAfterDelay();
  }

  /// راوی تایید می‌کند که جواب غلط بوده (دکمه قرمز)
  void markWrong() {
    if (selectedPlayerId == null) return;
    final player = players.firstWhere((p) => p.id == selectedPlayerId);

    player.wrongAnswersInCurrentQuestion += 1;
    player.totalWrongAnswers += 1;

    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    _resumeCountdownIfTimeLeft();
  }

  void _resumeCountdownIfTimeLeft() {
    if (_secondsRemaining <= 0) {
      _onQuestionTimeout();
      return;
    }
    phase = GamePhase.questionActive;
    _startCountdownTimer();
    notifyListeners();
  }

  void _goToNextQuestionAfterDelay() {
    phase = GamePhase.betweenQuestions;
    notifyListeners();

    _nextQuestionTimer?.cancel();
    _nextQuestionTimer = Timer(const Duration(seconds: betweenQuestionsDelay), () {
      if ((currentQuestionNumber % 5) == 0) {
        _showRoundScore();
      } else {
        _currentQuestionIndex++;
        _startNewQuestion();
      }
    });
  }

  /// بعد از سوال پنجم هر دست، بازی موقتاً به صفحه امتیاز می رود.
  /// امتیازهای این صفحه همیشه امتیاز تجمعی کل بازی هستند.
  void _showRoundScore() {
    _countdownTimer?.cancel();
    _nextQuestionTimer?.cancel();
    _questionStopwatch.stop();
    phase = GamePhase.roundScore;
    notifyListeners();
  }

  bool get isLastRound => currentRoundNumber >= totalRounds;

  /// از صفحه امتیاز به دست بعدی برمی گردد. در دست آخر، این متد استفاده نمی شود
  /// و صفحه نتیجه نهایی باز می شود.
  void startNextRound() {
    if (phase != GamePhase.roundScore || isLastRound) return;
    _currentQuestionIndex++;
    phase = GamePhase.waitingToShowQuestion;
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    notifyListeners();
  }

  // ---- استپ / ادامه ----
  GamePhase? _phaseBeforePause;
  bool _wasSelectionPendingBeforePause = false;

  void togglePause() {
    if (phase == GamePhase.paused) {
      final resumingPhase = _phaseBeforePause ?? GamePhase.questionActive;

      if (resumingPhase == GamePhase.betweenQuestions) {
        // فاصله بین سوالات را از نو شروع می‌کنیم تا سوال بعدی هنگام استپ زودتر ظاهر نشود
        _goToNextQuestionAfterDelay();
      } else if (resumingPhase == GamePhase.questionActive) {
        phase = GamePhase.questionActive;
        _questionStopwatch.start();
        // فقط اگر انتخابی در جریان نبود، تایمر بصری را دوباره فعال کن
        if (!_wasSelectionPendingBeforePause) {
          _startCountdownTimer();
        }
        notifyListeners();
      } else {
        phase = resumingPhase;
        notifyListeners();
      }
    } else {
      _phaseBeforePause = phase;
      _wasSelectionPendingBeforePause = selectedPlayerId != null;
      _countdownTimer?.cancel();
      _nextQuestionTimer?.cancel();
      if (_questionStopwatch.isRunning) _questionStopwatch.stop();
      phase = GamePhase.paused;
      notifyListeners();
    }
  }

  // ---- پایان بازی ----
  List<PlayerResult> results = [];

  List<String> goldenPlayerIds = [];
  String? goldenWinnerId;
  Question? goldenQuestion;

  List<Player> get goldenPlayers => players.where((p) => goldenPlayerIds.contains(p.id)).toList();
  bool get hasGoldenRound => goldenPlayerIds.length >= 2;

  /// پایان آخرین دست را بررسی می‌کند. اگر نفرات برتر از نظر امتیاز و تعداد خطا
  /// کاملاً برابر باشند، ابتدا وارد صفحه معرفی دور طلایی می‌شویم.
  /// در غیر این صورت نتیجه نهایی عادی محاسبه می‌شود.
  void finishFromScoreScreen() {
    if (phase != GamePhase.roundScore || !isLastRound) return;
    final competitors = players.where((p) => p.id != narratorId).toList();
    final sorted = List<Player>.from(competitors)
      ..sort((a, b) {
        if (b.score != a.score) return b.score.compareTo(a.score);
        return a.totalWrongAnswers.compareTo(b.totalWrongAnswers);
      });

    if (sorted.length >= 2) {
      final topScore = sorted.first.score;
      final topMistakes = sorted.first.totalWrongAnswers;
      final tied = sorted
          .where((p) => p.score == topScore && p.totalWrongAnswers == topMistakes)
          .take(3)
          .toList();
      if (tied.length >= 2) {
        goldenPlayerIds = tied.map((p) => p.id).toList();
        goldenWinnerId = null;
        goldenQuestion = null;
        phase = GamePhase.goldenIntro;
        notifyListeners();
        return;
      }
    }

    _finishGame();
  }

  Future<void> startGoldenRound() async {
    if (phase != GamePhase.goldenIntro || goldenPlayerIds.length < 2) return;
    await _beginGoldenQuestion();
  }

  Future<void> _beginGoldenQuestion() async {
    goldenQuestion = await _questionBank.generateGoldenQuestion();
    for (final p in goldenPlayers) {
      p.resetForNewQuestion();
    }
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    _secondsRemaining = questionDuration;
    phase = GamePhase.goldenQuestionActive;
    _questionStopwatch
      ..reset()
      ..start();
    _startGoldenCountdownTimer();
    notifyListeners();
  }

  void _startGoldenCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _startNextGoldenQuestionAfterDelay();
      }
      notifyListeners();
    });
  }

  void selectGoldenPlayer(String playerId) {
    if (phase != GamePhase.goldenQuestionActive) return;
    if (!goldenPlayerIds.contains(playerId)) return;
    final player = players.firstWhere((p) => p.id == playerId);
    if (player.isBlockedForCurrentQuestion) return;
    _selectionElapsedSeconds = _questionStopwatch.elapsed.inMilliseconds / 1000.0;
    _countdownTimer?.cancel();
    selectedPlayerId = playerId;
    notifyListeners();
  }

  void cancelGoldenSelection() {
    if (selectedPlayerId == null) return;
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    if (_secondsRemaining > 0) _startGoldenCountdownTimer();
    notifyListeners();
  }

  void markGoldenWrong() {
    if (selectedPlayerId == null) return;
    final player = players.firstWhere((p) => p.id == selectedPlayerId);
    player.wrongAnswersInCurrentQuestion += 1;
    player.totalWrongAnswers += 1;
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;

    final everyoneBlocked = goldenPlayers.isNotEmpty &&
        goldenPlayers.every((p) => p.isBlockedForCurrentQuestion);
    if (everyoneBlocked) {
      _startNextGoldenQuestionAfterDelay();
    } else if (_secondsRemaining > 0) {
      _startGoldenCountdownTimer();
    }
    notifyListeners();
  }

  void markGoldenCorrect() {
    if (selectedPlayerId == null) return;
    goldenWinnerId = selectedPlayerId;
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    _countdownTimer?.cancel();
    _questionStopwatch.stop();
    _finishGame(forcedWinnerId: goldenWinnerId);
  }

  void _startNextGoldenQuestionAfterDelay() {
    _countdownTimer?.cancel();
    _questionStopwatch.stop();
    phase = GamePhase.goldenBetweenQuestions;
    notifyListeners();
    _nextQuestionTimer?.cancel();
    _nextQuestionTimer = Timer(const Duration(seconds: betweenQuestionsDelay), () async {
      await _beginGoldenQuestion();
    });
  }

  void _finishGame({String? forcedWinnerId}) {
    phase = GamePhase.finished;

    // طبق طراحی: بلافاصله بعد از پایان بازی و اعلام برنده، لیست سوالات
    // استفاده‌شده کاملاً پاک می‌شود تا بازی بعدی از صفر شروع شود.
    _questionBank.clearUsedQuestions();

    // راوی هرگز جواب نمی‌دهد و امتیازی نمی‌گیرد، پس نباید در رتبه‌بندی نهایی باشد
    final competitors = players.where((p) => p.id != narratorId).toList();

    final sorted = List<Player>.from(competitors)
      ..sort((a, b) {
        if (forcedWinnerId != null) {
          if (a.id == forcedWinnerId) return -1;
          if (b.id == forcedWinnerId) return 1;
        }
        if (b.score != a.score) return b.score.compareTo(a.score);
        return a.totalWrongAnswers.compareTo(b.totalWrongAnswers);
      });

    results = [];
    for (int i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      final rank = i + 1;
      final wonByMistakes = forcedWinnerId == null &&
          rank == 1 &&
          sorted.length > 1 &&
          sorted[0].score == sorted[1].score &&
          sorted[0].totalWrongAnswers < sorted[1].totalWrongAnswers;
      results.add(PlayerResult(
        player: p,
        rank: rank,
        wonByFewerMistakes: wonByMistakes,
      ));
    }

    notifyListeners();
  }

  void resetGame() {
    _countdownTimer?.cancel();
    _nextQuestionTimer?.cancel();
    _questionStopwatch
      ..stop()
      ..reset();
    players = [];
    _questions = [];
    _currentQuestionIndex = 0;
    narratorId = null;
    selectedPlayerId = null;
    _selectionElapsedSeconds = null;
    lastScoreEvent = null;
    results = [];
    goldenPlayerIds = [];
    goldenWinnerId = null;
    goldenQuestion = null;
    phase = GamePhase.waitingToShowQuestion;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nextQuestionTimer?.cancel();
    super.dispose();
  }
}
