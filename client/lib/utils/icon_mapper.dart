import 'package:flutter/material.dart';

class IconMapper {
  static const Map<String, IconData> _iconMap = {
    'lock_rounded': Icons.lock_rounded,
    'cloud_upload': Icons.cloud_upload_rounded,
    'security': Icons.security_rounded,
    'api': Icons.api_rounded,
    'bolt': Icons.bolt_rounded,
  };

  static IconData getIcon(String iconName) {
    return _iconMap[iconName] ?? Icons.help_outline_rounded;
  }
}
