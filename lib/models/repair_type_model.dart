class RepairTypeModel {
  final String id;
  final String name;

  const RepairTypeModel({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory RepairTypeModel.fromJson(Map<String, dynamic> json) {
    return RepairTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairTypeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
