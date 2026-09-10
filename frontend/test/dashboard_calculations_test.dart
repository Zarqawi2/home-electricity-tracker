import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/settings/electricity_tariff.dart';
import 'package:frontend/core/settings/electricity_tariff_storage.dart';
import 'package:frontend/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:frontend/features/dashboard/data/datasources/local_appliance_store.dart';
import 'package:frontend/features/dashboard/domain/entities/view_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> addAppliance(
    LocalApplianceStore store, {
    required String name,
    double power = 1000,
    double hours = 12,
    bool isOn = true,
  }) async {
    await store.createAppliance(
      name: name,
      category: 'Other',
      powerW: power,
      dailyUseHours: hours,
      isOn: isOn,
    );
  }

  test(
    'household tiers are applied once and off devices have no cost',
    () async {
      final store = LocalApplianceStore();
      await addAppliance(store, name: 'A');
      await addAppliance(store, name: 'B');
      await addAppliance(store, name: 'Off', power: 5000, isOn: false);

      final data = await DashboardRemoteDataSource(store).fetchDashboard(
        date: DateTime(2024, 2, 29),
        mode: DashboardViewMode.monthly,
      );
      expect(data.summary.dailyKwh, 24);
      expect(data.summary.monthlyEstimateKwh, 696);
      expect(data.summary.monthlyCostIqd, 60768);
      expect(data.lineChart.points.last.y, data.summary.monthlyEstimateKwh);
      expect(
        data.appliances
            .singleWhere((item) => item.name == 'Off')
            .monthlyCostIqd,
        0,
      );
      expect(
        data.appliances.singleWhere((item) => item.name == 'A').monthlyCostIqd,
        30384,
      );
      expect(
        data.appliances.fold<double>(
          0,
          (sum, item) => sum + item.monthlyCostIqd!,
        ),
        data.summary.monthlyCostIqd,
      );
      expect(data.pieChart.length, 2);
      expect(data.pieChart.fold<double>(0, (sum, item) => sum + item.pct), 100);
      expect(
        data.lineChart.points.singleWhere((point) => point.x == '2024-01').y,
        744,
      );
    },
  );

  test(
    'one outage is averaged over every calendar day, not outage rows',
    () async {
      final store = LocalApplianceStore();
      await addAppliance(store, name: 'A');
      await store.setOutageMinutesForDate(
        date: DateTime(2024, 2, 15),
        outageMinutes: 720,
      );
      final data = await DashboardRemoteDataSource(store).fetchDashboard(
        date: DateTime(2024, 2, 29),
        mode: DashboardViewMode.monthly,
      );
      // 29 scheduled days less half a day: 12 * 28.5 = 342 kWh.
      expect(data.summary.monthlyEstimateKwh, 342);
      expect(data.lineChart.points.last.y, 342);
      expect(data.summary.monthlyCostIqd, 24624);
    },
  );

  test(
    'empty and disabled-only households have zero bill and pie shares',
    () async {
      final store = LocalApplianceStore();
      await addAppliance(store, name: 'Off', isOn: false);
      final source = DashboardRemoteDataSource(store);
      final data = await source.fetchDashboard(
        date: DateTime(2026, 1, 31),
        mode: DashboardViewMode.daily,
      );
      expect(data.summary.monthlyEstimateKwh, 0);
      expect(data.summary.monthlyCostIqd, 0);
      expect(data.appliances.single.monthlyCostIqd, 0);
      expect(data.pieChart, isEmpty);
      expect(data.lineChart.points.every((point) => point.y == 0), isTrue);
    },
  );

  test(
    'outage retains start schedule and tariff across edits and restart',
    () async {
      var now = DateTime(2024, 2, 28, 23, 30);
      final store = LocalApplianceStore(now: () => now);
      await addAppliance(store, name: 'A', power: 3000);
      await store.startOutageTracking();
      final id = (await store.listAppliances()).single['id'] as String;
      await store.updateAppliance(
        id: id,
        name: 'A changed',
        category: 'Other',
        powerW: 100,
        dailyUseHours: 1,
        isOn: false,
      );
      await saveElectricityTariffProfile(
        ElectricityTariffCatalog.commercial.id,
      );
      now = DateTime(2024, 2, 29, 1, 30);
      final restartedStore = LocalApplianceStore(now: () => now);
      expect(
        await restartedStore.stopOutageTracking(
          tariffProfileId: ElectricityTariffCatalog.commercial.id,
        ),
        120,
      );
      expect(
        await restartedStore.getOutageMinutesForDate(DateTime(2024, 2, 28)),
        30,
      );
      expect(
        await restartedStore.getOutageMinutesForDate(DateTime(2024, 2, 29)),
        90,
      );
      final log = (await restartedStore.listOutageLogs()).first;
      expect(log['type'], 'stop');
      // 3 kW * 12h/day spread across 24h => 1.5 kW average; two hours => 3 kWh.
      expect(log['active_power_watts'], 1500);
      expect(log['estimated_kwh_saved'], 3);
      // February's 1,044 kWh baseline falls in the 175 IQD marginal tier.
      expect(log['estimated_iqd_saved'], 525);
      expect(await restartedStore.isOutageTrackingActive(), isFalse);
      expect(await restartedStore.stopOutageTracking(), 0);
    },
  );

  test(
    'manual outage uses daily hours and supports signed corrections',
    () async {
      final store = LocalApplianceStore();
      await addAppliance(store, name: 'A', power: 2000, hours: 6);
      await store.setOutageMinutesForDate(
        date: DateTime(2024, 2, 20),
        outageMinutes: 720,
        logChange: true,
      );
      var log = (await store.listOutageLogs()).first;
      expect(log['estimated_kwh_saved'], 6);
      expect(log['estimated_iqd_saved'], 432);
      await store.setOutageMinutesForDate(
        date: DateTime(2024, 2, 20),
        outageMinutes: 0,
        logChange: true,
      );
      log = (await store.listOutageLogs()).first;
      expect(log['estimated_kwh_saved'], -6);
      expect(log['estimated_iqd_saved'], -432);
    },
  );
}
