import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StatCard — reusable StatelessWidget for the statistics summary (Phase 3).
//
// Used three times in HomeScreen with different label, value, and colour.
// StatelessWidget is correct here because the card itself holds no mutable
// state; it re-renders whenever the parent calls setState().
// ─────────────────────────────────────────────────────────────────────────────

// STATIC: reusable summary card widget
class StatCard extends StatelessWidget {
  // STATIC: the text shown below the number
  final String label;

  // STATIC: the number to display (passed as a String for flexibility)
  final String value;

  // STATIC: background colour so each card is visually distinct
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // STATIC: Card with a coloured container inside
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // STATIC: large number at the top
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // STATIC: descriptive label below the number
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
