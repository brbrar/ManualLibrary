import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _showFavourites = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    _loadManuals(); // load manuals on start
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch) {
      _showFirstLaunchDialog();
      await prefs.setBool('first_launch', false);
    }
    _requestPermissions();
  }

  Future<void> _showFirstLaunchDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Library'),
          content: const Text(
              'Add a new PDF manual by pressing the + icon and selecting upload. '
              'Use the search icon to search already added manuals. '),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'))
          ],
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
                'This app requires storage permissions in order to save and read manual files.'),
            actions: <Widget>[
              TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Permission.storage.request();
                  },
                  child: const Text('OK'))
            ],
          );
        },
      );
    }
  }

  // Load all manuals to view in home page
  Future<void> _loadManuals() async {
    final manuals = await _manualService.loadManuals();
    setState(() {
      _manuals = manuals;
      _filteredManuals = _showFavourites
          ? manuals.where((m) => m.isFavourite).toList()
          : manuals;
    });
  }

  // Upload manuals
  Future<void> _uploadManual() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      String manualName = await _showNameDialog(context);

      if (result != null) {
        String filePath = result.files.single.path!;

        if (manualName.isNotEmpty) {
          final newManual = Manual(name: manualName, path: filePath);

          setState(() {
            _manuals.add(newManual);
            _filteredManuals = _manuals;
          });
          await _manualService.saveManual(newManual);
          await _loadManuals();
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to upload manual with error $e');
    }
  }

  // Dialog to set manual name
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

  // open manual and view as PDF
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

  // Delete manual
  Future<void> _deleteManual(Manual manual) async {
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
      await _manualService.deleteManual(manual.id!);
      await _loadManuals();
    }
  }

  // Edit manual name and file path
  Future<void> _editManual(Manual manual) async {
    TextEditingController nameController =
        TextEditingController(text: manual.name);
    String? newPath = manual.path;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Name'),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter new name'),
              ),
              const SizedBox(height: 16),
              const Text('File Path'),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      newPath!,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );

                      if (result != null) {
                        setState(() {
                          newPath = result.files.single.path!;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  Manual updatedManual = manual.copyWith(
                    name: nameController.text,
                    path: newPath,
                  );

                  await _manualService.updateManual(updatedManual);
                  await _loadManuals();

                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog('Manual name cannot be empty.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleFavourite(Manual manual) async {
    await _manualService.toggleFavourites(manual);
    await _loadManuals();
  }

  Future<void> _toggleShowFavourites() async {
    setState(() {
      _showFavourites = !_showFavourites;
      _filteredManuals = _showFavourites
          ? _manuals.where((m) => m.isFavourite).toList()
          : _manuals;
    });
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

  // Error dialog
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

  // Search stored manuals
  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: ManualSearchDelegate(_manuals, _openManual),
    );
  }

  // Info popup for selected pdf/manual
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
            onPressed: _toggleShowFavourites,
            icon: Icon(
              _showFavourites ? (Icons.favorite) : (Icons.favorite_border),
            ),
          ),
          IconButton(
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredManuals.length,
        itemBuilder: (context, index) {
          final manual = _filteredManuals[index];
          return ListTile(
            title: Text(_filteredManuals[index].name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            onTap: () => _openManual(_filteredManuals[index], context),
            trailing: Row(
              children: [
                IconButton(
                    onPressed: () => _toggleFavourite(manual),
                    icon: Icon(manual.isFavourite
                        ? Icons.favorite
                        : Icons.favorite_border)),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String result) {
                    switch (result) {
                      case 'info':
                        _showInfoPopup(context, _filteredManuals[index]);
                        break;
                      case 'delete':
                        _deleteManual(_filteredManuals[index]);
                        break;
                      case 'edit':
                        _editManual(_filteredManuals[index]);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      value: 'info',
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Info'),
                            Icon(Icons.info),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      value: 'edit',
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Edit'),
                            Icon(Icons.edit),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      value: 'delete',
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Delete'),
                            Icon(Icons.delete),
                          ],
                        ),
                      ),
                    ),
                  ],
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
