import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aryan Portfolio',
      theme: isDark ? ThemeData.dark() : ThemeData(primarySwatch: Colors.indigo),
      home: HomePage(toggleTheme: toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;

  HomePage({required this.toggleTheme});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, String>> projects = [];
  String? imagePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  // ---------------- STORAGE ----------------
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('projects', jsonEncode(projects));
    prefs.setString('image', imagePath ?? '');
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString('projects');
    if (data != null) {
      projects = List<Map<String, String>>.from(jsonDecode(data));
    }

    imagePath = prefs.getString('image');

    setState(() {});
  }

  // ---------------- ADD PROJECT ----------------
  void addProject(String title, String desc) {
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() {
      projects.insert(0, {'title': title, 'desc': desc});
    });

    saveData();
  }

  // ---------------- DELETE PROJECT ----------------
  void deleteProject(int index) {
    setState(() {
      projects.removeAt(index);
    });
    saveData();
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imagePath = picked.path;
      });
      saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Portfolio"),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.person), text: "Profile"),
            Tab(icon: Icon(Icons.work), text: "Projects"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          profileTab(),
          projectsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  // ---------------- PROFILE ----------------
  Widget profileTab() {
    return Column(
      children: [
        SizedBox(height: 30),
        GestureDetector(
          onTap: pickImage,
          child: CircleAvatar(
            radius: 60,
            backgroundImage:
            imagePath != null && imagePath!.isNotEmpty
                ? FileImage(File(imagePath!))
                : null,
            child: imagePath == null || imagePath!.isEmpty
                ? Icon(Icons.person, size: 60)
                : null,
          ),
        ),
        SizedBox(height: 10),
        Text("Aryan Goud", style: TextStyle(fontSize: 22)),
        Text("Flutter Developer"),
      ],
    );
  }

  // ---------------- PROJECTS ----------------
  Widget projectsTab() {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        var p = projects[index];

        return Card(
          child: ListTile(
            title: Text(p['title']!),
            subtitle: Text(p['desc']!),
            leading: Icon(Icons.work),
            onLongPress: () => deleteProject(index),
          ),
        );
      },
    );
  }

  // ---------------- DIALOG ----------------
  void showAddDialog() {
    TextEditingController t = TextEditingController();
    TextEditingController d = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Project"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: InputDecoration(labelText: "Title")),
            TextField(controller: d, decoration: InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              addProject(t.text, d.text);
              Navigator.pop(context);
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }
}