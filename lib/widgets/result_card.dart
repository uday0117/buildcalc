import 'package:flutter/material.dart';

class ResultRowItem {
  final String label;
  final String value;
  final bool isPrimary;
  final String? subtitle;

  const ResultRowItem({
    required this.label,
    required this.value,
    this.isPrimary = false,
    this.subtitle,
  });
}

class ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ResultRowItem> rows;
  final String? note;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const ResultCard({
    super.key,
    this.title = 'Results',
    this.icon = Icons.analytics_rounded,
    required this.rows,
    this.note,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF8C00), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (onSave != null)
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    color: Colors.white70,
                    tooltip: 'Save to Bookmarks',
                    onPressed: onSave,
                  ),
                if (onShare != null)
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    color: Colors.white70,
                    tooltip: 'Share',
                    onPressed: onShare,
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // Primary / key metric callouts if any
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...rows.map((row) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.label,
                                style: TextStyle(
                                  fontSize: row.isPrimary ? 16 : 14,
                                  fontWeight: row.isPrimary
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: row.isPrimary
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              if (row.subtitle != null)
                                Text(
                                  row.subtitle!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          row.value,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: row.isPrimary ? 20 : 16,
                            fontWeight: FontWeight.bold,
                            color: row.isPrimary
                                ? const Color(0xFFFF8C00)
                                : const Color(0xFFFFA726),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
