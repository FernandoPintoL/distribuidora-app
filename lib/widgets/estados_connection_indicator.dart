/// Widget para mostrar el estado de conexión WebSocket en tiempo real
///
/// Muestra indicadores visuales: ✓ Conectado, ⟳ Sincronizando, × Sin conexión

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estado_event.dart';
import '../providers/estados_realtime_provider.dart';

/// Indicator compacto de conexión (para usar en AppBar)
class EstadosConnectionIndicator extends ConsumerWidget {
  final bool showLabel;
  final TextStyle? labelStyle;

  const EstadosConnectionIndicator({
    Key? key,
    this.showLabel = true,
    this.labelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(estadosConnectionStateStreamProvider);

    return connectionState.when(
      data: (state) => _buildIndicator(context, state),
      loading: () => _buildLoadingIndicator(context),
      error: (error, stack) => _buildErrorIndicator(context, error.toString()),
    );
  }

  Widget _buildIndicator(BuildContext context, EstadoConnectionState state) {
    if (state.isConnected) {
      return _buildConnectedIndicator(context);
    } else if (state.isConnecting) {
      return _buildSyncingIndicator(context);
    } else {
      return _buildDisconnectedIndicator(context, state.error);
    }
  }

  Widget _buildConnectedIndicator(BuildContext context) {
    return Tooltip(
      message: 'En vivo',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi,
            size: 16,
            color: Colors.green[600],
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'En vivo',
              style: labelStyle ??
                  TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncingIndicator(BuildContext context) {
    return Tooltip(
      message: 'Sincronizando...',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'Sincronizando...',
              style: labelStyle ??
                  TextStyle(
                    color: Colors.amber[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisconnectedIndicator(BuildContext context, String? error) {
    return Tooltip(
      message: error ?? 'Sin conexión',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: Colors.red[600],
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'Sin conexión',
              style: labelStyle ??
                  TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Tooltip(
      message: 'Cargando...',
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
        ),
      ),
    );
  }

  Widget _buildErrorIndicator(BuildContext context, String error) {
    return Tooltip(
      message: error,
      child: Icon(
        Icons.error_outline,
        size: 16,
        color: Colors.red[600],
      ),
    );
  }
}

/// Dialog para mostrar estado detallado de conexión
class EstadosConnectionStatusDialog extends ConsumerWidget {
  const EstadosConnectionStatusDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(estadosConnectionStateStreamProvider);
    final eventStream = ref.watch(estadosEventStreamProvider);

    return AlertDialog(
      title: const Text('Estado de Conexión'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          connectionState.when(
            data: (state) => _buildStatusDetails(state),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Últimos Eventos:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          eventStream.when(
            data: (_) => const Text('Escuchando eventos...'),
            loading: () => const Text('Cargando eventos...'),
            error: (error, stack) => Text('Error: $error'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildStatusDetails(EstadoConnectionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(
          'Estado:',
          state.isConnected
              ? '✓ Conectado'
              : state.isConnecting
                  ? '⟳ Conectando...'
                  : '× Desconectado',
          state.isConnected
              ? Colors.green
              : state.isConnecting
                  ? Colors.amber
                  : Colors.red,
        ),
        const SizedBox(height: 8),
        _buildStatusRow(
          'Última conexión:',
          _formatTime(state.lastConnected),
          Colors.grey,
        ),
        if (state.lastDisconnected != null) ...[
          const SizedBox(height: 8),
          _buildStatusRow(
            'Última desconexión:',
            _formatTime(state.lastDisconnected!),
            Colors.grey,
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 8),
          _buildStatusRow(
            'Última error:',
            state.error!,
            Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'hace ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'hace ${diff.inHours}h';
    } else {
      return 'hace ${diff.inDays}d';
    }
  }
}

/// Banner que aparece cuando se pierde conexión
class EstadosConnectionBanner extends ConsumerWidget {
  const EstadosConnectionBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(estadosConnectionStateStreamProvider);

    return connectionState.when(
      data: (state) {
        if (state.isConnected) {
          return const SizedBox.shrink(); // No mostrar si está conectado
        }

        return Container(
          width: double.infinity,
          color: state.isConnecting ? Colors.amber[100] : Colors.red[100],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                state.isConnecting ? Icons.sync : Icons.wifi_off,
                color: state.isConnecting ? Colors.amber[700] : Colors.red[700],
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.isConnecting
                          ? 'Sincronizando cambios...'
                          : 'Sin conexión en tiempo real',
                      style: TextStyle(
                        color: state.isConnecting
                            ? Colors.amber[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: state.isConnecting
                              ? Colors.amber[600]
                              : Colors.red[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => Container(
        width: double.infinity,
        color: Colors.red[100],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error de conexión: $error',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
