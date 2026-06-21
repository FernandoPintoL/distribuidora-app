import 'package:flutter/material.dart';

/// Widget reutilizable para input de cantidad con botones + y -
/// Se puede usar en carrito, productos, pedidos, etc.
class QuantityInputWidget extends StatefulWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Function(String)? onChanged;
  final Color? primaryColor;
  final double? size;
  final bool enabled;
  final bool fullWidth;

  const QuantityInputWidget({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
    this.onChanged,
    this.primaryColor,
    this.size,
    this.enabled = true,
    this.fullWidth = false,
  });

  @override
  State<QuantityInputWidget> createState() => _QuantityInputWidgetState();
}

class _QuantityInputWidgetState extends State<QuantityInputWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(QuantityInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.quantity != widget.quantity) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChange(String value) {
    if (!widget.enabled) return;

    if (value.isEmpty) return;

    final cantidad = int.tryParse(value) ?? 0;
    if (cantidad <= 0 || cantidad > widget.maxQuantity) {
      _controller.text = widget.quantity.toString();
      return;
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.primaryColor ?? const Color(0xFFFFB800);
    final buttonSize = widget.size ?? 40.0;
    final opacity = widget.enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withAlpha(150), width: 2),
        ),
        // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: widget.fullWidth
              ? MainAxisAlignment.spaceEvenly
              : MainAxisAlignment.center,
          children: [
            // Botón Decrementar
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? widget.onDecrement : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.remove, size: 18, color: Colors.black87),
                  ),
                ),
              ),
            ),
            // Campo de cantidad editable
            Expanded(
              child: SizedBox(
                height: buttonSize,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  enabled: widget.enabled,
                  onChanged: _handleChange,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: accentColor.withAlpha(80),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Botón Incrementar
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? widget.onIncrement : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add, size: 18, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
