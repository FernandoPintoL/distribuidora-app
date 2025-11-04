import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diálogo para compartir carrito con código o QR
class ShareCartDialog extends StatefulWidget {
  final String codigoCompartida;
  final String nombreCarrito;
  final VoidCallback? onClose;

  const ShareCartDialog({
    super.key,
    required this.codigoCompartida,
    required this.nombreCarrito,
    this.onClose,
  });

  @override
  State<ShareCartDialog> createState() => _ShareCartDialogState();
}

class _ShareCartDialogState extends State<ShareCartDialog> {
  bool _codigoCopiadoAlPortapapeles = false;
  bool _linkCopiadoAlPortapapeles = false;

  /// Copiar código al portapapeles
  Future<void> _copiarCodigo() async {
    await Clipboard.setData(ClipboardData(text: widget.codigoCompartida));
    setState(() => _codigoCopiadoAlPortapapeles = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _codigoCopiadoAlPortapapeles = false);
      }
    });

    debugPrint('✅ Código copiado al portapapeles: ${widget.codigoCompartida}');
  }

  /// Copiar link al portapapeles
  Future<void> _copiarLink() async {
    final link = 'myapp.com/carrito/${widget.codigoCompartida}';
    await Clipboard.setData(ClipboardData(text: link));
    setState(() => _linkCopiadoAlPortapapeles = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _linkCopiadoAlPortapapeles = false);
      }
    });

    debugPrint('✅ Link copiado al portapapeles: $link');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compartir Carrito',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onClose?.call();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nombre del carrito
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.nombreCarrito,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Código de compartida
              Text(
                'Código de compartida:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SelectableText(
                        widget.codigoCompartida,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copiarCodigo,
                      icon: Icon(
                        _codigoCopiadoAlPortapapeles
                            ? Icons.check_circle
                            : Icons.content_copy,
                        color: _codigoCopiadoAlPortapapeles
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Link compartida
              Text(
                'Link para compartir:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SelectableText(
                        'myapp.com/carrito/${widget.codigoCompartida}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copiarLink,
                      icon: Icon(
                        _linkCopiadoAlPortapapeles
                            ? Icons.check_circle
                            : Icons.content_copy,
                        color: _linkCopiadoAlPortapapeles
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Información
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.amber.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este carrito es válido por 7 días. Otros usuarios pueden recuperar este carrito usando el código o link.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onClose?.call();
                      },
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
