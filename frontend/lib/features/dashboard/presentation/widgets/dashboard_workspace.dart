import 'package:flutter/material.dart';

import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/settings/meter_cycle_storage.dart';
import '../../../../core/widgets/app_button.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);

class DashboardSectionHeading extends StatelessWidget {
  const DashboardSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: _muted, height: 1.6)),
        ],
      ),
    );
  }
}

class DashboardToolList extends StatelessWidget {
  const DashboardToolList({
    super.key,
    required this.onEnergyTap,
    required this.onElectricalTap,
    required this.onBudgetTap,
    required this.onOutageTap,
  });

  final VoidCallback onEnergyTap;
  final VoidCallback onElectricalTap;
  final VoidCallback onBudgetTap;
  final VoidCallback onOutageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardSectionHeading(
          title: 'ئامرازەکان',
          subtitle: 'هەژمارکردن، بەدجەت و تۆمارکردنی قەطعبوون.',
        ),
        DashboardActionRow(
          icon: Icons.calculate_outlined,
          title: 'ژمێریاری وزە و تێچوو',
          subtitle: 'kWh، وات و کات، یان خوێندنەوەی کنتۆر',
          onTap: onEnergyTap,
        ),
        const Divider(height: 1, color: _line),
        DashboardActionRow(
          icon: Icons.electrical_services_outlined,
          title: 'ژمێریاری کارەبا',
          subtitle: 'هەژمارکردنی وات، ڤۆڵتەج و ئەمپێر',
          onTap: onElectricalTap,
        ),
        const Divider(height: 1, color: _line),
        DashboardActionRow(
          icon: Icons.savings_outlined,
          title: 'بەدجەتی مانگانە',
          subtitle: 'دیاریکردنی سنووری تێچووی ماڵ',
          onTap: onBudgetTap,
        ),
        const Divider(height: 1, color: _line),
        DashboardActionRow(
          icon: Icons.power_outlined,
          title: 'تۆمارکردنی قەطعبوون',
          subtitle: 'دەستپێکردن، وەستاندن یان تۆماری دەستی',
          onTap: onOutageTap,
        ),
      ],
    );
  }
}

class DashboardActionRow extends StatelessWidget {
  const DashboardActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      leading: Icon(icon, color: _ink, size: 23),
      title: Text(
        title,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          subtitle,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left,
        color: _ink,
        size: 20,
        textDirection: TextDirection.ltr,
      ),
      onTap: onTap,
    );
  }
}

class DashboardRecordsSection extends StatelessWidget {
  const DashboardRecordsSection({
    super.key,
    required this.history,
    required this.onOutageLogTap,
    required this.onMeterTap,
  });

  final Future<List<MeterCycleRecord>> history;
  final VoidCallback onOutageLogTap;
  final VoidCallback onMeterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardSectionHeading(
          title: 'تۆمارەکان',
          subtitle: 'خوێندنەوە پاشەکەوتکراوەکانی کنتۆر و مێژووی قەطعبوون.',
        ),
        DashboardActionRow(
          icon: Icons.history_outlined,
          title: 'تۆماری قەطعبوون',
          subtitle: 'کات و ماوەی قەطعبوونە تۆمارکراوەکان',
          onTap: onOutageLogTap,
        ),
        const Divider(height: 32, color: _line),
        Row(
          children: [
            const Expanded(
              child: Text(
                'خولەکانی کنتۆر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            AppButton(
              label: 'تۆماری نوێ',
              icon: Icons.add,
              variant: AppButtonVariant.outline,
              onPressed: onMeterTap,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MeterCycleRecord>>(
          future: history,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _ink)),
              );
            }
            final records = snapshot.data ?? const <MeterCycleRecord>[];
            if (records.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: _ink,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'هێشتا خوێندنەوەیەک پاشەکەوت نەکراوە.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ژمارەی پێشوو و ئێستای کنتۆر بنووسە بۆ تۆمارکردنی خولێک.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, height: 1.6),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final record in records) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${record.usageKwh.toStringAsFixed(2)} kWh',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              formatIqd(record.costIqd),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${record.createdAt.year}/${record.createdAt.month}/${record.createdAt.day} • ${record.days} ڕۆژ • ${record.profileTitle}',
                          style: const TextStyle(color: _muted, height: 1.5),
                        ),
                        Text(
                          '${record.fromReadingKwh} → ${record.toReadingKwh} kWh',
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _line),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
