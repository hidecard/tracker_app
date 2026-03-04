import 'package:flutter/material.dart';
import 'glass_card.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? valueColor, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final List<StatCardData> stats;
  final double spacing;

  const StatRow({super.key, required this.stats, this.spacing = 8});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index > 0 ? spacing : 0),
            child: StatCard(
              label: stat.label,
              value: stat.value,
              valueColor: stat.valueColor,
              icon: stat.icon,
              iconColor: stat.iconColor,
              onTap: stat.onTap,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class StatCardData {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatCardData({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    this.iconColor,
    this.onTap,
  });
}
