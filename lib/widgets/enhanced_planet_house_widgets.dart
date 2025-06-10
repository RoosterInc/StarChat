import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/planet_house_models.dart';
import '../controllers/enhanced_planet_house_controller.dart';

class EnhancedPlanetHouseWidget extends StatelessWidget {
  final PlanetHouseData planetData;
  final double size;
  final VoidCallback? onTap;

  const EnhancedPlanetHouseWidget({
    super.key,
    required this.planetData,
    this.size = 52.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStrengthBar(context),
          const SizedBox(height: 6),
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              planetData.planetImageAsset,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Text(planetData.position.planet[0]),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            planetData.housePositionText,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(BuildContext context) {
    final strength = planetData.strengthRating / 10.0;
    return Container(
      width: size * 0.8,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.grey.shade300,
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: strength.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: planetData.strengthColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class EnhancedPlanetHouseList extends StatelessWidget {
  const EnhancedPlanetHouseList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedPlanetHouseController>();
    return Obx(() {
      if (controller.isLoading && !controller.hasData) {
        return const SizedBox(
            height: 80, child: Center(child: CircularProgressIndicator()));
      }
      if (controller.error.isNotEmpty && !controller.hasData) {
        return SizedBox(
          height: 80,
          child: Center(
            child: TextButton(
              onPressed: controller.forceRefreshData,
              child: const Text('Retry'),
            ),
          ),
        );
      }
      return SizedBox(
        // Provide enough vertical space for the planet widget to
        // avoid overflow errors when the text height varies slightly.
        height: 86,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.planetHouseData.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = controller.planetHouseData[index];
            return EnhancedPlanetHouseWidget(
              planetData: item,
              onTap: () => _showDetails(context, item),
            );
          },
        ),
      );
    });
  }

  void _showDetails(BuildContext context, PlanetHouseData data) {
    showDialog(
      context: context,
      builder: (_) => EnhancedPlanetDetailsDialog(planetData: data),
    );
  }
}

class EnhancedPlanetDetailsDialog extends StatelessWidget {
  final PlanetHouseData planetData;
  const EnhancedPlanetDetailsDialog({super.key, required this.planetData});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(planetData.position.planet),
      content: planetData.interpretation == null
          ? const Text('No interpretation available')
          : SingleChildScrollView(
              child: Text(planetData.interpretation!.summary),
            ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }
}
