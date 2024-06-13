import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ManualsApp());
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
  List<Map<String, String>> _manuals = [];
  List<Map<String, String>> _filteredManuals = [];
  // search web for manual
  // download manual
  @override
  void initState() {
    super.initState();
    _loadManuals(); // load manuals on start
  }

  Future<void> _loadManuals() async {
    final prefs = await SharedPreferences.getInstance();
    final manualList = prefs.getStringList('manuals') ?? [];
    setState(() {
      _manuals = manualList
          .map((e) => Map<String, String>.from(Uri.splitQueryString(e)))
          .toList();
      _filteredManuals = _manuals;
    });
  }

  Future<void> _saveManuals() async {
    final prefs = await SharedPreferences.getInstance();
    final manualList =
        _manuals.map((e) => Uri(queryParameters: e).query).toList();
    await prefs.setStringList('manuals', manualList);
  }

  Future<void> _uploadManual() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      String manualName = await _showNameDialog(context);

      if (manualName.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final newFile = await file.copy('%{directory.path}/%fileName');

        setState(() {
          _manuals.add({'name': manualName, 'path': newFile.path});
          _filteredManuals = _manuals;
        });
        _saveManuals();
      }
    } else {}
  }

  Future<String> _showNameDialog(BuildContext context) async {
    TextEditingController _nameController = TextEditingController();
    String manualName = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Name the manual'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Enter name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                manualName = _nameController.text;
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

  void _searchManuals(String query) {
    setState(() {
      _filteredManuals = _manuals
          .where((manual) =>
              manual['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
            onPressed: () {
              showSearch(
                context: context,
                delegate: ManualSearchDelegate(_manuals),
              );
            },
            icon: Icon(Icons.search),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredManuals.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_filteredManuals[index]['name']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PDFViewerScreen(_filteredManuals[index]['path']!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          SpeedDial(icon: Icons.add, activeIcon: Icons.close, children: [
        SpeedDialChild(
          child: const Icon(Icons.search),
          backgroundColor: Colors.blue,
          label: 'Search Web',
          onTap: () {},
        ),
        SpeedDialChild(
          child: const Icon(Icons.upload),
          backgroundColor: Colors.grey,
          label: 'Upload',
          onTap: () {
            _uploadManual();
          },
        )
      ]),
    );
  }
}

class ManualSearchDelegate extends SearchDelegate {
  final List<Map<String, String>> manuals;

  ManualSearchDelegate(this.manuals);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = manuals
        .where((manual) =>
            manual['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]['name']!),
          onTap: () {
            // Navigate to the PDF viewer screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(results[index]['path']!),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = manuals
        .where((manual) =>
            manual['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]['name']!),
          onTap: () {
            query = suggestions[index]['name']!;
            showResults(context);
          },
        );
      },
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String path;

  PDFViewerScreen(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Name'),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}
