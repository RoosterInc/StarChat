import 'package:flutter/material.dart';

/// Optimized list view widget following AGENTS.md performance patterns
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback? onLoadMore;
  final EdgeInsetsGeometry? padding;
  final SliverGridDelegate? gridDelegate;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const OptimizedListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.padding,
    this.gridDelegate,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (gridDelegate != null) {
      return GridView.builder(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        gridDelegate: gridDelegate!,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Load more when reaching near end
          if (onLoadMore != null && index >= itemCount - 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onLoadMore!();
            });
          }
          return itemBuilder(context, index);
        },
      );
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Load more when reaching near end
        if (onLoadMore != null && index >= itemCount - 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLoadMore!();
          });
        }
        return itemBuilder(context, index);
      },
    );
  }
}