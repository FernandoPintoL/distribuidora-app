import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../extensions/carrito_theme_extension.dart';
import '../../extensions/theme_extension.dart';
import 'carrito_item_ahorro_section.dart';

class CarritoItemCard extends StatefulWidget {
  final CarritoItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final Function(int) onUpdateCantidad;
  final DetalleCarritoConRango? detalleConRango;
  final VoidCallback? onAgregarParaAhorrar;

  const CarritoItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onUpdateCantidad,
    this.detalleConRango,
    this.onAgregarParaAhorrar,
  });

  @override
  State<CarritoItemCard> createState() => _CarritoItemCardState();
}

class _CarritoItemCardState extends State<CarritoItemCard> {
  late TextEditingController _observacionesController;
  bool _editandoObservaciones = false;
  bool _guardandoObservaciones = false;

  @override
  void initState() {
    super.initState();
    _observacionesController =
        TextEditingController(text: widget.item.observaciones ?? '');
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardarObservaciones() async {
    setState(() => _guardandoObservaciones = true);

    // Simular guardado (en producción, llamaría al provider)
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _editandoObservaciones = false;
        _guardandoObservaciones = false;
      });

      debugPrint('✅ Observaciones guardadas para ${widget.item.producto?.nombre}');
    }
  }

  void _cancelarEdicion() {
    _observacionesController.text = widget.item.observaciones ?? '';
    setState(() => _editandoObservaciones = false);
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.item.producto;
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispInt = (stockDisponible as num).toInt();
    final tieneStockSuficiente = widget.item.cantidad <= stockDispInt;
    final excedido = widget.item.cantidadExcedida;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: excedido > 0 ? 2 : 0,
      color: excedido > 0 ? context.carritoErrorBg : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImagePlaceholder(),
                ),
                const SizedBox(width: 12),

                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto con badge de stock
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              producto.nombre,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStockBadge(context, stockDispInt),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Código del producto
                      Text(
                        'Código: ${producto.codigo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.carritoSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 🔑 NUEVO: Precio con comparativa si cambió de rango
                      _buildPrecioUnitarioSection(context),
                      const SizedBox(height: 8),

                      // Controles de cantidad
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botones de cantidad
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: tieneStockSuficiente
                                    ? context.carritorBorderColor
                                    : context.carritoErrorBorder,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: widget.onDecrement,
                                  icon: const Icon(Icons.remove, size: 18),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    widget.item.cantidad.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: tieneStockSuficiente
                                          ? context.carritoQuantityText
                                          : context.carritoErrorIcon,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onIncrement,
                                  icon: const Icon(Icons.add, size: 18),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🔑 NUEVO: Subtotal con comparativa si cambió de rango
                          Flexible(
                            child: _buildSubtotalComparativo(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón eliminar
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(Icons.delete_outline, color: context.carritoDeleteIconColor),
                  tooltip: 'Eliminar',
                ),
              ],
            ),

            // Mostrar advertencia de stock si excede
            if (excedido > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.carritoErrorBg,
                    border: Border.all(color: context.carritoErrorBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: context.carritoErrorIcon, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stock insuficiente: $excedido unidades excedidas. Máximo disponible: $stockDispInt',
                          style: TextStyle(
                            color: context.carritoErrorText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Sección de observaciones (editable en línea)
            /*Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildObservacionesSection(),
            ),*/

            // 🔑 NUEVO: Línea compacta de ahorro (reemplaza el panel grande)
            if (widget.detalleConRango?.tieneOportunidadAhorro ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.carritoSavingsBg,
                    border: Border.all(color: context.carritoSavingsBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_down,
                        size: 14,
                        color: context.carritoSavingsIcon,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '💚 Ahorro: Bs ${widget.detalleConRango!.ahorroProximo!.toStringAsFixed(2)} | Agrega ${widget.detalleConRango!.proximoRango!.faltaCantidad}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.carritoSavingsText,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 28,
                        child: TextButton.icon(
                          onPressed: widget.onAgregarParaAhorrar,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Añadir', style: TextStyle(fontSize: 10)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                            foregroundColor: context.carritoSavingsIcon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de observaciones con edición en línea
  Widget _buildObservacionesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.carritoNotesBg,
        border: Border.all(color: context.carritoNotesBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _editandoObservaciones
          ? _buildObservacionesEditing()
          : _buildObservacionesViewing(),
    );
  }

  /// Vista de solo lectura (mostrar notas)
  Widget _buildObservacionesViewing() {
    return GestureDetector(
      onTap: () {
        setState(() => _editandoObservaciones = true);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note, color: context.carritoNotesIcon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.item.observaciones != null &&
                    widget.item.observaciones!.isNotEmpty)
                  Text(
                    widget.item.observaciones!,
                    style: TextStyle(
                      color: context.carritoNotesText,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Agregar nota (toca para editar)',
                    style: TextStyle(
                      color: context.carritoNotesIcon,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.edit, color: context.carritoNotesIcon, size: 16),
        ],
      ),
    );
  }

  /// Vista de edición (campo de texto)
  Widget _buildObservacionesEditing() {
    return Column(
      children: [
        TextField(
          controller: _observacionesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Agregar nota para este producto...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          style: const TextStyle(fontSize: 13),
          onSubmitted: (_) => _guardarObservaciones(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelarEdicion,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _guardandoObservaciones ? null : _guardarObservaciones,
              icon: _guardandoObservaciones
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                _guardandoObservaciones ? 'Guardando...' : 'Guardar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockBadge(BuildContext context, int stockDisponible) {
    final isLowStock = stockDisponible > 0 && stockDisponible <= 5;
    final isOutOfStock = stockDisponible <= 0;

    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              'Agotado',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Poco stock',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'Disponible',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el subtotal con comparativa si cambió de rango
  ///
  /// Muestra el subtotal anterior tachado si se aplicó un descuento por rango
  Widget _buildSubtotalComparativo(BuildContext context) {
    final detalleConRango = widget.detalleConRango;
    final subtotalActual = widget.item.subtotal;
    final subtotalBajoRango = detalleConRango?.subtotal ?? subtotalActual;

    // Detectar si cambio de tipo de precio (no es VENTA por defecto)
    final cambioDePrecio = detalleConRango != null &&
                           detalleConRango.tipoPrecioId != 2 &&
                           subtotalBajoRango != subtotalActual;

    if (!cambioDePrecio) {
      // Sin cambios: mostrar solo el subtotal actual
      return Text(
        'Bs ${subtotalActual.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    // Con cambios: mostrar comparativa en columna
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Subtotal anterior tachado
        Text(
          'Bs ${subtotalActual.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
        // Subtotal nuevo con énfasis
        Text(
          'Bs ${subtotalBajoRango.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  /// Construye la sección de precio con comparativa si cambió de rango
  ///
  /// Si el tipo de precio es diferente al de venta (tipo_precio_id != 2),
  /// muestra el precio anterior tachado y el nuevo precio
  Widget _buildPrecioUnitarioSection(BuildContext context) {
    final detalleConRango = widget.detalleConRango;
    final precioActual = widget.item.precioUnitario;
    final precioBajoRango = detalleConRango?.precioUnitario ?? precioActual;

    // Detectar si cambio de tipo de precio (no es VENTA por defecto)
    final cambioDePrecio = detalleConRango != null &&
                           detalleConRango.tipoPrecioId != 2 &&
                           precioBajoRango != precioActual;

    if (!cambioDePrecio) {
      // Sin cambios: mostrar solo el precio actual + tipo de precio
      return Row(
        children: [
          Text(
            'Bs ${precioActual.toStringAsFixed(2)} c/u',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 8),
          // Badge tipo de precio solo si es diferente a VENTA
          if (detalleConRango != null && detalleConRango.tipoPrecioId != 2)
            _buildTipoPrecioBadge(detalleConRango.tipoPrecioNombre),
        ],
      );
    }

    // Con cambios: mostrar comparativa (precio anterior tachado + precio nuevo)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Precio anterior tachado
        Text(
          'Bs ${precioActual.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        // Nuevo precio con énfasis (comprimido)
        Flexible(
          child: Text(
            'Bs ${precioBajoRango.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        // Badge tipo de precio (compacto)
        _buildTipoPrecioBadge(detalleConRango!.tipoPrecioNombre),
      ],
    );
  }

  /// Construye badge compacto del tipo de precio
  Widget _buildTipoPrecioBadge(String tipoPrecioNombre) {
    final colorMap = {
      'Precio de Venta': Colors.blue,
      'P. Descuento': Colors.green,
      'P. Especial': Colors.orange,
      'Descuento': Colors.green,
      'Especial': Colors.orange,
    };

    final color = colorMap.entries
        .firstWhere(
          (e) => tipoPrecioNombre.contains(e.key),
          orElse: () => MapEntry('default', Colors.blue),
        )
        .value;

    // 🔑 Crear etiqueta corta pero clara
    final badgeText = _getBadgeLabel(tipoPrecioNombre);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade600,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Obtener etiqueta corta para el badge del tipo de precio
  String _getBadgeLabel(String tipoPrecioNombre) {
    if (tipoPrecioNombre.contains('Venta')) return 'V';
    if (tipoPrecioNombre.contains('Descuento') || tipoPrecioNombre.contains('Desc')) return 'D';
    if (tipoPrecioNombre.contains('Especial') || tipoPrecioNombre.contains('Esp')) return 'E';
    return 'P';
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }
}
