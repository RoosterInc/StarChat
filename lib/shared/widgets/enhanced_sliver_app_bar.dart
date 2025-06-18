import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/enhanced_planet_house_controller.dart';
import 'enhanced_planet_house_widgets.dart';
import 'simple_dynamic_tabs.dart';
import '../../controllers/master_data_controller.dart';
import 'complete_enhanced_watchlist.dart';
import '../../core/design_system/modern_ui_system.dart';

class EnhancedSliverAppBar extends StatelessWidget {
  const EnhancedSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.primary.withOpacity(0.6);
    Get.put(EnhancedPlanetHouseController(), permanent: true);
    if (!Get.isRegistered<MasterDataController>()) {
      Get.put(MasterDataController(), permanent: true);
    }
    return SliverAppBar(
      pinned: true,
      expandedHeight: ResponsiveUtils.adaptiveValue(
        context,
        mobile: DesignTokens.xl(context) * 8,
        tablet: DesignTokens.xl(context) * 9,
        desktop: DesignTokens.xl(context) * 10,
      ),
      collapsedHeight: 0,
      toolbarHeight: 0,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Material(
          elevation: 1,
          color: colorScheme.surface,
          child: const SimpleDynamicTabs(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: DesignTokens.md(context).horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing(context, 12),
                        vertical: DesignTokens.sm(context),
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusLg(context)),
                        border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.all_inclusive, color: iconColor, size: 20),
                          SizedBox(width: DesignTokens.sm(context)),
                          Text('StarChat',
                              style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.refresh, color: iconColor),
                          onPressed: () =>
                              Get.find<EnhancedPlanetHouseController>()
                                  .forceRefreshData(),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings, color: iconColor),
                          onPressed: () => Get.toNamed('/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: DesignTokens.sm(context)),
              Padding(
                padding: DesignTokens.md(context).horizontal,
                child: Obx(() {
                  final controller = Get.find<EnhancedPlanetHouseController>();
                  final data = Get.find<MasterDataController>();
                  final selected = data.rashiOptions.firstWhereOrNull(
                      (r) => r.rashiId == controller.currentRashiId);
                  return DropdownButton<RashiOption>(
                    value: selected,
                    underline: const SizedBox(),
                    items: data.rashiOptions
                        .map((r) => DropdownMenuItem<RashiOption>(
                              value: r,
                              child: Text('${r.symbol} ${r.name}'),
                            ))
                        .toList(),
                    onChanged: (RashiOption? r) =>
                        controller.selectRashi(r?.rashiId ?? 'r1'),
                  );
                }),
              ),
              Padding(
                padding: DesignTokens.md(context).horizontal,
                child: const Text(
                  'Current Planetary Positions',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: DesignTokens.sm(context)),
              const Expanded(child: EnhancedPlanetHouseList()),
              SizedBox(height: DesignTokens.xs(context)),
            ],
          ),
        ),
      ),
    );
  }
}
