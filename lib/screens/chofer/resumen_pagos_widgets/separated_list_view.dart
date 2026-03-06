import 'package:flutter/material.dart';

/// Widget para ListView.separated con elementos y divisor
class SeparatedListView extends StatelessWidget {
  final List<dynamic> items;
  final IndexedWidgetBuilder itemBuilder;
  final WidgetBuilder separatorBuilder;
  final bool shrinkWrap;
  final ScrollPhysics physics;
  final EdgeInsets? padding;

  const SeparatedListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: items.length,
      separatorBuilder: (context, index) => separatorBuilder(context),
      itemBuilder: (context, index) => itemBuilder(context, index),
    );
  }
}
