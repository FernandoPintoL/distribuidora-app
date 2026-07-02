import 'package:flutter/material.dart';

class InfoChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? tooltip;
  final String? id;
  final String? estadoLogistico;

  const InfoChipWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.tooltip,
    this.id,
    this.estadoLogistico,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$label #$id",
                  style: TextStyle(fontWeight: FontWeight.w500, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                /*if (id != null && id!.isNotEmpty)
                  Text(
                    '#$id',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),*/
                if (estadoLogistico != null && estadoLogistico!.isNotEmpty)
                  Text(
                    estadoLogistico!,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip, child: chip);
    }
    return chip;
  }
}
