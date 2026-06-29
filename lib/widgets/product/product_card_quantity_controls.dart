import 'package:flutter/material.dart';

class ProductCardQuantityControls extends StatefulWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final Function(String)? onChanged;

  const ProductCardQuantityControls({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    this.onIncrement,
    this.onDecrement,
    this.onChanged,
  });

  @override
  State<ProductCardQuantityControls> createState() =>
      _ProductCardQuantityControlsState();
}

class _ProductCardQuantityControlsState
    extends State<ProductCardQuantityControls> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(
      text: widget.quantity.toString(),
    );
  }

  @override
  void didUpdateWidget(ProductCardQuantityControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _cantidadController.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  void _actualizarCantidadDesdeInput(String value) {
    if (value.isEmpty) return;

    final cantidad = int.tryParse(value) ?? 0;
    if (cantidad <= 0 || cantidad > widget.maxQuantity) {
      _cantidadController.text = widget.quantity.toString();
      return;
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccentColor = Color(0xFFFFB800);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: primaryAccentColor.withAlpha(150), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onDecrement,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryAccentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _cantidadController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onChanged: _actualizarCantidadDesdeInput,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: primaryAccentColor,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: primaryAccentColor.withAlpha(80),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onIncrement,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryAccentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
