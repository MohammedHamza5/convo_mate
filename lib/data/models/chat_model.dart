import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatModel extends Equatable {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isLastMessageSeen;
  final bool isLastMessageDelivered;
  final String lastMessageSenderId;
  final int unreadCount;  // عدد الرسائل غير المقروءة للمستخدم الحالي
  final String otherUserName;
  final String? otherUserImage;
  final bool isOnline;
  final String otherUserId; // معرف المستخدم الآخر

  const ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isLastMessageSeen,
    required this.isLastMessageDelivered,
    required this.lastMessageSenderId,
    required this.unreadCount,
    required this.otherUserName,
    this.otherUserImage,
    required this.isOnline,
    required this.otherUserId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, String chatId) {
    // الحصول على المستخدم الحالي
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // استخراج عدد الرسائل غير المقروءة الخاص بالمستخدم الحالي
    // إذا لم يكن موجوداً، نستخدم الحقل العادي unreadCount
    final String unreadCountField = 'unreadCount_$currentUserId';
    final int userUnreadCount = json[unreadCountField] ?? json['unreadCount'] ?? 0;
    
    return ChatModel(
      chatId: chatId,
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: (json['lastMessageTime'] is Timestamp)
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : (json['lastMessageTime'] is String && json['lastMessageTime'].isNotEmpty
          ? DateTime.parse(json['lastMessageTime'])
          : DateTime.now()),
      isLastMessageSeen: json['isLastMessageSeen'] ?? false,
      isLastMessageDelivered: json['isLastMessageDelivered'] ?? false,
      lastMessageSenderId: json['lastMessageSenderId'] ?? '',
      unreadCount: userUnreadCount,
      otherUserName: json['otherUserName'] ?? '',
      otherUserImage: json['otherUserImage'],
      isOnline: json['isOnline'] ?? false,
      otherUserId: json['otherUserId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'isLastMessageSeen': isLastMessageSeen,
      'isLastMessageDelivered': isLastMessageDelivered,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'otherUserName': otherUserName,
      'otherUserImage': otherUserImage,
      'isOnline': isOnline,
      'otherUserId': otherUserId,
    };
  }

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isLastMessageSeen,
    bool? isLastMessageDelivered,
    String? lastMessageSenderId,
    int? unreadCount,
    String? otherUserName,
    String? otherUserImage,
    bool? isOnline,
    String? otherUserId,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isLastMessageSeen: isLastMessageSeen ?? this.isLastMessageSeen,
      isLastMessageDelivered: isLastMessageDelivered ?? this.isLastMessageDelivered,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserImage: otherUserImage ?? this.otherUserImage,
      isOnline: isOnline ?? this.isOnline,
      otherUserId: otherUserId ?? this.otherUserId,
    );
  }

  @override
  List<Object?> get props => [
    chatId,
    participants,
    lastMessage,
    lastMessageTime,
    isLastMessageSeen,
    isLastMessageDelivered,
    lastMessageSenderId,
    unreadCount,
    otherUserName,
    otherUserImage,
    isOnline,
    otherUserId,
  ];
}