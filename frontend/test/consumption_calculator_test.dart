import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/domain/entities/appliance.dart';
import 'package:frontend/features/dashboard/domain/services/consumption_calculator.dart';

void main() {
  test('inactive appliances contribute no scheduled consumption', () {
    const appliance = Appliance(
      id: 'ac',
      name: 'AC',
      category: 'Climate Control',
      powerW: 1800,
      dailyUseHours: 8,
      isOn: false,
    );
    expect(appliance.dailyKwh, 0);
    expect(appliance.copyWith(isOn: true).dailyKwh, 14.4);
    expect(appliance.copyWith(isOn: true, powerW: -10).dailyKwh, 0);
    expect(
      appliance.copyWith(isOn: true, dailyUseHours: double.nan).dailyKwh,
      0,
    );
    expect(appliance.copyWith(isOn: true, dailyUseHours: 30).dailyKwh, 43.2);
  });

  test('calendar month length includes leap years', () {
    expect(daysInCalendarMonth(DateTime(2024, 2)), 29);
    expect(daysInCalendarMonth(DateTime(2025, 2)), 28);
    expect(daysInCalendarMonth(DateTime(2026, 1)), 31);
    expect(daysInCalendarMonth(DateTime(2026, 4)), 30);
  });

  test('proportional bill shares reconcile cents with stable tie breaking', () {
    final shares = allocateBillByUsage(
      usageById: {'c': 10, 'b': 10, 'a': 10, 'off': 0},
      totalCostIqd: 0.05,
    );
    expect(shares, {'a': 0.02, 'b': 0.02, 'c': 0.01, 'off': 0});
    expect(
      shares.values.fold<int>(0, (sum, value) => sum + (value * 100).round()),
      5,
    );
    expect(
      allocateBillByUsage(
        usageById: {'a': 10, 'b': 10, 'c': 10, 'off': 0},
        totalCostIqd: 0.05,
      ),
      shares,
    );
  });

  test('bill allocation excludes zero or invalid usage', () {
    expect(
      allocateBillByUsage(
        usageById: {'a': 100, 'b': 200, 'off': 0, 'invalid': double.nan},
        totalCostIqd: 100,
      ),
      {'a': 33.33, 'b': 66.67, 'off': 0, 'invalid': 0},
    );
    expect(allocateBillByUsage(usageById: {'off': 0}, totalCostIqd: 0), {
      'off': 0,
    });
  });
}
