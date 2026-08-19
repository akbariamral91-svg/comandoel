import 'dart:async';
import 'dart:math';
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

    // تعیین راوی - با بررسی معتبر بودن ایندکس برای جلوگیری از کرش
    if (settings.narratorMode == NarratorSelectionMode.manual &&
        settings.manualNarratorId != null &&
        players.any((p) => p.id == settings.manualNarratorId)) {
      narratorId = settings.manualNarratorId;
    } else {
      final randomIndex = Random().nextInt(players.length);
      narratorId = players[randomIndex].id;
    }
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
      if (isLastQuestion) {
        _finishGame();
      } else {
        _currentQuestionIndex++;
        _startNewQuestion();
      }
    });
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

  void _finishGame() {
    phase = GamePhase.finished;

    // طبق طراحی: بلافاصله بعد از پایان بازی و اعلام برنده، لیست سوالات
    // استفاده‌شده کاملاً پاک می‌شود تا بازی بعدی از صفر شروع شود.
    _questionBank.clearUsedQuestions();

    // راوی هرگز جواب نمی‌دهد و امتیازی نمی‌گیرد، پس نباید در رتبه‌بندی نهایی باشد
    final competitors = players.where((p) => p.id != narratorId).toList();

    final sorted = List<Player>.from(competitors)
      ..sort((a, b) {
        if (b.score != a.score) return b.score.compareTo(a.score);
        // در صورت تساوی امتیاز: کمترین تعداد اشتباه برنده می‌شود
        return a.totalWrongAnswers.compareTo(b.totalWrongAnswers);
      });

    results = [];
    for (int i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      int rank;
      if (i == 0) {
        rank = 1;
      } else if (i == 1) {
        rank = 2;
      } else {
        final prev = sorted[i - 1];
        final tiedWithPrev = p.score == prev.score && p.totalWrongAnswers == prev.totalWrongAnswers;
        if (i == 2) {
          rank = 3;
        } else if (tiedWithPrev && results.isNotEmpty && results.last.rank == 3) {
          rank = 3;
        } else {
          rank = i + 1;
        }
      }

      // پیام «برنده به دلیل کمترین اشتباه» فقط وقتی نشان داده شود که امتیاز نفر اول و دوم برابر
      // بوده و واقعاً تعداد اشتباه نفر اول کمتر بوده (نه تساوی کامل)
      final wonByMistakes = rank == 1 &&
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
