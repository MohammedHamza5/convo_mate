import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String messageId;
  final String senderId;
  final String? receiverId;
  final String message;
  final String? imageUrl;
  final String? audioUrl;
  final bool isSeen; // Deprecated, to be replaced by isRead
  final DateTime timestamp;
  final bool isDelivered;
  final bool isRead;
  final String? replyTo; // Field for reply message ID
  final bool isEdited; // Field to track if message was edited

  const MessageModel({
    required this.messageId,
    required this.senderId,
    this.receiverId,
    required this.message,
    this.imageUrl,
    this.audioUrl,
    required this.isSeen,
    required this.timestamp,
    this.isDelivered = false,
    this.isRead = false,
    this.replyTo,
    this.isEdited = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'],
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
      isSeen: data['isSeen'] ?? false,
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] is String && data['timestamp'].isNotEmpty
          ? DateTime.parse(data['timestamp'])
          : DateTime.now()),
      isDelivered: data['isDelivered'] ?? false,
      isRead: data['isRead'] ?? false,
      replyTo: data['replyTo'],
      isEdited: data['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'isSeen': isSeen,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDelivered': isDelivered,
      'isRead': isRead,
      'replyTo': replyTo,
      'isEdited': isEdited,
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? message,
    String? imageUrl,
    String? audioUrl,
    bool? isSeen,
    DateTime? timestamp,
    bool? isDelivered,
    bool? isRead,
    String? replyTo,
    bool? isEdited,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      isSeen: isSeen ?? this.isSeen,
      timestamp: timestamp ?? this.timestamp,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  @override
  List<Object?> get props => [
    messageId,
    senderId,
    receiverId,
    message,
    imageUrl,
    audioUrl,
    isSeen,
    timestamp,
    isDelivered,
    isRead,
    replyTo,
    isEdited,
  ];
}