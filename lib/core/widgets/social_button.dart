import 'package:flutter/material.dart';

enum SocialType { twitter, facebook, google, instagram }

class SocialButton extends StatelessWidget {
  final SocialType type;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.type,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case SocialType.twitter:
        label = 'twitter';
        icon = Icons.tag_rounded;
        color = const Color(0xFF1DA1F2);
        break;
      case SocialType.facebook:
        label = 'facebook';
        icon = Icons.facebook_outlined;
        color = const Color(0xFF1877F2);
        break;
      case SocialType.google:
        label = 'g+ google';
        icon = Icons.g_mobiledata_rounded;
        color = const Color(0xFFEA4335);
        break;
      case SocialType.instagram:
        label = 'instagram';
        icon = Icons.camera_alt_outlined;
        color = const Color(0xFFC13584);
        break;
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
