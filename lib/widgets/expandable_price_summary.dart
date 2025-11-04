import 'package:flutter/material.dart';

/// Widget expandible que muestra desglose detallado de precios
///
/// Estados:
/// - Colapsado: Solo muestra total
/// - Expandido: Muestra subtotal, impuesto, envío, descuento, total
class ExpandablePriceSummary extends StatefulWidget {
  final double subtotal;
  final double impuesto;
  final double costoEnvio;
  final double descuento;
  final double porcentajeDescuento;

  /// Si está preseleccionado expandido
  final bool initiallyExpanded;

  /// Color para líneas positivas (subtotal, impuesto, envío)
  final Color positiveColor;

  /// Color para líneas negativas (descuento)
  final Color negativeColor;

  /// Color del total
  final Color totalColor;

  const ExpandablePriceSummary({
    super.key,
    required this.subtotal,
    required this.impuesto,
    required this.costoEnvio,
    required this.descuento,
    this.porcentajeDescuento = 0,
    this.initiallyExpanded = false,
    this.positiveColor = const Color(0xFF666666),
    this.negativeColor = const Color(0xFF2E7D32),
    this.totalColor = const Color(0xFF1976D2),
  });

  @override
  State<ExpandablePriceSummary> createState() => _ExpandablePriceSummaryState();
}

class _ExpandablePriceSummaryState extends State<ExpandablePriceSummary>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  double get _totalConDescuento =>
      widget.subtotal - widget.descuento + widget.impuesto + widget.costoEnvio;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Siempre visible
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: widget.totalColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Resumen de Precios',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.totalColor,
                            ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: widget.totalColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          if (_isExpanded)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.shade300,
            ),

          // Contenido expandible
          SizeTransition(
            sizeFactor: _heightAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Subtotal
                  _buildPriceLine(
                    context,
                    label: 'Subtotal',
                    amount: widget.subtotal,
                    color: widget.positiveColor,
                    icon: Icons.shopping_cart_rounded,
                  ),
                  const SizedBox(height: 12),

                  // Impuesto
                  _buildPriceLine(
                    context,
                    label: 'Impuesto',
                    amount: widget.impuesto,
                    color: widget.positiveColor,
                    icon: Icons.percent_rounded,
                  ),
                  const SizedBox(height: 12),

                  // Envío (solo si > 0)
                  if (widget.costoEnvio > 0) ...[
                    _buildPriceLine(
                      context,
                      label: 'Envío',
                      amount: widget.costoEnvio,
                      color: widget.positiveColor,
                      icon: Icons.local_shipping_rounded,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Descuento (solo si > 0)
                  if (widget.descuento > 0) ...[
                    _buildPriceLine(
                      context,
                      label: widget.porcentajeDescuento > 0
                          ? 'Descuento (${widget.porcentajeDescuento.toStringAsFixed(0)}%)'
                          : 'Descuento',
                      amount: -widget.descuento,
                      color: widget.negativeColor,
                      icon: Icons.discount_rounded,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Divider antes del total
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),

                  // Total
                  _buildTotalLine(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una línea de precio con ícono, label y monto
  Widget _buildPriceLine(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? amount.abs() : amount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
        Text(
          '${isNegative ? '-' : ''}Bs ${displayAmount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  /// Construye la línea de total final
  Widget _buildTotalLine(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TOTAL A PAGAR',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: widget.totalColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'Bs ${_totalConDescuento.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: widget.totalColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
      ],
    );
  }
}
