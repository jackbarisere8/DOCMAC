/// Inbox thread model for the Talk tab.
///
/// [TalkThread] is the UI-facing projection of a Firestore `chats/{chatId}`
/// document combined with its latest message preview. The curated fallback
/// list below is shown when Firebase is unavailable or the user is signed
/// out, so the inbox still renders a useful preview state.
class TalkThread {
  const TalkThread({
    required this.id,
    required this.chatId,
    required this.name,
    required this.initial,
    required this.preview,
    required this.time,
    this.unread = 0,
    this.isOnline = false,
    this.hasNewActivity = false,
    this.isGroup = false,
    this.isSaved = false,
  });

  /// Stable key used for SharedPreferences pin/archive/mute sets.
  /// Never derive prefs keys from [name] so renames do not lose state.
  final String id;
  final String chatId;
  final String name;
  final String initial;
  final String preview;
  final String time;
  final int unread;
  final bool isOnline;
  final bool hasNewActivity;
  final bool isGroup;
  final bool isSaved;

  TalkThread copyWith({
    String? preview,
    String? time,
    int? unread,
    bool? isOnline,
    bool? hasNewActivity,
  }) {
    return TalkThread(
      id: id,
      chatId: chatId,
      name: name,
      initial: initial,
      preview: preview ?? this.preview,
      time: time ?? this.time,
      unread: unread ?? this.unread,
      isOnline: isOnline ?? this.isOnline,
      hasNewActivity: hasNewActivity ?? this.hasNewActivity,
      isGroup: isGroup,
      isSaved: isSaved,
    );
  }
}

/// Preview-only fallback when Firestore is unreachable or signed out.
/// Matches the previous hardcoded inbox so existing tests and screenshots
/// stay stable while the real stream is being adopted.
const curatedTalkThreads = <TalkThread>[
  TalkThread(
    id: 'jack',
    chatId: 'jack',
    name: 'Jack Wilson',
    initial: 'J',
    preview: 'I found a quieter route by the water.',
    time: '6:21 PM',
    unread: 2,
    isOnline: true,
  ),
  TalkThread(
    id: 'weekend-crew',
    chatId: 'weekend-crew',
    name: 'Weekend crew',
    initial: 'W',
    preview: 'Nora: What time are we meeting?',
    time: '5:08 PM',
    isGroup: true,
  ),
  TalkThread(
    id: 'emma',
    chatId: 'emma',
    name: 'Emma Clarke',
    initial: 'E',
    preview: 'Sent you a new moment',
    time: 'Yesterday',
    hasNewActivity: true,
    isSaved: true,
  ),
  TalkThread(
    id: 'design-circle',
    chatId: 'design-circle',
    name: 'Design circle',
    initial: 'D',
    preview: 'David: The prototype is ready.',
    time: 'Yesterday',
    unread: 4,
    isGroup: true,
  ),
  TalkThread(
    id: 'tobi',
    chatId: 'tobi',
    name: 'Tobi Adeyemi',
    initial: 'T',
    preview: 'Wave back to begin a conversation',
    time: 'Mon',
  ),
];
