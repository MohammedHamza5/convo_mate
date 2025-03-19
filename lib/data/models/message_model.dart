class MessageModel {
  String senderId;
  String receiverId;
  String message;
  String? imageUrl;
  String? audioUrl;
  bool isSeen;
  DateTime timestamp;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.imageUrl,
    this.audioUrl,
    this.isSeen = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'isSeen': isSeen,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      message: json['message'],
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      isSeen: json['isSeen'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}