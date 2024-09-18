import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'task_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TaskService _taskService = TaskService();
  final TextEditingController _taskController = TextEditingController();
  String? _editingTaskId;
  DateTime _selectedDate = DateTime.now(); // Holds the selected date
  List<Map<String, dynamic>> _tasks = []; // Holds tasks for the selected date

  @override
  void initState() {
    super.initState();
    _fetchTasksForDate(_selectedDate); // Fetch tasks for the current date initially
  }

  // Fetch tasks for a specific date
  void _fetchTasksForDate(DateTime date) async {
    List<Map<String, dynamic>> tasks = await _taskService.getTasksByDate(date);
    setState(() {
      _tasks = tasks;
    });
  }

  // Function to show the bottom sheet date picker
  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 250,
          child: Column(
            children: [
              // Horizontal scrollable date picker
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(30, (index) {
                    DateTime date = DateTime.now().subtract(Duration(days: index));
                    bool isSelected = date.isAtSameMomentAs(_selectedDate);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('MMM dd').format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _fetchTasksForDate(_selectedDate); // Fetch tasks for the selected date
                },
                child: Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today), // Calendar icon
            onPressed: _showDatePicker, // Show date picker on tap
          ),
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
            child: _tasks.isEmpty
                ? Center(child: Text('No tasks for this day.'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      var taskData = _tasks[index];
                      User? currentUser = FirebaseAuth.instance.currentUser;
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
