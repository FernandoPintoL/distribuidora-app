import 'package:flutter/material.dart';

class SelectSearch<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) displayString;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? decoration;

  const SelectSearch({
    super.key,
    required this.label,
    required this.items,
    this.value,
    required this.displayString,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
  });

  @override
  State<SelectSearch<T>> createState() => _SelectSearchState<T>();
}

class _SelectSearchState<T> extends State<SelectSearch<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<T> _filteredItems = [];
  bool _isDropdownOpen = false;
  bool _isActive = true; // Bandera para controlar si el widget está activo

  // Método separado para el listener del focusNode
  void _focusListener() {
    if (_focusNode.hasFocus) {
      _showDropdown();
    } else {
      _hideDropdown();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateControllerText();
    _filteredItems = widget.items;

    // Agregar el listener como método separado para poder eliminarlo en dispose
    _focusNode.addListener(_focusListener);
  }

  @override
  void didUpdateWidget(SelectSearch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.items != widget.items) {
      // Usar addPostFrameCallback para evitar setState() durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateControllerText();
          _filterItems(_controller.text);
        }
      });
    }
  }

  @override
  void dispose() {
    // Marcar el widget como inactivo para evitar actualizaciones de estado
    _isActive = false;
    
    // Primero eliminar el overlay para evitar actualizaciones de estado
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    
    // Eliminar el listener antes de disponer del focusNode
    _focusNode.removeListener(_focusListener);
    
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateControllerText() {
    if (widget.value != null) {
      _controller.text = widget.displayString(widget.value as T);
    } else {
      _controller.text = '';
    }
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      _filteredItems = widget.items;
    } else {
      _filteredItems = widget.items.where((item) {
        return widget
            .displayString(item)
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    }
    _updateOverlay();
  }

  void _showDropdown() {
    // Verificar si el widget está activo y el overlay no existe
    if (!_isActive || _overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    // Verificar nuevamente si el widget sigue activo antes de insertar el overlay
    if (_isActive) {
      Overlay.of(context).insert(_overlayEntry!);
      if (mounted) {
        setState(() => _isDropdownOpen = true);
      }
    }
  }

  void _hideDropdown() {
    // Remover el overlay si existe
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    // Actualizar el estado solo si el widget sigue montado y activo
    if (_isActive && mounted) {
      setState(() => _isDropdownOpen = false);
    }
  }

  void _updateOverlay() {
    // Solo actualizar el overlay si el widget sigue montado, activo y el overlay existe
    if (_isActive && mounted && _overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Ancho del TextField
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56), // Altura aproximada del TextField
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: _filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No se encontraron resultados',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected =
                            widget.value != null &&
                            widget.displayString(widget.value as T) ==
                                widget.displayString(item);

                        return InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            _controller.text = widget.displayString(item);
                            _focusNode.unfocus();
                            _hideDropdown();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.displayString(item),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = (widget.decoration ?? const InputDecoration())
        .copyWith(
          labelText: widget.label,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon:
              widget.suffixIcon ??
              Icon(
                _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          border: const OutlineInputBorder(),
        );

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: effectiveDecoration,
        validator: widget.validator != null
            ? (value) => widget.validator!(widget.value)
            : null,
        onChanged: _filterItems,
        onTap: () {
          if (!_isDropdownOpen) {
            _showDropdown();
          }
        },
        onFieldSubmitted: (_) {
          _hideDropdown();
        },
      ),
    );
  }
}
