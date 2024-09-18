import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'task_service.dart'; // Make sure you have this service for task operations

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TaskService _taskService = TaskService();
  final TextEditingController _taskController = TextEditingController();
  String? _editingTaskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: 'Enter task for today',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_taskController.text.isNotEmpty) {
                      _taskService.addOrUpdateTask(_taskController.text).then((_) {
                        setState(() {});
                        _taskController.clear();
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _taskService.getTasksByDate(DateTime.now()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No tasks for today.'));
                }

                var tasks = snapshot.data!;
                User? currentUser = FirebaseAuth.instance.currentUser;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var taskData = tasks[index];
                    bool isCurrentUser = taskData['email'] == currentUser?.email;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(taskData['name']),
                        subtitle: Text(taskData['task']),
                        trailing: isCurrentUser
                            ? IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _taskController.text = taskData['task'];
                                  _editingTaskId = taskData['email'];
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Edit Task'),
                                      content: TextField(
                                        controller: _taskController,
                                        decoration: InputDecoration(
                                          labelText: 'Task',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            if (_taskController.text.isNotEmpty) {
                                              await _taskService.addOrUpdateTask(_taskController.text);
                                              Navigator.pop(context);
                                              setState(() {});
                                            }
                                          },
                                          child: Text('Save'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut(); // Ensure Google Sign-In is signed out
      Navigator.pushReplacementNamed(context, '/'); // Navigate to the sign-in page
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
