import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/custom_colors.dart';

/// Utility class for UX enhancements
class UXHelpers {
  /// Shows an exit confirmation dialog
  static Future<bool> showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              color: CustomColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Exit App?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit Document Companion?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: CustomColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Provides haptic feedback for selection
  static void selectionFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Provides haptic feedback for light impact
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Provides haptic feedback for medium impact
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Provides haptic feedback for heavy impact
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Provides haptic feedback for successful actions
  static void successFeedback() {
    HapticFeedback.mediumImpact();
  }

  /// Provides haptic feedback for error actions
  static void errorFeedback() {
    HapticFeedback.heavyImpact();
  }
}

