import 'package:flutter/material.dart';

import '../../models/tag.dart';
import '../../theme/app_colors.dart';

/// Colored tag chip mirroring TAG_COLORS from the web's mock-data.ts.
/// [selected] draws it with a ring, used by the tag picker/filter row.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
  });

  final Tag tag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.tagColors[tag.label]!;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: selected ? Border.all(color: fg, width: 1.5) : null,
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: pill,
    );
  }
}
