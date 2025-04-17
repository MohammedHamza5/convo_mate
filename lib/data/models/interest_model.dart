class InterestModel {
  final String name;
  final String? icon;

  InterestModel({
    required this.name,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }

  factory InterestModel.fromMap(Map<String, dynamic> map) {
    return InterestModel(
      name: map['name'] ?? '',
      icon: map['icon'],
    );
  }
}