import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';

/// Category chip widget for category filtering
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? iconUrl;

  const CategoryChip({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.iconUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.md(context).left,
          vertical: DesignTokens.sm(context).top,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.colorScheme.primary
              : context.colorScheme.surface,
          border: Border.all(
            color: isSelected 
                ? context.colorScheme.primary
                : context.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null) ...[
              // TODO: Add category icon support
              Icon(
                Icons.category,
                size: DesignTokens.iconXs(context),
                color: isSelected 
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.onSurface,
              ),
              SizedBox(width: DesignTokens.xs(context).width),
            ],
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: isSelected 
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}