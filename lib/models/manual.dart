class Manual {
  final int? id;
  final String name;
  final String path;
  bool isFavourite;

  Manual(
      {this.id,
      required this.name,
      required this.path,
      this.isFavourite = false});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'path': path,
        'isFavourite': isFavourite ? 1 : 0,
      };

  factory Manual.fromMap(Map<String, dynamic> map) {
    return Manual(
      id: map['id'] as int?,
      name: map['name']!,
      path: map['path']!,
      isFavourite: map['isFavourite'] == 1,
    );
  }

  Manual copyWith({
    int? id,
    String? name,
    String? path,
    bool? isFavourite,
  }) {
    return Manual(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  @override
  String toString() {
    return 'Manual{id: $id, name: $name, path: $path, isFavourite: $isFavourite}';
  }
}
