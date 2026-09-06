import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class AvatarUtils {
  static ImageProvider? getAvatarImageProvider(String? pic) {
    if (pic == null || pic.trim().isEmpty || pic.startsWith('avatar_')) {
      return null;
    }
    final trimmed = pic.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Data = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        return MemoryImage(base64Decode(base64Data));
      } catch (_) {
        return null;
      }
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    if (trimmed.startsWith('/') || trimmed.startsWith('C:') || trimmed.startsWith('file:')) {
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
      return null;
    }
    if (trimmed.startsWith('assets/')) {
      return AssetImage(trimmed);
    }
    return null;
  }
}
