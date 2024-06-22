import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/manual.dart';

class ManualService {
  static const String _key = 'manuals';

  Future<List<Manual>> loadManuals() async {
    final prefs = await SharedPreferences.getInstance();
    final manualList = prefs.getStringList(_key) ?? [];
    return manualList
        .map((e) => Manual.fromMap(Map<String, String>.from(Uri.splitQueryString(e))))
        .toList();
  }

  Future<void> saveManuals(List<Manual> manuals) async {
    final prefs = await SharedPreferences.getInstance();
    final manualList = manuals.map((e) => Uri(queryParameters: e.toMap()).query).toList();
    await prefs.setStringList(_key, manualList);
  }

  Future<Map<String, String>> getFileDetails(String path) async {
  try {
    File file = File(path);
    FileStat fileStat = await file.stat();
    return {
      'Path': path,
      'Original Name': path.split('/').last,
      'Size': '${(fileStat.size / 1048576).toStringAsFixed(2)} MB',
      'Modified': fileStat.modified.toString(),
    };
  } catch (e) {
    return {
      'Error': 'Could not retrieve file details: $e',
    };
  }
}

}