import 'package:flutter/material.dart';
import 'glass_card.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String? formatMMK;
  final bool showDeleteButton;

  const TransactionTile({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
    this.formatMMK,
    this.showDeleteButton = false,
  });

  String _formatMMK(double amount) {
    return formatMMK ?? '${amount.toStringAsFixed(0)}MMK';
  }

  @override
  Widget build(BuildContext context) {
    bool isIncome = item['type'] == 'income';
    bool isSave = item['type'] == 'save';
    String categoryText = item['category']?.toString() ?? '';
    String dateText = item['date']?.toString() ?? '';
    String noteText = item['note']?.toString() ?? '';
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;

    Color iconColor;
    Color bgColor;
    IconData icon;

    if (isSave) {
      iconColor = Colors.blue[700]!;
      bgColor = Colors.blue[50]!;
      icon = Icons.savings;
    } else if (isIncome) {
      iconColor = Colors.green[700]!;
      bgColor = Colors.green[50]!;
      icon = Icons.arrow_downward;
    } else {
      iconColor = Colors.red[700]!;
      bgColor = Colors.red[50]!;
      icon = Icons.arrow_upward;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSave
                        ? 'Save Money'
                        : (categoryText.isEmpty ? '-' : categoryText),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0077B6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    noteText.isNotEmpty
                        ? '$dateText • ${noteText.length > 15 ? '${noteText.substring(0, 15)}...' : noteText}'
                        : dateText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${_formatMMK(amountValue)}',
                  style: TextStyle(
                    color: isSave
                        ? Colors.blue[700]
                        : (isIncome ? Colors.green[700] : Colors.red[700]),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (showDeleteButton && onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionTileSimple extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;
  final String? formatMMK;

  const TransactionTileSimple({
    super.key,
    required this.item,
    this.onTap,
    this.formatMMK,
  });

  String _formatMMK(double amount) {
    return formatMMK ?? '${amount.toStringAsFixed(0)}MMK';
  }

  @override
  Widget build(BuildContext context) {
    bool isIncome = item['type'] == 'income';
    bool isSave = item['type'] == 'save';
    String categoryText = item['category']?.toString() ?? '';
    String dateText = item['date']?.toString() ?? '';
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;

    Color iconColor;
    IconData icon;

    if (isSave) {
      iconColor = Colors.blue[700]!;
      icon = Icons.savings;
    } else if (isIncome) {
      iconColor = Colors.green[700]!;
      icon = Icons.arrow_downward;
    } else {
      iconColor = Colors.red[700]!;
      icon = Icons.arrow_upward;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          isSave ? 'Save Money' : categoryText,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(dateText),
        trailing: Text(
          '${isIncome ? '+' : '-'}${_formatMMK(amountValue)}',
          style: TextStyle(
            color: isSave
                ? Colors.blue[700]
                : (isIncome ? Colors.green[700] : Colors.red[700]),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
