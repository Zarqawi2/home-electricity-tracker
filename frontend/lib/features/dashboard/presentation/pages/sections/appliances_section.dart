import 'package:flutter/material.dart';

import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/appliance.dart';
import '../../widgets/appliance_card.dart';
import 'grid_calculator.dart';

class AppliancesSection extends StatelessWidget {
  const AppliancesSection({
    super.key,
    required this.grid,
    required this.appliances,
    required this.applianceCosts,
    required this.spacing,
    required this.isLoading,
    this.errorMessage,
    required this.onAdd,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final GridCalculator grid;
  final List<Appliance> appliances;
  final Map<String, double> applianceCosts;
  final double spacing;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onAdd;
  final Future<void> Function(Appliance) onToggle;
  final Future<void> Function(Appliance) onEdit;
  final Future<void> Function(Appliance) onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'ئامێرەکان',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ئامێرەکان بەڕێوەبەرە و خەرجی مانگانەیان پێشبینی بکە.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AppButton(
                variant: AppButtonVariant.outline,
                label: 'ئامێر زیاد بکە',
                icon: Icons.add,
                onPressed: () => onAdd(),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                borderRadius: 9,
                fontSize: 12,
                iconSize: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (appliances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                      children: [
                  const Icon(Icons.info_outline, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هێشتا هیچ ئامێرێک زیاد نەکراوە. دوگمەی "ئامێر زیاد بکە" دابگرە بۆ دەستپێکردن.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final appliance in appliances)
                  SizedBox(
                    width: grid.widthForApplianceColumns(grid.applianceColumns),
                    child: ApplianceCard(
                      appliance: appliance,
                      monthlyCost: applianceCosts[appliance.id] ?? 0,
                      onToggle: () => onToggle(appliance),
                      onEdit: () => onEdit(appliance),
                      onLongPress: () => onDelete(appliance),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
