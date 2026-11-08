import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router/app_back.dart';
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
          onPressed: () => AppBack.to(context, fallback: '/me'),
          icon: const Icon(DocmacIconlyLight.arrowLeft),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          const _LocalFoundryPreviewNotice(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(DocmacIconlyLight.work, color: colors.onPrimary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Local preview',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  )),
                      const SizedBox(height: 3),
                      Text('Foundry is not connected to real creator data yet.',
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
          const Card(
            child: ListTile(
              leading: Icon(DocmacIconlyLight.chart),
              title: Text('Impact metrics are not available yet'),
              subtitle:
                  Text('Reach, responses, quality, and reading time are not '
                      'measured in this build.'),
            ),
          ),
          const SizedBox(height: 28),
          Text('Build with intention',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _FoundryItem(
            icon: DocmacIconlyLight.wallet,
            title: 'Earnings',
            subtitle: 'Rewards and your earning history',
            onTap: () => _showCreatorDetail(
              context,
              'Creator Earnings',
              'Rewards and earning history',
              'Earnings track direct community appreciations and reward allocations for verified perspectives.',
            ),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.chart,
            title: 'Analytics',
            subtitle: 'Understand reach, reading, and response quality',
            onTap: () => _showCreatorDetail(
              context,
              'Creator Analytics',
              'Reading and response quality',
              'Analytics reflect verified reader engagement, discussion depth, and qualitative resonance.',
            ),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.graph,
            title: 'Reach',
            subtitle: 'See how perspectives travel through Forge',
            onTap: () => _showCreatorDetail(
              context,
              'Signal Reach',
              'How perspectives travel',
              'Reach measures authentic cross-circle circulation and relay distribution.',
            ),
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
            onTap: () => _showCreatorDetail(
              context,
              'Audience Analytics',
              'People who return for your ideas',
              'Audience metrics track reader retention and signal distribution across your Relays and Drops.',
            ),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.wallet,
            title: 'Payouts',
            subtitle: 'Set up where your Forge Rewards go',
            onTap: () => _showCreatorDetail(
              context,
              'Creator Payouts',
              'Set up where your Forge Rewards go',
              'Docmac connects directly to your verified payout provider to disburse community rewards.',
            ),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.star,
            title: 'Achievements',
            subtitle: 'Milestones earned through meaningful contribution',
            onTap: () => _showCreatorDetail(
              context,
              'Creator Milestones',
              'Earned through meaningful contribution',
              'Milestones celebrate high-signal perspectives, thoughtful commentary, and steady curation.',
            ),
          ),
          _FoundryItem(
            icon: DocmacIconlyLight.activity,
            title: 'Insights',
            subtitle: 'Patterns that can make your next idea stronger',
            onTap: () => _showCreatorDetail(
              context,
              'Signal Insights',
              'Patterns that make your ideas stronger',
              'Insights distill conversation trends, highlight popular themes, and help guide your writing.',
            ),
          ),
          const SizedBox(height: 14),
          Text('Creator path', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Creator levels are not available yet.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  static void _showCreatorDetail(
    BuildContext context,
    String title,
    String subtitle,
    String detail,
  ) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 16),
              const Text(
                'This is not available yet. Foundry is a local preview in '
                'this build and is not connected to real analytics, '
                'earnings, payouts, or audience data.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('Understood'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalFoundryPreviewNotice extends StatelessWidget {
  const _LocalFoundryPreviewNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Foundry is a local preview in this build. It does not yet '
              'measure reach, responses, earnings, payouts, or audience data.',
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundryItem extends StatelessWidget {
  const _FoundryItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        onTap: onTap,
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
      );
}
