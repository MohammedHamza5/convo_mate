class ChatModel {
  String chatId;
  List<String> users; // [user1Id, user2Id]
  String lastMessage;
  DateTime lastMessageTime;

  ChatModel({
    required this.chatId,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chatId'],
      users: List<String>.from(json['users']),
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
    );
  }
}