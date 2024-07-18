import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:convert';

class WebSearchScreen extends StatefulWidget {
  final String query;

  const WebSearchScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<WebSearchScreen> createState() => _WebSearchScreenState();
}

class _WebSearchScreenState extends State<WebSearchScreen> {
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
