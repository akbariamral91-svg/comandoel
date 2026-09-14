import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

/// سرویس بانک سوالات
/// سوالات از فایل assets/data/komandoel_questions.json (۱۵۰ سوال) خوانده می‌شود
/// و به صورت کاملاً شانسی (بر اساس id) بین بازیکنان پخش می‌شود.
///
/// برای جلوگیری از تکرار سوالات بین بازی‌های پشت‌سرهم (بدون بستن برنامه)،
/// شناسه‌ی سوالاتی که قبلاً در یک بازی استفاده شده‌اند نگه‌داری می‌شود تا
/// بازی بعدی تا حد امکان از سوالات دیده‌نشده استفاده کند. این لیست بلافاصله
/// بعد از پایان هر بازی (اعلام برنده) کاملاً پاک می‌شود.
class QuestionBankService {
  static const String _assetPath = 'assets/data/komandoel_questions.json';
  static const String _usedIdsKey = 'komandoel_used_question_ids';

  List<Question>? _cache;

  Future<List<Question>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    _cache = jsonList
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<Set<int>> _loadUsedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_usedIdsKey) ?? [];
    return list.map(int.parse).toSet();
  }

  Future<void> _saveUsedIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_usedIdsKey, ids.map((e) => e.toString()).toList());
  }

  /// یک سوال برای دور طلایی می‌سازد. این سوال به عنوان سوال استفاده‌شده ثبت می‌شود
  /// تا در ادامه همان بازی دوباره انتخاب نشود.
  Future<Question> generateGoldenQuestion() async {
    final all = await _loadAll();
    final usedIds = await _loadUsedIds();
    final candidates = all.where((q) => !usedIds.contains(q.id)).toList();
    final pool = candidates.isNotEmpty ? candidates : List<Question>.from(all);
    pool.shuffle(Random());
    final question = pool.first;
    await _saveUsedIds({...usedIds, question.id});
    return question;
  }

  /// بعد از پایان هر بازی (اعلام برنده) صدا زده می‌شود تا لیست سوالات
  /// استفاده‌شده کاملاً پاک شود و بازی بعدی از صفر شروع شود.
  Future<void> clearUsedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usedIdsKey);
  }

  /// برای شروع یک بازی جدید: [roundsCount] دست، هر دست ۵ سوال، به صورت شانسی
  /// و بدون تکرار از بین ۱۵۰ سوال انتخاب و شافل می‌شود.
  /// در حد امکان سوالاتی که در بازی‌های قبلی (از آخرین ریست) استفاده نشده‌اند
  /// در اولویت انتخاب هستند تا تکرار سوال بین بازی‌های پشت‌سرهم کمتر شود.
  Future<List<Question>> generateGameQuestions(int roundsCount) async {
    final all = await _loadAll();
    final needed = roundsCount * 5;
    final usedIds = await _loadUsedIds();

    final unused = all.where((q) => !usedIds.contains(q.id)).toList()..shuffle(Random());
    final alreadyUsed = all.where((q) => usedIds.contains(q.id)).toList()..shuffle(Random());

    List<Question> selected;
    if (unused.length >= needed) {
      selected = unused.take(needed).toList();
    } else {
      // سوالات دیده‌نشده کافی نیست: همه‌ی دیده‌نشده‌ها را بردار و بقیه را از دیده‌شده‌ها تکمیل کن
      selected = [...unused, ...alreadyUsed.take(needed - unused.length)];
      if (selected.length < needed) {
        // احتیاط: اگر باز هم کم بود (بعید است چون کل بانک ۱۵۰ سواله و حداکثر نیاز ۵۰ تاست)
        final extra = List<Question>.from(all)..shuffle(Random());
        while (selected.length < needed) {
          selected.add(extra[selected.length % extra.length]);
        }
      }
    }
    selected.shuffle(Random());

    // ثبت این سوالات به‌عنوان استفاده‌شده برای بازی‌های بعدی (تا زمان ریست)
    final newUsedIds = {...usedIds, ...selected.map((q) => q.id)};
    await _saveUsedIds(newUsedIds);

    return selected;
  }
}
