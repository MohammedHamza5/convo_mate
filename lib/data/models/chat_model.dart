// lib/data/models/chat_model.dart
class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isLastMessageSeen;
  final String otherUserName;
  final String? otherUserImage;
  final int unreadCount; // عدد الرسائل غير المقروءة
  final bool isOnline; // حالة الاتصال
  final List<String>? sharedInterests; // الاهتمامات المشتركة

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isLastMessageSeen = false,
    required this.otherUserName,
    this.otherUserImage,
    this.unreadCount = 0,
    this.isOnline = false,
    this.sharedInterests,
  });

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'participants': participants,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime.toIso8601String(),
    'isLastMessageSeen': isLastMessageSeen,
    'otherUserName': otherUserName,
    'otherUserImage': otherUserImage,
    'unreadCount': unreadCount,
    'isOnline': isOnline,
    'sharedInterests': sharedInterests,
  };

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
    chatId: json['chatId'],
    participants: List<String>.from(json['participants']),
    lastMessage: json['lastMessage'],
    lastMessageTime: DateTime.parse(json['lastMessageTime']),
    isLastMessageSeen: json['isLastMessageSeen'],
    otherUserName: json['otherUserName'],
    otherUserImage: json['otherUserImage'],
    unreadCount: json['unreadCount'] ?? 0,
    isOnline: json['isOnline'] ?? false,
    sharedInterests: json['sharedInterests'] != null
        ? List<String>.from(json['sharedInterests'])
        : null,
  );
}