import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatThemePage extends StatefulWidget {
  const ChatThemePage({super.key});

  @override
  State<ChatThemePage> createState() => _ChatThemePageState();
}

class _ChatThemePageState extends State<ChatThemePage> {
  int _selected = 0;

  static const _themes = [
    (Color(0xFF2A0C1B), Color(0xFFBE2C55)),
    (Color(0xFFF4F0E8), Color(0xFFBDEFC3)),
    (Color(0xFFF0EEE9), Color(0xFF15A66A)),
    (Color(0xFFF9EAF7), Color(0xFF6650DF)),
    (Color(0xFFECC8F5), Color(0xFF6246D8)),
    (Color(0xFFF4D7D2), Color(0xFFA54ACF)),
    (Color(0xFFFFD99A), Color(0xFFE76C50)),
    (Color(0xFFBCE5F4), Color(0xFF008F7D)),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Talk theme')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Themes', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _themes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemBuilder: (context, index) => _ThemePreview(
                background: _themes[index].$1,
                bubble: _themes[index].$2,
                selected: _selected == index,
                onTap: () => setState(() => _selected = index),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your talk color and wallpaper change together.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 26),
            Text('Customize', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Talk color'),
              onTap: () => context.push('/chat/color'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wallpaper_outlined),
              title: const Text('Wallpaper'),
              onTap: () => context.push('/chat/wallpaper'),
            ),
          ],
        ),
      );
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.background,
    required this.bubble,
    required this.selected,
    required this.onTap,
  });

  final Color background;
  final Color bubble;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).dividerColor,
              width: selected ? 3 : 1,
            ),
          ),
          padding: const EdgeInsets.all(9),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 38,
                  height: 17,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 42,
                  height: 18,
                  decoration: BoxDecoration(
                    color: bubble,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              if (selected)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                    child: Icon(Icons.check_rounded,
                        color: Theme.of(context).colorScheme.surface, size: 17),
                  ),
                ),
            ],
          ),
        ),
      );
}

class DisappearingMessagesPage extends StatefulWidget {
  const DisappearingMessagesPage({super.key});

  @override
  State<DisappearingMessagesPage> createState() =>
      _DisappearingMessagesPageState();
}

class _DisappearingMessagesPageState extends State<DisappearingMessagesPage> {
  String _timer = 'Off';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Disappearing messages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 132,
                  height: 92,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                CircleAvatar(
                  radius: 43,
                  backgroundColor: colors.primary,
                  child: Icon(Icons.timer_outlined,
                      size: 50, color: colors.onPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Make messages in this talk disappear',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            'For more privacy and storage, new messages disappear for everyone after the selected duration. Anyone in this talk can change this setting.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 22),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          Text('Message timer',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _timer,
            onChanged: (value) {
              if (value != null) {
                setState(() => _timer = value);
              }
            },
            child: Column(
              children: [
                for (final duration in const [
                  '24 hours',
                  '7 days',
                  '90 days',
                  'Off'
                ])
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(duration),
                    value: duration,
                    activeColor: colors.primary,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Update your default timer in Talk settings.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ChatColorPage extends StatefulWidget {
  const ChatColorPage({super.key});

  @override
  State<ChatColorPage> createState() => _ChatColorPageState();
}

class _ChatColorPageState extends State<ChatColorPage> {
  int _selected = 0;
  static const _colors = [
    Color(0xFFBE2C55),
    Color(0xFFFFE0EB),
    Color(0xFF6348DD),
    Color(0xFFE5DFFF),
    Color(0xFFAF4BDC),
    Color(0xFFF0DCF8),
    Color(0xFFE76E52),
    Color(0xFFFFE0D4),
    Color(0xFF008A82),
    Color(0xFFC8F0F0),
    Color(0xFF3069D7),
    Color(0xFFD2E6FB),
    Color(0xFF19517D),
    Color(0xFFD9E6EF),
    Color(0xFF3D513B),
    Color(0xFFE1EAE0),
    Color(0xFF7B1930),
    Color(0xFFFFCBD7),
    Color(0xFF353535),
    Color(0xFFD8D8D8),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Talk color')),
        body: GridView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: _colors.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 24,
            mainAxisSpacing: 28,
          ),
          itemBuilder: (context, index) => InkWell(
            onTap: () => setState(() => _selected = index),
            borderRadius: BorderRadius.circular(999),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colors[index],
                border: _selected == index
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3)
                    : null,
              ),
              child: _selected == index
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(context).colorScheme.onSurface)
                  : null,
            ),
          ),
        ),
      );
}

class WallpaperPage extends StatefulWidget {
  const WallpaperPage({super.key});

  @override
  State<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
  int _selected = 0;
  static const _wallpapers = [
    Color(0xFF2A0C1B),
    Color(0xFFD4B9F8),
    Color(0xFFF3A8D1),
    Color(0xFFF5B8B3),
    Color(0xFFD8C4E7),
    Color(0xFF8E78E7),
    Color(0xFFFFA44C),
    Color(0xFFF8BD67),
    Color(0xFFF0ABDD),
    Color(0xFF74C779),
    Color(0xFF6BB7ED),
    Color(0xFFB7DB99),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Wallpaper')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.colorize_outlined),
              title: const Text('Set a color'),
              onTap: () {},
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wallpapers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: .58,
              ),
              itemBuilder: (context, index) => InkWell(
                onTap: () => setState(() => _selected = index),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: _wallpapers[index],
                    borderRadius: BorderRadius.circular(18),
                    border: _selected == index
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: _selected == index
                      ? Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 12,
                              child: Icon(Icons.check_rounded,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
}
