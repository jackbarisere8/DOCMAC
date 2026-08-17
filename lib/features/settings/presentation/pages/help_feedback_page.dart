import 'package:flutter/material.dart';

import '../../../../core/ui/docmac_iconly.dart';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help and feedback')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _HelpRow(
              icon: DocmacIconlyLight.infoCircle,
              title: 'Help center',
              subtitle: 'Get help with Docmac',
              onTap: () => _notice(context, 'Help center is ready to connect.'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.edit,
              title: 'Send feedback',
              subtitle: 'Report a problem or share an idea',
              onTap: () => _showFeedbackSheet(context),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.document,
              title: 'Terms and privacy',
              onTap: () =>
                  _notice(context, 'Terms and privacy are ready to review.'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.danger,
              title: 'Safety reports',
              onTap: () => _notice(context, 'Safety reports will appear here.'),
            ),
            _HelpRow(
              icon: DocmacIconlyLight.infoCircle,
              title: 'App info',
              subtitle: 'Docmac 1.0.0',
              onTap: () => _notice(context, 'Docmac 1.0.0'),
            ),
          ],
        ),
      );

  static void _showFeedbackSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Send feedback',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 6,
              autofocus: true,
              decoration:
                  const InputDecoration(hintText: 'Tell us what happened'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                _notice(
                    context,
                    controller.text.trim().isEmpty
                        ? 'Add a message before sending feedback.'
                        : 'Thanks — your feedback is ready to send.');
              },
              child: const Text('Send feedback'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  static void _notice(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 7),
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
        onTap: onTap,
      );
}
