/// MTDS Header - Page titles with calm subtitles
import 'package:flutter/material.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Page header with title and optional subtitle
/// Follows MTDS typography scale and spacing
class MtdsHeader extends StatelessWidget {
  const MtdsHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.fromLTRB(
      MtdsSpacing.lg,
      MtdsSpacing.xl,
      MtdsSpacing.lg,
      MtdsSpacing.lg,
    );

    return Padding(
      padding: padding ?? defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main title
          Text(
            title,
            style: MtdsTypography.title.copyWith(
              color: MtdsColors.textPrimary,
            ),
            semanticsLabel: title,
          ),
          
          // Optional subtitle
          if (subtitle != null) ...[
            SizedBox(height: MtdsSpacing.xs),
            Text(
              subtitle!,
              style: MtdsTypography.body.copyWith(
                color: MtdsColors.textSecondary,
              ),
              semanticsLabel: subtitle,
            ),
          ],
        ],
      ),
    );
  }
}