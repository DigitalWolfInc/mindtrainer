/// MTDS Section Header - Small overline + title for grouping content
import 'package:flutter/material.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Section header with optional overline and title
/// Used for grouping related content sections
class MtdsSectionHeader extends StatelessWidget {
  const MtdsSectionHeader({
    super.key,
    required this.text,
    this.overline,
    this.padding,
  });

  final String text;
  final String? overline;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.fromLTRB(
      MtdsSpacing.lg,
      MtdsSpacing.xl,
      MtdsSpacing.lg,
      MtdsSpacing.md,
    );

    return Padding(
      padding: padding ?? defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional overline
          if (overline != null) ...[
            Text(
              overline!.toUpperCase(),
              style: MtdsTypography.overline.copyWith(
                color: MtdsColors.textSecondary,
              ),
              semanticsLabel: overline,
            ),
            SizedBox(height: MtdsSpacing.xs),
          ],
          
          // Main section title
          Text(
            text,
            style: MtdsTypography.body.copyWith(
              color: MtdsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            semanticsLabel: text,
          ),
        ],
      ),
    );
  }
}