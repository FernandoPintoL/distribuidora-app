import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_text_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../../extensions/theme_extension.dart';

class PerfilAppearanceCardWidget extends StatelessWidget {
  const PerfilAppearanceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = context.isDark;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHighest.withAlpha(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                          color: isDarkMode ? Colors.amber : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Modo ${isDarkMode ? 'Oscuro' : 'Claro'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isDarkMode
                          ? 'Interfaz oscura para menos luz'
                          : 'Interfaz clara para mejor visibilidad',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Switch(
                  key: ValueKey(isDarkMode),
                  value: isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: Colors.amber,
                  activeTrackColor: Colors.amber.shade200,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
