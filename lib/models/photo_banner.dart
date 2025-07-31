class PhotoBanner {
  final int id;
  final String name;
  final String? filePath;

  PhotoBanner({
    required this.id,
    required this.name,
    required this.filePath,
  });

  factory PhotoBanner.fromJson(Map<String, dynamic> json) {
    return PhotoBanner(
      id: json['id'],
      name: json['name'],
      filePath: json['file_path'] != null
          ? 'https://your-domain/storage/${json['file_path']}'
          : null,
    );
  }
}
