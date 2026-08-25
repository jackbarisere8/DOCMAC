import 'package:flutter/material.dart';

import '../../../../shared/widgets/docmac_mark.dart';

class TalkPage extends StatefulWidget {
  const TalkPage({super.key});

  @override
  State<TalkPage> createState() => _TalkPageState();
}

class _TalkPageState extends State<TalkPage> {
  final _messageController = TextEditingController();
  _Thread? _openThread;
  final List<_Message> _messages = [
    const _Message(
        'Hey Jack, are we still on for the walk later?', false, '6:18 PM'),
    const _Message(
        'Definitely. I found a quieter route by the water.', true, '6:20 PM'),
    const _Message('Perfect. I will bring the coffee.', false, '6:21 PM'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text, true, 'Now'));
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _openThread == null
        ? _Inbox(onOpen: (thread) => setState(() => _openThread = thread))
        : _Conversation(
            thread: _openThread!,
            messages: _messages,
            controller: _messageController,
            onBack: () => setState(() => _openThread = null),
            onSend: _sendMessage,
          );
  }
}

class _Inbox extends StatelessWidget {
  const _Inbox({required this.onOpen});

  final ValueChanged<_Thread> onOpen;

  @override
  Widget build(BuildContext context) {
    const threads = [
      _Thread('Jack Wilson', 'J', 'I found a quieter route by the water.',
          '6:21 PM', 2, true),
      _Thread('Weekend crew', 'W', 'Nora: What time are we meeting?', '5:08 PM',
          0, false, true),
      _Thread(
          'Emma Clarke', 'E', 'Sent you a new moment', 'Yesterday', 0, true),
      _Thread('Design circle', 'D', 'David: The prototype is ready.',
          'Yesterday', 4, false, true),
      _Thread('Tobi Adeyemi', 'T', 'Wave back to begin a conversation', 'Mon',
          0, false),
    ];

    return ColoredBox(
      color: const Color(0xFFF5F6F1),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          children: [
            Row(
              children: [
                const DocmacMark(size: 44),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Talk',
                          style: TextStyle(
                              color: Color(0xFF132827),
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8)),
                      SizedBox(height: 1),
                      Text('Messages that matter',
                          style: TextStyle(
                              color: Color(0xFF61716E), fontSize: 11.5)),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF176B5D),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _TalkSearch(),
            const SizedBox(height: 18),
            const _Filters(),
            const SizedBox(height: 28),
            const Row(
              children: [
                Text('Inbox',
                    style: TextStyle(
                        color: Color(0xFF132827),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4)),
                Spacer(),
                Text('5 conversations',
                    style: TextStyle(color: Color(0xFF71807C), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDE5DF)),
              ),
              child: Column(
                children: List.generate(threads.length, (index) {
                  return Column(
                    children: [
                      _ThreadTile(thread: threads[index], onTap: onOpen),
                      if (index != threads.length - 1)
                        const Divider(
                            height: 1, indent: 74, color: Color(0xFFE3E9E4)),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 26),
            const _SignalNote(),
          ],
        ),
      ),
    );
  }
}

class _TalkSearch extends StatelessWidget {
  const _TalkSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE5DF)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: Color(0xFF176B5D)),
          SizedBox(width: 12),
          Text('Search messages',
              style: TextStyle(color: Color(0xFF798783), fontSize: 13)),
          Spacer(),
          Icon(Icons.tune_rounded, color: Color(0xFF798783), size: 19),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _Filter(label: 'All talks', active: true),
          SizedBox(width: 8),
          _Filter(label: 'Unread', count: 6),
          SizedBox(width: 8),
          _Filter(label: 'Circles'),
          SizedBox(width: 8),
          _Filter(label: 'Saved'),
        ],
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label, this.active = false, this.count});

  final String label;
  final bool active;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF176B5D) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: active ? null : Border.all(color: const Color(0xFFDDE5DF)),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF50615C),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Colors.white : const Color(0xFFB7F2D1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: Color(0xFF176B5D),
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final _Thread thread;
  final ValueChanged<_Thread> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(thread),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: thread.isGroup
                    ? const Color(0xFFD7E9E1)
                    : const Color(0xFFB7F2D1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: thread.isGroup
                  ? const Icon(Icons.grid_view_rounded,
                      color: Color(0xFF176B5D), size: 21)
                  : Text(thread.initial,
                      style: const TextStyle(
                          color: Color(0xFF176B5D),
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread.name,
                      style: const TextStyle(
                          color: Color(0xFF132827),
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(thread.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF71807C), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(thread.time,
                    style: const TextStyle(
                        color: Color(0xFF89948F), fontSize: 10)),
                const SizedBox(height: 7),
                if (thread.unread > 0)
                  Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF176B5D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${thread.unread}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  )
                else if (thread.active)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3CCB7F),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalNote extends StatelessWidget {
  const _SignalNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F7EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF176B5D), size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text('Your talks are personal spaces. Take your time.',
                style: TextStyle(
                    color: Color(0xFF315950), fontSize: 11.5, height: 1.25)),
          ),
        ],
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.thread,
    required this.messages,
    required this.controller,
    required this.onBack,
    required this.onSend,
  });

  final _Thread thread;
  final List<_Message> messages;
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F6F1),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 20, 13),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Color(0xFF132827)),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7F2D1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(thread.initial,
                        style: const TextStyle(
                            color: Color(0xFF176B5D),
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(thread.name,
                            style: const TextStyle(
                                color: Color(0xFF132827),
                                fontWeight: FontWeight.w800)),
                        const Text('Active now',
                            style: TextStyle(
                                color: Color(0xFF3E9C70), fontSize: 10)),
                      ],
                    ),
                  ),
                  const _HeaderButton(icon: Icons.call_outlined),
                  const SizedBox(width: 8),
                  const _HeaderButton(icon: Icons.more_horiz_rounded),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                itemCount: messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 22),
                        child: Text('TODAY',
                            style: TextStyle(
                                color: Color(0xFF7C8A85),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                      ),
                    );
                  }
                  return _MessageBubble(message: messages[index - 1]);
                },
              ),
            ),
            _Composer(controller: controller, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF176B5D)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 285),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: message.mine ? const Color(0xFF176B5D) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.mine ? 16 : 4),
              bottomRight: Radius.circular(message.mine ? 4 : 16),
            ),
          ),
          child: Text(message.text,
              style: TextStyle(
                  color: message.mine ? Colors.white : const Color(0xFF243936),
                  fontSize: 13,
                  height: 1.28)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(message.time,
              style: const TextStyle(color: Color(0xFF89948F), fontSize: 9.5)),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF176B5D)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write a message',
                hintStyle:
                    const TextStyle(color: Color(0xFF87938F), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF0F4F0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Color(0xFF176B5D)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF176B5D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const _SignalSendMark(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalSendMark extends StatelessWidget {
  const _SignalSendMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SignalSendPainter());
  }
}

class _SignalSendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * .28, size.height * .67)
      ..lineTo(size.width * .72, size.height * .28)
      ..lineTo(size.width * .62, size.height * .70)
      ..lineTo(size.width * .45, size.height * .53)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Thread {
  const _Thread(
    this.name,
    this.initial,
    this.preview,
    this.time,
    this.unread,
    this.active, [
    this.isGroup = false,
  ]);

  final String name;
  final String initial;
  final String preview;
  final String time;
  final int unread;
  final bool active;
  final bool isGroup;
}

class _Message {
  const _Message(this.text, this.mine, this.time);

  final String text;
  final bool mine;
  final String time;
}
