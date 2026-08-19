import 'package:flutter/material.dart';

/// مدل بازیکن
class Player {
  final String id;
  String name;
  int score;
  int wrongAnswersInCurrentQuestion; // برای منطق خط قرمز روی دایره (فقط ۱ اشتباه کافیست)
  int totalWrongAnswers; // مجموع اشتباهات کل بازی - برای تعیین برنده در صورت تساوی امتیاز
  final Color avatarColor;
  bool isNarrator;

  Player({
    required this.id,
    required this.name,
    required this.avatarColor,
    this.score = 0,
    this.wrongAnswersInCurrentQuestion = 0,
    this.totalWrongAnswers = 0,
    this.isNarrator = false,
  });

  /// آیا این بازیکن برای سوال جاری دیگر اجازه‌ی جواب دادن ندارد
  bool get isBlockedForCurrentQuestion => wrongAnswersInCurrentQuestion >= 1;

  void resetForNewQuestion() {
    wrongAnswersInCurrentQuestion = 0;
  }

  /// رنگ‌های پیش‌فرض دایره‌ی بازیکنان - هماهنگ با تم طلایی مشکی
  static const List<Color> defaultAvatarColors = [
    Color(0xFFD4AF37), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
    Color(0xFF6EC1E4), // آبی روشن
    Color(0xFFE85D75), // صورتی
    Color(0xFF7ED957), // سبز
    Color(0xFFB57EDC), // بنفش
    Color(0xFFFF8C42), // نارنجی
    Color(0xFF4ECDC4), // فیروزه‌ای
    Color(0xFFF7D060), // زرد
  ];
}
