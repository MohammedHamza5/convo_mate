class UserModel {
  String uid;
  String name;
  String email;
  String? phone;
  String profileImage;
  List<String> interests;
  bool isOnline;
  DateTime lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.profileImage,
    required this.interests,
    this.isOnline = false,
    required this.lastSeen,
  });

  // تحويل البيانات إلى JSON لحفظها في Firestore
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
    };
  }

  // إنشاء كائن UserModel من JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profileImage'],
      interests: List<String>.from(json['interests']),
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen']),
    );
  }
}