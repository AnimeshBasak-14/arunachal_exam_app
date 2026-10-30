import 'package:flutter/material.dart';
import '../../theme/aura.dart';
import '../../utils/avatar_utils.dart';

/// Profile photo, or the first letter of the name on a soft accent circle.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? pic;
  final double size;
  const UserAvatar({super.key, required this.name, this.pic, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final image = AvatarUtils.getAvatarImageProvider(pic);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: a.accentSoft,
        border: Border.all(color: a.hairline),
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : Text(name.trim().isEmpty ? '·' : name.trim()[0].toUpperCase(),
              style: AuraType.serif(size * 0.43, a.accent,
                  weight: FontWeight.w600)),
    );
  }
}
