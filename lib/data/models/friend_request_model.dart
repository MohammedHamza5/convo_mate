import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String id; // معرف الطلب
  final String from; // معرف المرسل
  final String to; // معرف المستلم
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.from,
    required this.to,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return FriendRequest(
        id: doc.id,
        from: '',
        to: '',
        createdAt: DateTime.now(),
      );
    }
    data['id'] = doc.id;
    return FriendRequest.fromJson(data);
  }
}