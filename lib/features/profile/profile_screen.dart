import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/section_header.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockNoriGoData.user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'My page'),
          const SizedBox(height: 14),
          NoriCard(
            color: NoriGoColors.mint,
            borderColor: Colors.transparent,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: NoriGoColors.sea,
                  child: Text(
                    'EK',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.badge,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.currentCity,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NoriCard(
            child: Row(
              children: [
                const Icon(Icons.language, color: NoriGoColors.sea),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Korean language setting',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'English first, Korean helper phrases on',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: const [
              _StatCard(label: 'Saved plans', value: '12'),
              _StatCard(label: 'Saved places', value: '28'),
              _StatCard(label: 'Culture scans', value: '9'),
              _StatCard(label: 'Time saved', value: '1h 25m'),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Menu'),
          const SizedBox(height: 10),
          NoriCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(icon: Icons.route_outlined, label: 'My itineraries'),
                _MenuTile(icon: Icons.bookmark_outline, label: 'Saved places'),
                _MenuTile(icon: Icons.translate, label: 'Translation history'),
                _MenuTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Saved culture guides',
                ),
                _MenuTile(
                  icon: Icons.hourglass_bottom,
                  label: 'Wait-time help history',
                ),
                _MenuTile(icon: Icons.favorite_border, label: 'Interests'),
                _MenuTile(
                  icon: Icons.notifications_outlined,
                  label: 'Language & notifications',
                ),
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy & data',
                ),
                _MenuTile(icon: Icons.help_outline, label: 'Help center'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NoriCard(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.dashboard),
            child: Row(
              children: [
                const Icon(Icons.dashboard_outlined, color: NoriGoColors.sea),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Public organization dashboard',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return NoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: NoriGoColors.sea),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label will open when data is connected.')),
        );
      },
    );
  }
}
