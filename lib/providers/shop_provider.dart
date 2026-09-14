import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';

/// وضعیت فروشگاه: تعداد الماس‌ها و شخصیت‌هایی که کاربر خریده است.
/// همه چیز روی گوشی ذخیره می‌شود (shared_preferences) تا بین اجراهای برنامه بماند.
class ShopProvider extends ChangeNotifier {
  static const String _diamondsKey = 'komandoel_diamonds';
  static const String _ownedKey = 'komandoel_owned_characters';

  int _diamonds = 0;
  int get diamonds => _diamonds;

  final Set<String> _ownedCharacterIds = {};
  Set<String> get ownedCharacterIds => _ownedCharacterIds;

  bool _loaded = false;
  bool get loaded => _loaded;

  ShopProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _diamonds = prefs.getInt(_diamondsKey) ?? 0;
    final owned = prefs.getStringList(_ownedKey) ?? [];
    _ownedCharacterIds
      ..clear()
      ..addAll(owned);

    // شخصیت‌های رایگان (قیمت صفر) همیشه از ابتدا در اختیار بازیکن هستند.
    for (final c in Character.catalog) {
      if (c.price <= 0) _ownedCharacterIds.add(c.id);
    }

    _loaded = true;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_diamondsKey, _diamonds);
    await prefs.setStringList(_ownedKey, _ownedCharacterIds.toList());
  }

  bool isOwned(String characterId) => _ownedCharacterIds.contains(characterId);

  /// دکمه‌ی تست/پاداش داخل فروشگاه - یک الماس اضافه می‌کند.
  Future<void> addDiamond([int amount = 1]) async {
    _diamonds += amount;
    notifyListeners();
    await _save();
  }

  /// تلاش برای خرید یک شخصیت. اگر الماس کافی باشد شخصیت خریده و ذخیره می‌شود.
  /// خروجی true یعنی خرید موفق، false یعنی الماس کافی نبود.
  Future<bool> buyCharacter(Character character) async {
    if (isOwned(character.id)) return true;
    if (_diamonds < character.price) return false;

    _diamonds -= character.price;
    _ownedCharacterIds.add(character.id);
    notifyListeners();
    await _save();
    return true;
  }

  List<Character> get ownedCharacters =>
      Character.catalog.where((c) => isOwned(c.id)).toList();
}
