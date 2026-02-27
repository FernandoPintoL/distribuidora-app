import 'package:flutter/material.dart';

import '../../../config/app_text_styles.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
        fontSize: AppTextStyles.bodyLarge(context).fontSize!,
        letterSpacing: 0.5,
      ),
    );
  }
}
