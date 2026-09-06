import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AvatarUtils {
  /// Returns the matching Color for any named preset avatar
  static Color getAvatarColor(String? avatarName) {
    switch (avatarName) {
      case 'avatar_teal':
        return const Color(0xFF0D9488);
      case 'avatar_gold':
        return const Color(0xFFF59E0B);
      case 'avatar_blue':
        return const Color(0xFF3B82F6);
      case 'avatar_orange':
        return const Color(0xFFE07A5F);
      case 'avatar_purple':
        return const Color(0xFF8B5CF6);
      case 'avatar_green':
      default:
        return const Color(0xFF1F6F4A);
    }
  }

  static ImageProvider? getAvatarImageProvider(String? pic) {
    if (pic == null || pic.trim().isEmpty || pic.startsWith('avatar_')) {
      return null;
    }
    final trimmed = pic.trim();

    // 1. Data URI base64 (e.g. data:image/jpeg;base64,...)
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Data = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final clean = base64Data.replaceAll(RegExp(r'\s+'), '');
        return MemoryImage(base64Decode(clean));
      } catch (_) {
        return null;
      }
    }

    // 2. HTTP / HTTPS network image
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    // 3. Raw base64 string without data:image prefix (e.g. /9j/... for JPEG or iVBOR... for PNG)
    if (trimmed.startsWith('/9j/') || trimmed.startsWith('iVBOR') || trimmed.startsWith('R0lGOD')) {
      try {
        final clean = trimmed.replaceAll(RegExp(r'\s+'), '');
        return MemoryImage(base64Decode(clean));
      } catch (_) {
        return null;
      }
    }

    // 4. Asset image
    if (trimmed.startsWith('assets/')) {
      return AssetImage(trimmed);
    }

    // 5. Local file path (strictly disabled on web to avoid UnsupportedError)
    if (!kIsWeb) {
      if (trimmed.startsWith('/') ||
          trimmed.startsWith('file:') ||
          RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(trimmed)) {
        try {
          final filePath = trimmed.startsWith('file://') ? trimmed.replaceFirst('file://', '') : trimmed;
          final file = io.File(filePath);
          if (file.existsSync()) {
            return FileImage(file);
          }
        } catch (_) {}
      }
    }

    return null;
  }
}

