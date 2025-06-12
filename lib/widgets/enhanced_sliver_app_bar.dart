import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/enhanced_planet_house_controller.dart';
import '../widgets/enhanced_planet_house_widgets.dart';
import 'simple_dynamic_tabs.dart';
import '../controllers/master_data_controller.dart';

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
      expandedHeight: 200,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.all_inclusive, color: iconColor, size: 20),
                          const SizedBox(width: 8),
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final controller = Get.find<EnhancedPlanetHouseController>();
                  final data = Get.find<MasterDataController>();
                  final selected = data.rashiOptions.firstWhereOrNull(
                      (r) => r.rashiId == controller.currentRashiId);
                  return DropdownButton<RashiOption>(
                    value: selected,
                    underline: const SizedBox(),
                    items: data.rashiOptions
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text('${r.symbol} ${r.name}'),
                            ))
                        .toList(),
                    onChanged: (r) => controller.selectRashi(r?.rashiId ?? 'r1'),
                  );
                }),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Current Planetary Positions',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              const EnhancedPlanetHouseList(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
