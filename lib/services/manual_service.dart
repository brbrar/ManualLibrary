import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/manual.dart';
import '../helpers/database_helper.dart';

class ManualService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Manual>> loadManuals() async {
    final List<Map<String, dynamic>> maps = await _databaseHelper.getManuals();
    return List.generate(maps.length, (i) {
      return Manual.fromMap(maps[i]);
    });
  }

  Future<void> saveManual(Manual manual) async {
    await _databaseHelper.insertManual(manual.toMap());
  }

  Future<void> deleteManual(int id) async {
    await _databaseHelper.deleteManual(id);
  }

  Future<void> updateManual(Manual manual) async {
    await _databaseHelper.updateManual(manual.toMap());
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
