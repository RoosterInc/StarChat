import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';

/// Dashboard stat card widget for displaying key metrics
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardStatCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: context.colorScheme.shadow.withOpacity(0.1),
      surfaceTintColor: context.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
        child: Padding(
          padding: DesignTokens.lg(context).all,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: DesignTokens.sm(context).all,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm(context)),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: DesignTokens.iconMd(context),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: DesignTokens.iconXs(context),
                      color: context.colorScheme.outline,
                    ),
                ],
              ),
              
              SizedBox(height: DesignTokens.md(context).height),
              
              Text(
                value,
                style: context.textTheme.headlineMedium?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: DesignTokens.xs(context).height),
              
              Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              if (subtitle != null) ...[
                SizedBox(height: DesignTokens.xs(context).height),
                Text(
                  subtitle!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}