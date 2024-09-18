import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add or update task in Firestore
  Future<void> addOrUpdateTask(String task) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Get today's date as document ID (YYYY-MM-DD format)
        String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // Reference to today's document
        DocumentReference docRef = _firestore.collection('dailysync').doc(todayDate);

        // Add or update task in the array
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot docSnapshot = await transaction.get(docRef);

          List<Map<String, dynamic>> tasks = [];

          if (docSnapshot.exists) {
            // If document exists, get existing tasks and add or update the new task
            tasks = List<Map<String, dynamic>>.from(docSnapshot.get('tasks') ?? []);
            tasks.removeWhere((task) => task['email'] == user.email); // Remove existing task if any
          }

          // Add new task to the list
          tasks.add({
            'name': user.displayName,
            'email': user.email,
            'task': task,
          });

          // Set the updated tasks list
          transaction.set(docRef, {'tasks': tasks});
        });
      }
    } catch (e) {
      print("Error adding or updating task: $e");
    }
  }

  // Fetch tasks by date
  Future<List<Map<String, dynamic>>> getTasksByDate(DateTime date) async {
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      DocumentSnapshot docSnapshot = await _firestore.collection('dailysync').doc(dateStr).get();

      if (docSnapshot.exists) {
        List<dynamic> tasks = docSnapshot.get('tasks') ?? [];
        return tasks.map((task) => Map<String, dynamic>.from(task)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error getting tasks: $e");
      return [];
    }
  }
}
