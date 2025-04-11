// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final List<String> interests;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isGhostMode; // Support for Ghost Mode

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.interests = const [],
    this.isOnline = false,
    required this.lastSeen,
    this.isGhostMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'interests': interests,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'isGhostMode': isGhostMode,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? 'مستخدم',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profileImage'] ?? 'https://example.com/default.jpg',
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : DateTime.now(),
      isGhostMode: json['isGhostMode'] ?? false,
    );
  }

  // Handle Firestore document directly
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return UserModel(
        uid: doc.id,
        name: 'مستخدم',
        email: '',
        lastSeen: DateTime.now(),
      );
    }
    data['uid'] = doc.id; // Ensure UID is included
    return UserModel.fromJson(data);
  }
}