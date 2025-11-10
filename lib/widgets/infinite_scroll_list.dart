import 'package:flutter/material.dart';

/// Widget reutilizable para implementar scroll infinito en cualquier lista
///
/// Características:
/// - Carga automática al hacer scroll
/// - Pull-to-refresh
/// - Estados de carga (inicial, cargando más, vacío, error)
/// - Indicadores visuales modernos
/// - Completamente personalizable
class InfiniteScrollList<T> extends StatefulWidget {
  /// Lista de items a mostrar
  final List<T> items;

  /// Función para construir cada item de la lista
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Función para cargar más items
  /// Retorna true si la carga fue exitosa
  final Future<bool> Function() onLoadMore;

  /// Función para refrescar la lista
  final Future<void> Function() onRefresh;

  /// Indica si hay más páginas disponibles
  final bool hasMorePages;

  /// Indica si se está cargando más items
  final bool isLoadingMore;

  /// Indica si es la carga inicial
  final bool isInitialLoading;

  /// Mensaje cuando la lista está vacía
  final String emptyMessage;

  /// Icono cuando la lista está vacía
  final IconData emptyIcon;

  /// Mensaje de error (null si no hay error)
  final String? errorMessage;

  /// Distancia en píxeles desde el final para trigger la carga
  final double loadMoreThreshold;

  /// Padding de la lista
  final EdgeInsets? padding;

  /// Separador entre items
  final Widget? separator;

  /// Header de la lista (opcional)
  final Widget? header;

  /// Footer de la lista (opcional)
  final Widget? footer;

  const InfiniteScrollList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    required this.hasMorePages,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.emptyMessage = 'No hay elementos para mostrar',
    this.emptyIcon = Icons.inbox_outlined,
    this.errorMessage,
    this.loadMoreThreshold = 200,
    this.padding,
    this.separator,
    this.header,
    this.footer,
  });

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - widget.loadMoreThreshold) {
      if (!widget.isLoadingMore && widget.hasMorePages) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estado: Carga inicial
    if (widget.isInitialLoading && widget.items.isEmpty) {
      return _buildInitialLoadingState();
    }

    // Estado: Error
    if (widget.errorMessage != null && widget.items.isEmpty) {
      return _buildErrorState();
    }

    // Estado: Vacío
    if (widget.items.isEmpty) {
      return _buildEmptyState();
    }

    // Estado: Lista con items
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: _calculateItemCount(),
        itemBuilder: (context, index) {
          // Header
          if (widget.header != null && index == 0) {
            return widget.header!;
          }

          // Ajustar índice si hay header
          final adjustedIndex = widget.header != null ? index - 1 : index;

          // Items de la lista
          if (adjustedIndex < widget.items.length) {
            final item = widget.items[adjustedIndex];
            final itemWidget = widget.itemBuilder(context, item, adjustedIndex);

            // Agregar separador si existe
            if (widget.separator != null && adjustedIndex < widget.items.length - 1) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  itemWidget,
                  widget.separator!,
                ],
              );
            }

            return itemWidget;
          }

          // Footer
          if (widget.footer != null && adjustedIndex == widget.items.length) {
            return widget.footer!;
          }

          // Indicador de carga al final
          final footerOffset = widget.footer != null ? 1 : 0;
          if (adjustedIndex == widget.items.length + footerOffset) {
            return _buildLoadingMoreIndicator();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  int _calculateItemCount() {
    int count = widget.items.length;

    if (widget.header != null) count++;
    if (widget.footer != null) count++;
    if (widget.isLoadingMore) count++;

    return count;
  }

  Widget _buildInitialLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.emptyIcon,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.emptyMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Desliza hacia abajo para recargar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error al cargar',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.errorMessage ?? 'Ocurrió un error desconocido',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cargando más...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
