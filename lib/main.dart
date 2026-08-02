import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudentDatabaseApp());
}

class StudentDatabaseApp extends StatelessWidget {
  const StudentDatabaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ICT107 Student Database',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StudentHomePage(),
    );
  }
}

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, 'ict107_students.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            student_id TEXT NOT NULL,
            course TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<Map<String, Object?>>> readStudents() async {
    final db = await database;
    return db.query('students', orderBy: 'id DESC');
  }

  Future<void> createStudent({
    required String name,
    required String studentId,
    required String course,
  }) async {
    final db = await database;
    await db.insert('students', {
      'name': name,
      'student_id': studentId,
      'course': course,
    });
  }

  Future<void> updateStudent({
    required int id,
    required String name,
    required String studentId,
    required String course,
  }) async {
    final db = await database;
    await db.update(
      'students',
      {'name': name, 'student_id': studentId, 'course': course},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteStudent(int id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> importJson() async {
    final jsonText = await rootBundle.loadString('assets/students.json');
    final rows = jsonDecode(jsonText) as List<dynamic>;
    final db = await database;
    var imported = 0;

    await db.transaction((transaction) async {
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final existing = Sqflite.firstIntValue(
          await transaction.rawQuery(
            'SELECT COUNT(*) FROM students WHERE student_id = ?',
            [row['student_id']],
          ),
        );
        if (existing == 0) {
          await transaction.insert('students', {
            'name': row['name'],
            'student_id': row['student_id'],
            'course': row['course'],
          });
          imported++;
        }
      }
    });
    return imported;
  }
}

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  List<Map<String, Object?>> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refreshStudents();
  }

  Future<void> refreshStudents() async {
    final records = await DatabaseService.instance.readStudents();
    if (!mounted) return;
    setState(() {
      students = records;
      loading = false;
    });
  }

  Future<void> showStudentForm([Map<String, Object?>? student]) async {
    final nameController = TextEditingController(
      text: student?['name']?.toString() ?? '',
    );
    final idController = TextEditingController(
      text: student?['student_id']?.toString() ?? '',
    );
    final courseController = TextEditingController(
      text: student?['course']?.toString() ?? 'ICT107',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Update Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Student name'),
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final studentId = idController.text.trim();
              final course = courseController.text.trim();
              if (name.isEmpty || studentId.isEmpty || course.isEmpty) return;

              if (student == null) {
                await DatabaseService.instance.createStudent(
                  name: name,
                  studentId: studentId,
                  course: course,
                );
              } else {
                await DatabaseService.instance.updateStudent(
                  id: student['id'] as int,
                  name: name,
                  studentId: studentId,
                  course: course,
                );
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              await refreshStudents();
            },
            child: Text(student == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> importStudents() async {
    final imported = await DatabaseService.instance.importJson();
    await refreshStudents();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$imported JSON student record(s) imported')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ICT107 Student Database'),
            Text(
              'Abhisan Limbu | sm20242212',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Import JSON',
            onPressed: importStudents,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(
                  child: Text('No records yet. Add a student or import JSON.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student['id'].toString()),
                        ),
                        title: Text(student['name'].toString()),
                        subtitle: Text(
                          '${student['student_id']} - ${student['course']}',
                        ),
                        onTap: () => showStudentForm(student),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await DatabaseService.instance.deleteStudent(
                              student['id'] as int,
                            );
                            await refreshStudents();
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStudentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
    );
  }
}
