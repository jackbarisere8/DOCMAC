import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// The Foundry is the private creator view of Forge: impact, audience, and
/// rewards without turning the relationship product into an engagement casino.
class FoundryPage extends StatelessWidget {
  const FoundryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Foundry'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(DocmacIconlyLight.arrowLeft),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(DocmacIconlyLight.work,
                      color: colors.onPrimary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explorer',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w800,
                              )),
                      const SizedBox(height: 3),
                      Text('Your ideas are beginning to find their people.',
                          style: TextStyle(
                              color: colors.onPrimary.withValues(alpha: .8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Your impact', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(child: _Metric(value: '1.2k', label: 'Reach')),
            SizedBox(width: 10),
            Expanded(child: _Metric(value: '84', label: 'Meaningful responses')),
          ]),
          const SizedBox(height: 10),
          const Row(children: [
            Expanded(child: _Metric(value: '72%', label: 'Quality score')),
            SizedBox(width: 10),
            Expanded(child: _Metric(value: '18m', label: 'Reading time')),
          ]),
          const SizedBox(height: 28),
          Text('Build with intention',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _FoundryItem(
            icon: DocmacIconlyLight.wallet,
            title: 'Earnings',
            subtitle: 'Rewards and your earning history',
            onTap: () => _notice(context, 'Earnings will unlock when Forge Rewards is available.'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.chart,
            title: 'Analytics',
            subtitle: 'Understand reach, reading, and response quality',
            onTap: () => _notice(context, 'Analytics are preparing your first report.'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.graph,
            title: 'Reach',
            subtitle: 'See how perspectives travel through Forge',
            onTap: () => _notice(context, 'Reach is measured by real attention, not empty impressions.'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.document,
            title: 'Perspectives',
            subtitle: 'Drafts, published ideas, and resolutions',
            onTap: () => context.push('/forge'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.discovery,
            title: 'Relays',
            subtitle: 'Publish Drops and understand your audience',
            onTap: () => context.push('/relays'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.user,
            title: 'Audience',
            subtitle: 'People who return for your ideas',
            onTap: () => _notice(context, 'Audience insights are on their way.'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.wallet,
            title: 'Payouts',
            subtitle: 'Set up where your Forge Rewards go',
            onTap: () => _notice(context, 'Payouts require the Forge Rewards launch.'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.star,
            title: 'Achievements',
            subtitle: 'Milestones earned through meaningful contribution',
            onTap: () => _notice(context, 'Your achievements will appear here.'),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.activity,
            title: 'Insights',
            subtitle: 'Patterns that can make your next idea stronger',
            onTap: () => _notice(context, 'Insights will grow as you publish.'),
          ),
          const SizedBox(height: 14),
          Text('Creator path', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Explorer · Contributor · Builder · Creator · Mentor · Pioneer',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  static void _notice(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _FoundryItem extends StatelessWidget {
  const _FoundryItem({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
      );
}
