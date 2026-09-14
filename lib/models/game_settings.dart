enum NarratorSelectionMode { random, manual }

/// تنظیمات یک بازی جدید که در صفحه‌ی «ساخت محیط بازی» تعیین می‌شود
class GameSettings {
  final int roundsCount; // تعداد دست‌ها - هر دست = ۵ سوال
  final NarratorSelectionMode narratorMode;
  final String? manualNarratorId; // در صورت انتخاب دستی راوی

  const GameSettings({
    required this.roundsCount,
    required this.narratorMode,
    this.manualNarratorId,
  });

  int get totalQuestions => roundsCount * 5;
}
