class Manual {
  final String name;
  final String path;

  Manual({required this.name, required this.path});

  Map<String, String> toMap() => {'name': name, 'path': path};
  
  factory Manual.fromMap(Map<String, String> map) {
    return Manual(name: map['name']!, path: map['path']!);
  }
}