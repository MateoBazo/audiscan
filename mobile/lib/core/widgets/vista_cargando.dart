import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer genérico para listas mientras cargan datos.
class VistaCargando extends StatelessWidget {
  final double alturaItem;
  final int cantidadItems;

  const VistaCargando({
    super.key,
    this.alturaItem = 80,
    this.cantidadItems = 6,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: cantidadItems,
        itemBuilder: (_, __) => Container(
          height: alturaItem,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
