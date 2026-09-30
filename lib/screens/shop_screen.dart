import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/character.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';

/// صفحه‌ی فروشگاه: نمایش شخصیت‌های قابل‌خرید در یک جدول ریسپانسیو،
/// شمارنده‌ی الماس بالا-راست، و دکمه‌ی تست برای دریافت الماس.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _openCharacterDialog(Character character) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => _CharacterDialog(character: character),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            return Column(
              children: [
                // نوار بالا: دکمه برگشت + عنوان + شمارنده‌ی الماس
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      GoldIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        size: 46,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text(
                        'فروشگاه',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.gold,
                        ),
                      ),
                      const Spacer(),
                      _DiamondCounter(count: shop.diamonds),
                    ],
                  ),
                ),

                // دکمه‌ی تست: دریافت الماس رایگان
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<ShopProvider>().addDiamond(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        side: const BorderSide(color: AppColors.gold, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.diamond, color: Colors.cyanAccent),
                      label: const Text(
                        'دریافت یک الماس',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // جدول ریسپانسیو شخصیت‌ها - قابل اسکرول
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: w < 380 ? 150 : 170,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: Character.catalog.length,
                    itemBuilder: (context, index) {
                      final character = Character.catalog[index];
                      final owned = shop.isOwned(character.id);
                      return _CharacterCard(
                        character: character,
                        owned: owned,
                        onTap: () => _openCharacterDialog(character),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// جدول کوچک بالا-راست که تعداد الماس‌ها را نشان می‌دهد.
class _DiamondCounter extends StatelessWidget {
  final int count;
  const _DiamondCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final bool owned;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: owned ? AppColors.brightGold : AppColors.gold.withValues(alpha: 0.4),
            width: owned ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.asset(character.imagePath, fit: BoxFit.cover),
                    ),
                    if (!owned)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock, color: Colors.white70, size: 26),
                        ),
                      ),
                    if (owned)
                      const Positioned(
                        top: 0,
                        left: 0,
                        child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (owned)
                    const Text(
                      'خریداری شده',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond, color: Colors.cyanAccent, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${character.price}',
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// پنجره‌ی کوچکی که با کلیک روی یک شخصیت باز می‌شود: عکس، اسم، دکمه‌ی خرید/لغو.
class _CharacterDialog extends StatefulWidget {
  final Character character;
  const _CharacterDialog({required this.character});

  @override
  State<_CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<_CharacterDialog> {
  bool _buying = false;

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final owned = shop.isOwned(widget.character.id);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brightGold, width: 2.4),
                image: DecorationImage(
                  image: AssetImage(widget.character.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.character.name,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            if (owned)
              const Text(
                'این شخصیت قبلاً خریداری شده',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: AppColors.success,
                  fontSize: 13,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.character.price}',
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.neutralGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'لغو',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: owned || _buying
                        ? null
                        : () async {
                            setState(() => _buying = true);
                            final success = await shop.buyCharacter(widget.character);
                            if (!mounted) return;
                            setState(() => _buying = false);
                            if (success) {
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'الماس کافی نیست',
                                    textAlign: TextAlign.right,
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: owned ? AppColors.neutralGray : AppColors.brightGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      owned ? 'خریداری شده' : 'خرید',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: owned ? Colors.white70 : AppColors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
