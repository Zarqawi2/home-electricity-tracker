import 'package:flutter/material.dart';

class DashboardNavigation extends StatelessWidget {
  const DashboardNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _destinations = [
    (Icons.home_outlined, 'پوختە'),
    (Icons.electrical_services_outlined, 'ئامێرەکان'),
    (Icons.receipt_long_outlined, 'تۆمارەکان'),
    (Icons.tune_outlined, 'ئامرازەکان'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                children: List.generate(_destinations.length, (index) {
                  final selected = index == selectedIndex;
                  final destination = _destinations[index];
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      child: InkWell(
                        key: ValueKey('dashboard-tab-$index'),
                        onTap: () => onSelected(index),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 68),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFF8FAFC) : null,
                            border: Border(
                              top: BorderSide(
                                color: selected
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                destination.$1,
                                size: 22,
                                color: const Color(0xFF0F172A),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                destination.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF0F172A),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
