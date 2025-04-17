import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final List<String> interests;
  final List<String> friends;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isGhostMode;
  final String? maritalStatus; // الحالة الاجتماعية
  final String? bio; // نبذة تعريفية
  final String? birthDate; // تاريخ الميلاد
  final String? city; // المدينة

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.interests = const [],
    this.friends = const [],
    this.isOnline = false,
    required this.lastSeen,
    this.isGhostMode = false,
    this.maritalStatus,
    this.bio,
    this.birthDate,
    this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'interests': interests,
      'friends': friends,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'isGhostMode': isGhostMode,
      'maritalStatus': maritalStatus,
      'bio': bio,
      'birthDate': birthDate,
      'city': city,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Convert Firestore Timestamp to DateTime
    DateTime parseLastSeen() {
      final lastSeenField = json['lastSeen'];
      if (lastSeenField is Timestamp) {
        return lastSeenField.toDate();
      } else if (lastSeenField is String) {
        return DateTime.parse(lastSeenField);
      } else {
        return DateTime.now();
      }
    }

    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? 'مستخدم',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage:
      json['profileImage']?.isNotEmpty == true ? json['profileImage'] : null,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      friends: json['friends'] != null
          ? List<String>.from(json['friends'])
          : [],
      isOnline: json['isOnline'] ?? false,
      lastSeen: parseLastSeen(),
      isGhostMode: json['isGhostMode'] ?? false,
      maritalStatus: json['maritalStatus'],
      bio: json['bio'],
      birthDate: json['birthDate'],
      city: json['city'],
    );
  }

  // Helper method to convert timestamp to date for birthDate field
  static String? convertTimestampToString(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } else if (timestamp is String) {
      return timestamp;
    }
    return null;
  }

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
    
    // Add the document ID to the data
    final Map<String, dynamic> userData = {...data, 'uid': doc.id};
    
    // Handle potential Timestamp fields before passing to fromJson
    if (userData['birthDate'] != null) {
      userData['birthDate'] = convertTimestampToString(userData['birthDate']);
    }
    
    return UserModel.fromJson(userData);
  }
}