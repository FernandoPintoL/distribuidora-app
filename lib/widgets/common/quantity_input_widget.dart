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
    final brownColor = widget.primaryColor ?? const Color(0xFF795548);
    final containerSize = widget.size ?? 38.0;
    final opacity = widget.enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brownColor.withAlpha(25),
              brownColor.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: brownColor.withAlpha(80),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: brownColor.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: widget.fullWidth ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
          children: [
            SizedBox(
              width: containerSize,
              height: containerSize,
              child: IconButton(
                onPressed: widget.enabled ? widget.onDecrement : null,
                icon: Icon(Icons.remove, size: containerSize * 0.47),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: brownColor.withAlpha(60),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            widget.fullWidth
                ? Expanded(
                    child: SizedBox(
                      height: containerSize,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: brownColor.withAlpha(100),
                            width: 1,
                          ),
                        ),
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
                            color: brownColor,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            border: InputBorder.none,
                            hintText: '1',
                            hintStyle: TextStyle(
                              color: brownColor.withAlpha(80),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    width: containerSize + 20,
                    height: containerSize,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: brownColor.withAlpha(100),
                          width: 1,
                        ),
                      ),
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
                          color: brownColor,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: InputBorder.none,
                          hintText: '1',
                          hintStyle: TextStyle(
                            color: brownColor.withAlpha(80),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
            SizedBox(
              width: containerSize,
              height: containerSize,
              child: IconButton(
                onPressed: widget.enabled ? widget.onIncrement : null,
                icon: Icon(Icons.add, size: containerSize * 0.47),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: brownColor.withAlpha(60),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
