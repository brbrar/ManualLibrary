import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/manual.dart';
import '../services/manual_service.dart';
import 'pdf_viewer_screen.dart';
import 'manual_search_delegate.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const ManualsApp());
}

class ManualsApp extends StatelessWidget {
  const ManualsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manual Library',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ManualService _manualService = ManualService();
  List<Manual> _manuals = [];
  List<Manual> _filteredManuals = [];

  @override
  void initState() {
    super.initState();
    _loadManuals(); // load manuals on start
  }

  Future<void> _loadManuals() async {
    final manuals = await _manualService.loadManuals();
    setState(() {
      _manuals = manuals;
      _filteredManuals = manuals;
    });
  }

  Future<void> _uploadManual() async {
    String manualName = await _showNameDialog(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        String filePath = result.files.single.path!;

        if (manualName.isNotEmpty) {
          final newManual = Manual(name: manualName, path: filePath);

          setState(() {
            _manuals.add(newManual);
            _filteredManuals = _manuals;
          });
          await _manualService.saveManuals(_manuals);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to upload manual with error $e');
    }
  }

  Future<String> _showNameDialog(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    String manualName = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Name the manual'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                manualName = nameController.text;
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.check),
            ),
          ],
        );
      },
    );
    return manualName;
  }

  Future<void> _openManual(Manual manual, BuildContext context) async {
    final file = File(manual.path);
    if (await file.exists() && (context.mounted)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(manual.path, manual.name),
        ),
      );
    } else {
      _showErrorDialog('Invalid file path. Press OK to delete from library.');
    }
  }

  Future<void> _deleteManual(int index) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: const Text(
                  'Are you sure you want to delete this manual from the library?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
    if (confirmDelete) {
      setState(() {
        _manuals.removeAt(index);
        _filteredManuals = _manuals;
      });
      await _manualService.saveManuals(_manuals);
    }
  }

  // Web search - not implemented
  Future<void> _searchWebManuals() async {
    // placeholder
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Search Web'),
            content:
                const Text('Search the Web for manuals. Not yet implemented.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Text"),
              ),
            ],
          );
        });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: ManualSearchDelegate(_manuals, _openManual),
    );
  }

  void _showInfoPopup(BuildContext context, Manual manual) async {
    final details = await _manualService.getFileDetails(manual.path);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Details for ${manual.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: details.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.key}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        //titleTextStyle: const TextStyle(fontWeight: FontWeight.bold),
        title: const Text('Manual Store'),
        actions: [
          IconButton(
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredManuals.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_filteredManuals[index].name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            onTap: () {
              _openManual(_filteredManuals[index], context);
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () =>
                      _showInfoPopup(context, _filteredManuals[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteManual(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.upload),
            backgroundColor: Colors.grey,
            label: 'Upload',
            onTap: () {
              _uploadManual();
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.search),
            backgroundColor: Colors.blue,
            label: 'Search Web',
            onTap: _searchWebManuals,
          )
        ],
      ),
    );
  }
}
