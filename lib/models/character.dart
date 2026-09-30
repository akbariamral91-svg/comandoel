/// مدل شخصیت قابل خرید در فروشگاه
class Character {
  final String id;
  final String name;
  final String imagePath;
  final int price;

  const Character({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
  });

  /// کاتالوگ کامل شخصیت‌های فروشگاه.
  ///
  /// افزودن شخصیت جدید: عکس را در assets/profiles/ قرار بده و یک آیتم
  /// جدید اینجا اضافه کن. char_01 عکس تستی است که کاربر جداگانه می‌فرستد؛
  /// بقیه فعلاً عکس نمونه (placeholder) دارند تا وقتی عکس واقعی جایگزین شود.
  static const List<Character> catalog = [
    Character(
      id: 'char_01',
      name: 'شخصیت ۱',
      imagePath: 'assets/profiles/char_01.png',
      price: 0, // شخصیت پیش‌فرض و رایگان
    ),
    Character(
      id: 'char_02',
      name: 'شخصیت ۲',
      imagePath: 'assets/profiles/char_02.png',
      price: 0,
    ),
    Character(
      id: 'char_03',
      name: 'شخصیت ۳',
      imagePath: 'assets/profiles/char_03.png',
      price: 0,
    ),
    Character(
      id: 'char_04',
      name: 'شخصیت ۴',
      imagePath: 'assets/profiles/char_04.png',
      price: 0,
    ),
    Character(
      id: 'char_05',
      name: 'شخصیت ۵',
      imagePath: 'assets/profiles/char_05.png',
      price: 0,
    ),
    Character(
      id: 'char_06',
      name: 'شخصیت ۶',
      imagePath: 'assets/profiles/char_06.png',
      price: 0,
    ),
    Character(
      id: 'char_07',
      name: 'شخصیت ۷',
      imagePath: 'assets/profiles/char_07.png',
      price: 0,
    ),
    Character(
      id: 'char_08',
      name: 'شخصیت ۸',
      imagePath: 'assets/profiles/char_08.png',
      price: 0,
    ),
    Character(
      id: 'char_09',
      name: 'شخصیت ۹',
      imagePath: 'assets/profiles/char_09.png',
      price: 0,
    ),
    Character(
      id: 'char_10',
      name: 'شخصیت ۱۰',
      imagePath: 'assets/profiles/char_10.png',
      price: 100,
    ),
    Character(
      id: 'char_11',
      name: 'شخصیت ۱۱',
      imagePath: 'assets/profiles/char_11.png',
      price: 100,
    ),
    Character(
      id: 'char_12',
      name: 'شخصیت ۱۲',
      imagePath: 'assets/profiles/char_12.png',
      price: 100,
    ),
    Character(
      id: 'char_13',
      name: 'شخصیت ۱۳',
      imagePath: 'assets/profiles/char_13.png',
      price: 100,
    ),
    Character(
      id: 'char_14',
      name: 'شخصیت ۱۴',
      imagePath: 'assets/profiles/char_14.png',
      price: 100,
    ),
    Character(
      id: 'char_15',
      name: 'شخصیت ۱۵',
      imagePath: 'assets/profiles/char_15.png',
      price: 100,
    ),
    Character(
      id: 'char_16',
      name: 'شخصیت ۱۶',
      imagePath: 'assets/profiles/char_16.png',
      price: 100,
    ),
    Character(
      id: 'char_17',
      name: 'شخصیت ۱۷',
      imagePath: 'assets/profiles/char_17.png',
      price: 100,
    ),
    Character(
      id: 'char_18',
      name: 'شخصیت ۱۸',
      imagePath: 'assets/profiles/char_18.png',
      price: 100,
    ),
  ];

  static Character? byId(String? id) {
    if (id == null) return null;
    for (final c in catalog) {
      if (c.id == id) return c;
    }
    return null;
  }
}
