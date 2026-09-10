import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ئامێرەکان (${appliances.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (appliances.isNotEmpty)
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, color: Color(0xFF0F172A), size: 19),
                label: const Text('زیادکردن'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              errorMessage!,
              style: TextStyle(color: AppColors.negativeFor(context)),
            ),
          )
        else if (appliances.isEmpty)
          _EmptyApplianceGuide(onAdd: onAdd)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = grid.applianceColumns;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final appliance in appliances)
                    SizedBox(
                      width: cardWidth,
                      child: RepaintBoundary(
                        child: ApplianceCard(
                          key: ValueKey(appliance.id),
                          appliance: appliance,
                          monthlyCost: applianceCosts[appliance.id] ?? 0,
                          onToggle: () => onToggle(appliance),
                          onEdit: () => onEdit(appliance),
                          onLongPress: () => onDelete(appliance),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _EmptyApplianceGuide extends StatelessWidget {
  const _EmptyApplianceGuide({required this.onAdd});

  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.electrical_services_outlined,
              size: 32,
              color: Color(0xFF0F172A),
            ),
            const SizedBox(height: 14),
            Text(
              'یەکەم ئامێرت زیاد بکە',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'ناو، توانا و ماوەی بەکارهێنان بنووسە تا خەمڵاندنی تێچوو ببینیت.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: Color(0xFF0F172A)),
              label: const Text('زیادکردنی ئامێر'),
            ),
          ],
        ),
      ),
    );
  }
}
