import 'package:flutter/material.dart';
import '../models/triage_level.dart';

class TriageBadge extends StatelessWidget {
  final TriageLevel level;
  final bool isCompact;

  const TriageBadge({
    super.key,
    required this.level,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: level.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: level.borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: 14, color: level.primaryColor),
            const SizedBox(width: 4),
            Text(
              level.shortTag,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: level.textColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: level.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: level.primaryColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: 18, color: level.primaryColor),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: level.textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
