import 'package:flutter/material.dart';
import '../../../a11y/a11y.dart';

/// MTDS Block card component for grid layouts
class MtdsBlock extends StatelessWidget {
  const MtdsBlock({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge; // e.g., "Pro" or "1m"
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF0F2436);
    const textPrimary = Color(0xFFF2F5F7);
    const textSecondary = Color(0xFFC7D1DD);
    const border = Color(0x66274862);
    const badgeBackground = Color(0xFF16354B);

    final textScaler = A11y.getClampedTextScale(context);

    return A11y.ensureMinTouchTarget(
      Semantics(
        button: true,
        label: badge != null ? '$title, $badge' : title,
        hint: subtitle,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          highlightColor: const Color(0x33274862),
          splashColor: const Color(0x33274862),
          child: Container(
            height: 132,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(width: 1.2, color: const Color(0xA3274862)),
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      color: textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: (16 * textScaler).toDouble(),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: (14 * textScaler).toDouble(),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: (12 * textScaler).toDouble(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}