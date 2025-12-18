import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

// ==================== NOTIFICATION BADGE ACTION ====================

/// Acción de icono con badge de notificaciones sin leer
///
/// Muestra el número de notificaciones sin leer usando un badge
/// Navega a '/notifications' cuando se presiona
///
/// Ejemplo:
/// ```dart
/// actions: [
///   NotificationBadgeAction(),
/// ]
/// ```
class NotificationBadgeAction extends StatelessWidget {
  final VoidCallback? onPressed;

  const NotificationBadgeAction({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;
        return IconButton(
          icon: Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: onPressed ??
              () {
                Navigator.pushNamed(context, '/notifications');
              },
          tooltip: 'Notificaciones',
        );
      },
    );
  }
}

// ==================== CART BADGE ACTION ====================

/// Acción de icono con badge de cantidad de items en el carrito
///
/// Muestra el número de items en el carrito usando un badge
/// Navega a '/carrito' cuando se presiona
///
/// Ejemplo:
/// ```dart
/// actions: [
///   CartBadgeAction(),
/// ]
/// ```
class CartBadgeAction extends StatelessWidget {
  final VoidCallback? onPressed;

  const CartBadgeAction({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CarritoProvider>(
      builder: (context, carritoProvider, _) {
        final itemCount = carritoProvider.items.length;
        return IconButton(
          icon: Badge(
            label: Text('$itemCount'),
            isLabelVisible: itemCount > 0,
            child: const Icon(Icons.shopping_cart),
          ),
          onPressed: onPressed ??
              () {
                Navigator.pushNamed(context, '/carrito');
              },
          tooltip: 'Carrito',
        );
      },
    );
  }
}

// ==================== REFRESH ACTION ====================

/// Acción que muestra un botón de refresh o un spinner de carga
///
/// Cuando [isLoading] es true, muestra un CircularProgressIndicator en lugar
/// del icono de refresh. Útil para indicar que se está cargando información.
///
/// Ejemplo:
/// ```dart
/// actions: [
///   RefreshAction(
///     isLoading: _isLoading,
///     onRefresh: () => _loadData(),
///   ),
/// ]
/// ```
class RefreshAction extends StatelessWidget {
  /// Si está en estado de carga
  final bool isLoading;

  /// Callback cuando se presiona el botón de refresh
  final VoidCallback onRefresh;

  /// Tooltip cuando está cargando
  final String loadingTooltip;

  /// Tooltip cuando no está cargando
  final String refreshTooltip;

  const RefreshAction({
    super.key,
    required this.isLoading,
    required this.onRefresh,
    this.loadingTooltip = 'Cargando...',
    this.refreshTooltip = 'Recargar',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      onPressed: isLoading ? null : onRefresh,
      tooltip: refreshTooltip,
    );
  }
}

// ==================== EDIT ACTION ====================

/// Acción de edición con icono decorado en un círculo
///
/// Muestra un icono de edición dentro de un círculo semitransparente
///
/// Ejemplo:
/// ```dart
/// actions: [
///   EditAction(
///     onEdit: () => _navigateToEdit(),
///   ),
/// ]
/// ```
class EditAction extends StatelessWidget {
  /// Callback cuando se presiona el botón
  final VoidCallback onEdit;

  /// Color de fondo del círculo
  final Color backgroundColor;

  /// Opacidad del fondo (0 a 1)
  final double backgroundOpacity;

  const EditAction({
    super.key,
    required this.onEdit,
    this.backgroundColor = Colors.white,
    this.backgroundOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(backgroundOpacity),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.edit, color: Colors.white),
        onPressed: onEdit,
        tooltip: 'Editar',
      ),
    );
  }
}

// ==================== LOGOUT ACTION ====================

/// Acción para cerrar sesión
///
/// Muestra un icono de logout que ejecuta un callback
///
/// Ejemplo:
/// ```dart
/// actions: [
///   LogoutAction(
///     onLogout: () => _logout(),
///   ),
/// ]
/// ```
class LogoutAction extends StatelessWidget {
  /// Callback cuando se presiona el botón
  final VoidCallback onLogout;

  const LogoutAction({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: onLogout,
      tooltip: 'Cerrar sesión',
    );
  }
}

// ==================== SEARCH ACTION ====================

/// Acción que abre un campo de búsqueda en el AppBar
///
/// Transforma el AppBar para mostrar un TextField de búsqueda
///
/// Ejemplo:
/// ```dart
/// actions: [
///   SearchAction(
///     onSearch: (query) => _search(query),
///     onClose: () => _closeSearch(),
///   ),
/// ]
/// ```
class SearchAction extends StatefulWidget {
  /// Callback cuando se ingresa texto en la búsqueda
  final Function(String) onSearch;

  /// Callback cuando se cierra la búsqueda
  final VoidCallback? onClose;

  /// Hint del TextField de búsqueda
  final String searchHint;

  const SearchAction({
    super.key,
    required this.onSearch,
    this.onClose,
    this.searchHint = 'Buscar...',
  });

  @override
  State<SearchAction> createState() => _SearchActionState();
}

class _SearchActionState extends State<SearchAction> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeSearch() {
    _controller.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearching) {
      return Container(
        width: 250,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _closeSearch,
            ),
          ),
          onChanged: widget.onSearch,
          autofocus: true,
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.search, color: Colors.white),
      onPressed: () {
        setState(() {
          _isSearching = true;
        });
      },
      tooltip: 'Buscar',
    );
  }
}

// ==================== MORE OPTIONS ACTION ====================

/// Acción que muestra un menú de opciones (PopupMenuButton)
///
/// Ejemplo:
/// ```dart
/// actions: [
///   MoreOptionsAction(
///     items: [
///       PopupMenuItem(
///         value: 'option1',
///         child: Text('Opción 1'),
///       ),
///     ],
///     onSelected: (value) => _handleOption(value),
///   ),
/// ]
/// ```
class MoreOptionsAction<T> extends StatelessWidget {
  /// Items del menú popup
  final List<PopupMenuEntry<T>> items;

  /// Callback cuando se selecciona una opción
  final Function(T) onSelected;

  /// Color del icono
  final Color iconColor;

  const MoreOptionsAction({
    super.key,
    required this.items,
    required this.onSelected,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: onSelected,
      itemBuilder: (context) => items,
    );
  }
}
