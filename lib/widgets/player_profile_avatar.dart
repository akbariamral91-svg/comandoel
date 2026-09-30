import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/player.dart';

/// دایره‌ی عکس پروفایل بازیکن - اگر بازیکن شخصیتی از فروشگاه انتخاب کرده باشد
/// عکس آن شخصیت را نشان می‌دهد؛ در غیر این صورت دایره‌ی رنگی ساده با حرف اول اسم.
class PlayerProfileAvatar extends StatelessWidget {
  final Player player;
  final double size;
  final Color borderColor;
  final double borderWidth;

  const PlayerProfileAvatar({
    super.key,
    required this.player,
    required this.size,
    this.borderColor = Colors.white,
    this.borderWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final character = Character.byId(player.characterId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: player.avatarColor,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
        ],
        image: character != null
            ? DecorationImage(
                image: AssetImage(character.imagePath),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: character == null
          ? Center(
              child: Text(
                player.name.isNotEmpty ? player.name.substring(0, 1) : '؟',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: size * 0.42,
                ),
              ),
            )
          : null,
    );
  }
}
