class InterestModel {
  final String id;
  final String name;
  final String icon;

  InterestModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }

  factory InterestModel.fromMap(Map<String, dynamic> map) {
    return InterestModel(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
    );
  }
}