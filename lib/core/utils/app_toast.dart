import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color bg;
    Color border;
    IconData icon;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        bg = const Color(0xFF064E3B);
        border = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case ToastType.error:
        bg = const Color(0xFF7F1D1D);
        border = const Color(0xFFEF4444);
        icon = Icons.error_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      case ToastType.warning:
        bg = const Color(0xFF78350F);
        border = const Color(0xFFF59E0B);
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case ToastType.info:
        bg = const Color(0xFF0F294A);
        border = const Color(0xFF38BDF8);
        icon = Icons.info_rounded;
        iconColor = const Color(0xFF38BDF8);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border.withValues(alpha: 0.5), width: 1.2),
        ),
        duration: duration,
      ),
    );
  }
}
