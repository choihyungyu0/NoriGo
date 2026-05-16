import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/section_header.dart';
import 'package:norigo/data/models/dashboard_metric.dart';
import 'package:norigo/data/repositories/mock_repositories.dart';

class PublicDashboardScreen extends StatelessWidget {
  const PublicDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = MockDashboardRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Public dashboard')),
      body: SafeArea(
        child: FutureBuilder<List<DashboardMetric>>(
          future: repository.getAggregateMetrics(),
          builder: (context, snapshot) {
            final metrics = snapshot.data ?? const <DashboardMetric>[];
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SectionHeader(
                  title: 'Tourism dispersion dashboard',
                  subtitle:
                      'Aggregate-only structure for public organizations. No individual routes are exposed.',
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (metrics.isEmpty &&
                    snapshot.connectionState != ConnectionState.waiting)
                  const NoriCard(
                    child: Text(
                      'Dashboard data is unavailable. Showing no private traveler data.',
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 820 ? 3 : 1;
                      return GridView.builder(
                        itemCount: metrics.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: crossAxisCount == 1 ? 2.75 : 1.65,
                        ),
                        itemBuilder: (context, index) =>
                            _MetricCard(metrics[index]),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                const _DashboardSection(
                  title: 'Top crowded zones',
                  rows: [
                    _ZoneRow(name: 'Anguk cafe street', percent: 0.86),
                    _ZoneRow(name: 'Gyeongbokgung west gate', percent: 0.78),
                    _ZoneRow(name: 'Myeongdong main road', percent: 0.71),
                  ],
                ),
                const SizedBox(height: 14),
                const _DashboardSection(
                  title: 'Recommended dispersion zones',
                  rows: [
                    _ZoneRow(name: 'Seochon book alleys', percent: 0.62),
                    _ZoneRow(name: 'Mangwon dessert lanes', percent: 0.58),
                    _ZoneRow(name: 'Seongsu side streets', percent: 0.51),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return NoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(metric.value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          InfoPill(
            label: metric.trend,
            icon: Icons.trending_up,
            color: NoriGoColors.coral,
          ),
          const SizedBox(height: 8),
          Text(
            metric.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.rows});

  final String title;
  final List<_ZoneRow> rows;

  @override
  Widget build(BuildContext context) {
    return NoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.name, required this.percent});

  final String name;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text('${(percent * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: NoriGoColors.line,
              color: percent > 0.7 ? NoriGoColors.danger : NoriGoColors.sea,
            ),
          ),
        ],
      ),
    );
  }
}
