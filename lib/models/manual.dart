class Manual {
  final int? id;
  final String name;
  final String path;

  Manual({this.id, required this.name, required this.path});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'path': path};

  factory Manual.fromMap(Map<String, dynamic> map) {
    return Manual(
        id: map['id'] as int?, name: map['name']!, path: map['path']!);
  }

  Manual copyWith({
    int? id,
    String? name,
    String? path,
  }) {
    return Manual(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
    );
  }

  @override
  String toString() {
    return 'Manual{id: $id, name: $name, path: $path}';
  }
}
