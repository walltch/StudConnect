import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Row of selectable color swatches for an account's avatar background.
/// Shared by signup and profile editing so both pick from the same
/// palette (AppColors.avatarPalette).
class AvatarColorPicker extends StatelessWidget {
  const AvatarColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// ARGB value of the currently selected color.
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in AppColors.avatarPalette)
          _Swatch(
            color: color,
            isSelected: color.toARGB32() == selected,
            onTap: () => onChanged(color.toARGB32()),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.slate800, width: 3)
              : null,
        ),
        alignment: Alignment.center,
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
