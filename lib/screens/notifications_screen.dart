import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../config/config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    // Configurar idioma español para timeago
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargar notificaciones solo cuando se abre la pantalla por primera vez
    if (_isFirstLoad) {
      _isFirstLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationProvider>().loadAllNotifications();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Notificaciones',
        customGradient: AppGradients.blue,
        actions: [
          // Marcar todas como leídas
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Marcar todas como leídas',
                  onPressed: () => _markAllAsRead(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Menú de opciones
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete_all') {
                    _confirmDeleteAll(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep,
                          color: isDarkMode ? Colors.red.shade400 : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eliminar todas',
                          style: TextStyle(
                            color: isDarkMode ? Colors.red.shade400 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          // Mostrar loading
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mostrar error si existe
          if (provider.error != null) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isDarkMode ? Colors.red.shade400 : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.red.shade400 : Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadAllNotifications(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Mostrar lista vacía
          if (provider.notifications.isEmpty) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 100,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Te avisaremos cuando recibas nuevas notificaciones',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Mostrar lista de notificaciones
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationItem(context, notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('notification-${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade600,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar notificación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta notificación?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.red.shade400 : Colors.red,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificación eliminada'),
            backgroundColor: isDarkMode ? Colors.grey[800] : null,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: notification.read ? 0 : 2,
        color: notification.read
            ? null
            : isDarkMode
                ? Colors.blue.shade900.withAlpha((0.3 * 255).toInt())
                : Colors.blue.shade50,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.color.withAlpha(
              (isDarkMode ? 0.25 : 0.15 * 255).toInt(),
            ),
            child: Icon(
              notification.icon,
              color: notification.color,
              size: 24,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                timeago.format(notification.createdAt, locale: 'es'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert,
              size: 20,
              color: isDarkMode ? Colors.grey[300] : null,
            ),
            onSelected: (value) {
              if (value == 'toggle_read') {
                if (notification.read) {
                  provider.markAsUnread(notification.id);
                } else {
                  provider.markAsRead(notification.id);
                }
              } else if (value == 'delete') {
                _confirmDelete(context, notification.id, provider);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_read',
                child: Row(
                  children: [
                    Icon(
                      notification.read
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notification.read
                          ? 'Marcar como no leída'
                          : 'Marcar como leída',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: isDarkMode ? Colors.red.shade400 : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Eliminar',
                      style: TextStyle(
                        color: isDarkMode ? Colors.red.shade400 : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            // Marcar como leída si no lo está
            if (!notification.read) {
              provider.markAsRead(notification.id);
            }

            // TODO: Navegar a la pantalla correspondiente según el tipo
            _handleNotificationTap(context, notification);
          },
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    // Aquí puedes navegar a la pantalla correspondiente
    // según el tipo de notificación y los datos
    debugPrint('Notificación tap: ${notification.type}');
    debugPrint('Datos: ${notification.data}');

    // Ejemplo de navegación según el tipo:
    // if (notification.type == 'proforma.aprobada' && notification.proformaId != null) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => ProformaDetailScreen(id: notification.proformaId!),
    //     ),
    //   );
    // }
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final provider = context.read<NotificationProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.markAllAsRead();

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Todas las notificaciones marcadas como leídas'
                : 'Error al marcar notificaciones',
          ),
          backgroundColor: success
              ? (isDarkMode ? Colors.green.shade800 : Colors.green)
              : (isDarkMode ? Colors.red.shade800 : Colors.red),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    int notificationId,
    NotificationProvider provider,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta notificación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.red.shade400 : Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (mounted && confirmed == true) {
      final success = await provider.deleteNotification(notificationId);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Notificación eliminada' : 'Error al eliminar',
            ),
            backgroundColor: success
                ? (isDarkMode ? Colors.green.shade800 : Colors.green)
                : (isDarkMode ? Colors.red.shade800 : Colors.red),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final provider = context.read<NotificationProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas las notificaciones'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar TODAS las notificaciones? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.red.shade400 : Colors.red,
            ),
            child: const Text('Eliminar todas'),
          ),
        ],
      ),
    );

    if (mounted && confirmed == true) {
      final success = await provider.deleteAllNotifications();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Todas las notificaciones eliminadas'
                  : 'Error al eliminar notificaciones',
            ),
            backgroundColor: success
                ? (isDarkMode ? Colors.green.shade800 : Colors.green)
                : (isDarkMode ? Colors.red.shade800 : Colors.red),
          ),
        );
      }
    }
  }
}
