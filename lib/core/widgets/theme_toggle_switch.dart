import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A custom pill toggle switch matching the modern dual-tone design
/// with a soft track and vibrant thumb for toggling Light and Dark mode.
class ThemeToggleSwitch extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const ThemeToggleSwitch({
    super.key,
    required this.isDark,
    required this.onChanged,
    this.width = 52,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = height - 6;

    // Track colors based on active theme
    final trackColor = isDark
        ? const Color(0xFFA5C8FE) // Soft periwinkle/blue from user image
        : (context.isDark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0));

    // Thumb colors based on active theme
    final thumbColor = isDark
        ? const Color(0xFF3B82F6) // Vibrant blue circle from user image
        : const Color(0xFF94A3B8);

    return Semantics(
      label: isDark ? 'Dark mode enabled' : 'Light mode enabled',
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!isDark),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: trackColor,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: thumbColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
