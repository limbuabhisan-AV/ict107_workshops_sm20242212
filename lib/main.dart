import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://lqnjqaaisexnbwgnznbk.supabase.co';
const supabasePublishableKey =
    'sb_publishable_Z2aV0av94rlXrDqFv6MrLw_7EwjTEvC';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const SupabaseStudentApp());
}

class SupabaseStudentApp extends StatelessWidget {
  const SupabaseStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ICT107 Supabase CRUD',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SupabaseStudentPage(),
    );
  }
}

class SupabaseStudentPage extends StatefulWidget {
  const SupabaseStudentPage({super.key});

  @override
  State<SupabaseStudentPage> createState() => _SupabaseStudentPageState();
}

class _SupabaseStudentPageState extends State<SupabaseStudentPage> {
  final client = Supabase.instance.client;
  List<Map<String, dynamic>> students = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    refreshStudents();
  }

  Future<void> refreshStudents() async {
    try {
      final response = await client
          .from('students')
          .select()
          .order('id', ascending: false);
      if (!mounted) return;
      setState(() {
        students = List<Map<String, dynamic>>.from(response);
        loading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> showStudentForm([Map<String, dynamic>? student]) async {
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
        title: Text(student == null ? 'Create Server Record' : 'Update Record'),
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

              try {
                if (student == null) {
                  await client.from('students').insert({
                    'name': name,
                    'student_id': studentId,
                    'course': course,
                  });
                } else {
                  await client.from('students').update({
                    'name': name,
                    'student_id': studentId,
                    'course': course,
                  }).eq('id', student['id']);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                await refreshStudents();
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Operation failed: $error')),
                );
              }
            },
            child: Text(student == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteStudent(Map<String, dynamic> student) async {
    await client.from('students').delete().eq('id', student['id']);
    await refreshStudents();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server record deleted')),
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
            Text('ICT107 Supabase Database'),
            Text(
              'Abhisan Limbu | sm20242212',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh server data',
            onPressed: refreshStudents,
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Supabase error:\n$errorMessage'),
                  ),
                )
              : students.isEmpty
                  ? const Center(child: Text('No server records found.'))
                  : RefreshIndicator(
                      onRefresh: refreshStudents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.cloud_done_outlined),
                              ),
                              title: Text(student['name'].toString()),
                              subtitle: Text(
                                '${student['student_id']} - ${student['course']}',
                              ),
                              onTap: () => showStudentForm(student),
                              trailing: IconButton(
                                tooltip: 'Delete server record',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => deleteStudent(student),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStudentForm(),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Add Server Record'),
      ),
    );
  }
}
