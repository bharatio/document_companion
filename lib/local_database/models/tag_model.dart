class TagModel {
  TagModel({
    required this.id,
    required this.name,
    required this.color,
    required this.createdOn,
  });

  String id;
  String name;
  String color; // Hex color code
  String createdOn;

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color, 'created_on': createdOn};
  }

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      createdOn: map['created_on'] as String,
    );
  }
}
