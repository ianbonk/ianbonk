class CarCategory {
  final String? name;
  final String? description;
  final String? thumbnail;

  CarCategory({
    this.name,
    this.description,
    this.thumbnail,
  });

  factory CarCategory.fromJson(Map<String, dynamic> json) {
    return CarCategory(
      name: json['name'] as String?,
      description: json['description'] as String?,
      thumbnail: json['icon_url'] as String?,
    );
  }
}
