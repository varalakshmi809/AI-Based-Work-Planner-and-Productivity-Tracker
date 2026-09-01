import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

import 'add_task_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'ai_suggestion_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // VARIABLES
  // ============================================================

  String _filter = 'All';
  String _progressMode = 'Weekly';
  String _userName = 'User';
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    syncTaskReminders();
  }

  Future<void> syncTaskReminders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .get();
    for (final document in snapshot.docs) {
      final data = document.data();
      final dueDate = data['dueDate'] is Timestamp
          ? (data['dueDate'] as Timestamp).toDate()
          : null;
      await NotificationService.scheduleTaskReminderFromParts(
        taskId: document.id,
        taskTitle: data['title']?.toString() ?? 'Task',
        dueDate: dueDate,
        dueTime: data['dueTime']?.toString() ?? '',
      );
    }
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final document = await _firestore.collection('users').doc(user.uid).get();
      final data = document.data() ?? {};

      if (!mounted) return;

      setState(() {
        _userName = data['name']?.toString().trim().isNotEmpty == true
            ? data['name'].toString()
            : 'User';
        _photoUrl = data['photoUrl']?.toString() ?? '';
      });
    } catch (_) {
      // Keep the dashboard usable when the profile document is unavailable.
    }
  }

  Future<void> logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) => loadUserProfile());
  }

  Widget buildProfileButton() {
    return GestureDetector(
      onTap: openProfile,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryBlue, width: 1.5),
        ),
        child: ClipOval(
          child: _photoUrl.isNotEmpty
              ? Image.network(
                  _photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, color: primaryBlue),
                )
              : const Icon(Icons.person, color: primaryBlue),
        ),
      ),
    );
  }

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF17175F);
  static const Color darkBlue = Color(0xFF101044);
  static const Color mint = Color(0xFF55D5C3);
  static const Color purple = Color(0xFFA66CC7);
  static const Color pink = Color(0xFFEBA3C5);
  static const Color backgroundColor = Color(0xFFF5F6FA);
  static const Color cardColor = Colors.white;

  // ============================================================
  // PRIORITY COLOR
  // ============================================================

  Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // ADD TASK
  // ============================================================

  Future<void> addTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  // ============================================================
  // DELETE TASK
  // ============================================================

  Future<void> deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Task',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // COMPLETE TASK
  // ============================================================

  Future<void> completeTask(String taskId, bool currentValue) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'completed': !currentValue,
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // EDIT TASK
  // ============================================================

  Future<void> openEditTask(String taskId, Map<String, dynamic> task) async {
    final titleController = TextEditingController(
      text: task['title']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: task['description']?.toString() ?? '',
    );

    String priority = task['priority']?.toString() ?? 'Medium';
    String category = task['category']?.toString() ?? 'General';

    DateTime? dueDate = getTaskDate(task['dueDate']);

    String dueTime = task['dueTime']?.toString() ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Edit Task',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'High', child: Text('High')),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            priority = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        initialValue:
                            [
                              'General',
                              'Study',
                              'Work',
                              'Personal',
                              'Shopping',
                              'Meeting',
                            ].contains(category)
                            ? category
                            : 'General',
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'General',
                            child: Text('General'),
                          ),
                          DropdownMenuItem(
                            value: 'Study',
                            child: Text('Study'),
                          ),
                          DropdownMenuItem(value: 'Work', child: Text('Work')),
                          DropdownMenuItem(
                            value: 'Personal',
                            child: Text('Personal'),
                          ),
                          DropdownMenuItem(
                            value: 'Shopping',
                            child: Text('Shopping'),
                          ),
                          DropdownMenuItem(
                            value: 'Meeting',
                            child: Text('Meeting'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            category = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // DUE DATE
                      InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );

                          if (selected != null) {
                            setDialogState(() {
                              dueDate = selected;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            prefixIcon: const Icon(Icons.calendar_month),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            dueDate == null
                                ? 'Select due date'
                                : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // DUE TIME
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (time != null) {
                            setDialogState(() {
                              dueTime = time.format(context);
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Reminder / Due Time',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            dueTime.isEmpty ? 'Select time' : dueTime,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a task title')),
                      );
                      return;
                    }

                    try {
                      // Prevent duplicate title while editing.
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) return;

                      final duplicateSnapshot = await FirebaseFirestore.instance
                          .collection('tasks')
                          .where('userId', isEqualTo: currentUser.uid)
                          .where('title', isEqualTo: title)
                          .get();

                      final duplicateExists = duplicateSnapshot.docs.any(
                        (doc) => doc.id != taskId,
                      );

                      if (duplicateExists) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'A task with the same name already exists.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final reminderAt =
                          NotificationService.reminderDateFromParts(
                            dueDate,
                            dueTime,
                          );

                      await FirebaseFirestore.instance
                          .collection('tasks')
                          .doc(taskId)
                          .update({
                            'userId': FirebaseAuth.instance.currentUser?.uid,
                            'title': title,
                            'description': descriptionController.text.trim(),
                            'priority': priority,
                            'category': category,
                            'dueDate': dueDate == null
                                ? null
                                : Timestamp.fromDate(dueDate!),
                            'dueTime': dueTime,
                            'reminderAt': reminderAt == null
                                ? null
                                : Timestamp.fromDate(reminderAt),
                            'whatsappReminderSent': false,
                          });

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unable to update task: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // GET TASK DATE
  // ============================================================

  DateTime? getTaskDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(dynamic value) {
    final date = getTaskDate(value);

    if (date == null) {
      return 'No due date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // FORMAT DATE LONG
  // ============================================================

  String formatLongDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ============================================================
  // FILTER
  // ============================================================

  void openFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Filter Tasks',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              _filterTile('All'),
              _filterTile('High'),
              _filterTile('Medium'),
              _filterTile('Low'),
              _filterTile('Completed'),
              _filterTile('Pending'),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _filterTile(String value) {
    return ListTile(
      leading: Icon(
        value == 'Completed'
            ? Icons.check_circle
            : value == 'Pending'
            ? Icons.pending_actions
            : Icons.filter_list,
        color: primaryBlue,
      ),
      title: Text(value),
      trailing: _filter == value
          ? const Icon(Icons.check, color: primaryBlue)
          : null,
      onTap: () {
        setState(() {
          _filter = value;
        });

        Navigator.pop(context);
      },
    );
  }

  // ============================================================
  // MATCH FILTER
  // ============================================================

  bool matchesFilter(Map<String, dynamic> task) {
    final completed = task['completed'] == true;

    if (_filter == 'All') return true;

    if (_filter == 'Completed') {
      return completed;
    }

    if (_filter == 'Pending') {
      return !completed;
    }

    final priority = task['priority']?.toString() ?? '';

    return priority.toLowerCase() == _filter.toLowerCase();
  }

  // ============================================================
  // TOP ICON
  // ============================================================

  Widget topIcon(IconData icon, String label, VoidCallback onPressed) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        icon: Icon(icon, color: primaryBlue, size: 21),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 7),
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void showComingSoon(String title) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: primaryBlue),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text('$title is ready for the next development phase.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // AI
  // ============================================================

  void openAi() {
    showComingSoon('AI Assistant');
  }

  void openAiTips() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiSuggestionScreen()),
    );
  }

  // ============================================================
  // SIMPLE PAGE
  // ============================================================

  void _showSimplePage({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  void openAnalytics() {
    _showSimplePage(
      title: 'Productivity Analytics',
      icon: Icons.analytics,
      child: _analyticsContent(),
    );
  }

  Widget _analyticsContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;

        int completed = 0;

        for (final doc in tasks) {
          if (doc.data()['completed'] == true) {
            completed++;
          }
        }

        final total = tasks.length;
        final pending = total - completed;

        final percentage = total == 0 ? 0.0 : completed / total * 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(
              'Your Productivity',
              'Track your task performance',
              Icons.insights,
            ),

            const SizedBox(height: 18),

            _statCard(
              'Total Tasks',
              total.toString(),
              Icons.assignment,
              Colors.blue,
              () => _showTaskDetails('All Tasks', tasks),
            ),

            _statCard(
              'Completed Tasks',
              completed.toString(),
              Icons.check_circle,
              Colors.green,
              () => _showTaskDetails(
                'Completed Tasks',
                tasks.where((doc) => doc.data()['completed'] == true).toList(),
              ),
            ),

            _statCard(
              'Pending Tasks',
              pending.toString(),
              Icons.pending_actions,
              Colors.orange,
              () => _showTaskDetails(
                'Pending Tasks',
                tasks.where((doc) => doc.data()['completed'] != true).toList(),
              ),
            ),

            _statCard(
              'Completion',
              '${percentage.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.purple,
              () => _showTaskDetails(
                'Completed Tasks',
                tasks.where((doc) => doc.data()['completed'] == true).toList(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'All Task Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (tasks.isEmpty)
              _emptyWidget('No task information available.')
            else
              ...tasks.map((doc) => taskDetailCard(doc.id, doc.data())),
          ],
        );
      },
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  void openProgress() {
    _showSimplePage(
      title: 'Progress',
      icon: Icons.bar_chart,
      child: _progressContent(),
    );
  }

  Widget _progressContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setPageState) {
            final filtered = _getProgressTasks(tasks);

            int completed = filtered
                .where((doc) => doc.data()['completed'] == true)
                .length;

            final total = filtered.length;

            final progress = total == 0 ? 0.0 : completed / total;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pageHeader(
                  'Task Progress',
                  'Monitor your daily, weekly and monthly work',
                  Icons.bar_chart,
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _progressTab('Daily', setPageState),
                      _progressTab('Weekly', setPageState),
                      _progressTab('Monthly', setPageState),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 200,
                          width: 200,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 18,
                            backgroundColor: Colors.grey.shade200,
                            color: primaryBlue,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _progressMode,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    '$completed of $total tasks completed',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Tasks in this period',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                if (filtered.isEmpty)
                  _emptyWidget('No tasks found for this period.')
                else
                  ...filtered.map((doc) => taskDetailCard(doc.id, doc.data())),
              ],
            );
          },
        );
      },
    );
  }

  Widget _progressTab(String value, StateSetter setPageState) {
    final selected = _progressMode == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setPageState(() {
            _progressMode = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _getProgressTasks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tasks,
  ) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    if (_progressMode == 'Daily') {
      start = DateTime(now.year, now.month, now.day);

      end = start.add(const Duration(days: 1));
    } else if (_progressMode == 'Weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));

      start = DateTime(monday.year, monday.month, monday.day);

      end = start.add(const Duration(days: 7));
    } else {
      start = DateTime(now.year, now.month, 1);

      end = DateTime(now.year, now.month + 1, 1);
    }

    return tasks.where((doc) {
      final date = getTaskDate(doc.data()['dueDate']);

      if (date == null) return false;

      return !date.isBefore(start) && date.isBefore(end);
    }).toList();
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  void openCalendar() {
    _showSimplePage(
      title: 'Calendar',
      icon: Icons.calendar_month,
      child: _calendarContent(),
    );
  }

  Widget _calendarContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setPageState) {
            DateTime focusedDay = DateTime.now();
            DateTime selectedDay = DateTime.now();

            return StatefulBuilder(
              builder: (context, setInnerState) {
                final selectedTasks = tasks.where((doc) {
                  final date = getTaskDate(doc.data()['dueDate']);
                  if (date == null) return false;
                  return isSameDay(date, selectedDay);
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2035),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        eventLoader: (day) {
                          return tasks.where((doc) {
                            final date = getTaskDate(doc.data()['dueDate']);
                            return date != null && isSameDay(date, day);
                          }).toList();
                        },
                        onDaySelected: (selected, focused) {
                          setInnerState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: mint.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: purple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tasks on ${formatLongDate(selectedDay)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (selectedTasks.isEmpty)
                      _emptyWidget('No tasks for this date.')
                    else
                      ...selectedTasks.map(
                        (doc) => taskDetailCard(doc.id, doc.data()),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // REPORTS
  // ============================================================

  void openReports() {
    _showSimplePage(
      title: 'Reports',
      icon: Icons.pie_chart,
      child: _reportsContent(),
    );
  }

  Widget _reportsContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;

        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        categories = {};

        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        priorities = {};

        for (final doc in tasks) {
          final data = doc.data();

          final category = data['category']?.toString() ?? 'General';

          final priority = data['priority']?.toString() ?? 'Medium';

          categories.putIfAbsent(category, () => []).add(doc);

          priorities.putIfAbsent(priority, () => []).add(doc);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(
              'Task Reports',
              'View tasks by category and priority',
              Icons.pie_chart,
            ),

            const SizedBox(height: 20),

            const Text(
              'Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...categories.entries.map((entry) {
              return _reportButton(
                entry.key,
                entry.value.length,
                Icons.category,
                primaryBlue,
                () {
                  _showTaskDetails('${entry.key} Tasks', entry.value);
                },
              );
            }),

            const SizedBox(height: 20),

            const Text(
              'Priority',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...priorities.entries.map((entry) {
              return _reportButton(
                entry.key,
                entry.value.length,
                Icons.flag,
                priorityColor(entry.key),
                () {
                  _showTaskDetails('${entry.key} Priority Tasks', entry.value);
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _reportButton(
    String title,
    int count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$count tasks'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // ============================================================
  // TASK DETAILS PAGE
  // ============================================================

  void _showTaskDetails(
    String title,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tasks,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              title: Text(title),
            ),
            body: SafeArea(
              child: tasks.isEmpty
                  ? _emptyWidget('No tasks available.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final doc = tasks[index];

                        return taskDetailCard(doc.id, doc.data());
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _pageHeader(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, darkBlue]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TASK DETAIL CARD
  // ============================================================

  Widget taskDetailCard(String taskId, Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? 'Untitled Task';

    final description = task['description']?.toString() ?? '';

    final category = task['category']?.toString() ?? 'General';

    final priority = task['priority']?.toString() ?? 'Medium';

    final dueTime = task['dueTime']?.toString() ?? '';

    final completed = task['completed'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: completed ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],

            const SizedBox(height: 12),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _infoChip(Icons.category, category, primaryBlue),
                _infoChip(Icons.flag, priority, priorityColor(priority)),
                _infoChip(
                  Icons.calendar_today,
                  formatDate(task['dueDate']),
                  Colors.purple,
                ),
                if (dueTime.isNotEmpty)
                  _infoChip(Icons.access_time, dueTime, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget taskCard(String taskId, Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? 'Untitled Task';

    final description = task['description']?.toString() ?? '';

    final priority = task['priority']?.toString() ?? 'Medium';

    final category = task['category']?.toString() ?? 'General';

    final dueTime = task['dueTime']?.toString() ?? '';

    final completed = task['completed'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17324D).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: completed,
              activeColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (_) {
                completeTask(taskId, completed);
              },
            ),

            const SizedBox(width: 3),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _smallChip(Icons.category, category, primaryBlue),
                      _smallChip(Icons.flag, priority, priorityColor(priority)),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(task['dueDate']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      if (dueTime.isNotEmpty) ...[
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dueTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            Column(
              children: [
                IconButton(
                  onPressed: () {
                    openEditTask(taskId, task);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: primaryBlue,
                    size: 20,
                  ),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 35,
                    minHeight: 35,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    deleteTask(taskId);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 35,
                    minHeight: 35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyWidget(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading tasks:\n\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  String _shortWeekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String _shortMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[date.month - 1];
  }

  Widget _templateDateSelector() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = monday.add(Duration(days: index));
          final selected = date.day == today.day && date.month == today.month;

          return Container(
            width: 52,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              color: selected ? primaryBlue : const Color(0xFFE7E7F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _shortWeekday(date),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF34363C),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _templateTaskCard(
    String taskId,
    Map<String, dynamic> task,
    int index,
  ) {
    final completed = task['completed'] == true;
    final colors = completed
        ? [purple, const Color(0xFF8A79B8), pink]
        : [mint, const Color(0xFF3FBBAA), const Color(0xFF6A8ED4)];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title']?.toString() ?? 'Untitled task',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${task['category'] ?? 'General'}${task['dueTime']?.toString().isNotEmpty == true ? '  •  ${task['dueTime']}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: completed ? 'Mark as pending' : 'Mark as complete',
            onPressed: () => completeTask(taskId, completed),
            icon: Container(
              width: 27,
              height: 27,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: completed
                  ? const Icon(Icons.check, size: 17, color: Color(0xFF66789C))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateProgressCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final completed = docs
        .where((doc) => doc.data()['completed'] == true)
        .length;
    final progress = docs.isEmpty ? 0.0 : completed / docs.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E7F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's Progress",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF30333A),
                  ),
                ),
              ),
              Text(
                '$completed/${docs.length}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(mint),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress == 1.0
                ? 'Excellent! All tasks completed.'
                : 'Keep going! You are doing great.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF68718A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('tasks')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _errorWidget(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTasks = snapshot.data!.docs;
            final filteredTasks = allTasks
                .where((doc) => matchesFilter(doc.data()))
                .toList();
            final pendingTasks = filteredTasks
                .where((doc) => doc.data()['completed'] != true)
                .toList();
            final completedTasks = filteredTasks
                .where((doc) => doc.data()['completed'] == true)
                .toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      buildProfileButton(),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $_userName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF24262C),
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              "Let's make today productive!",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF898C95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () => openProfile(),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF35373D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF22242A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_shortMonth(DateTime.now())} ${DateTime.now().day}, ${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF858993),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _templateDateSelector(),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'To Do',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF292B31),
                        ),
                      ),
                      Text(
                        '${pendingTasks.length} Tasks',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF92959E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (pendingTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: _emptyWidget(
                        'No tasks yet\nTap Add Task to begin',
                      ),
                    )
                  else
                    ...pendingTasks.asMap().entries.map(
                      (entry) => _templateTaskCard(
                        entry.value.id,
                        entry.value.data(),
                        entry.key,
                      ),
                    ),
                  const SizedBox(height: 22),
                  const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF292B31),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (completedTasks.isNotEmpty)
                    ...completedTasks.asMap().entries.map(
                      (entry) => _templateTaskCard(
                        entry.value.id,
                        entry.value.data(),
                        entry.key,
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E96C),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Completed Tasks',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF555229),
                            ),
                          ),
                        ),
                        Text(
                          '${allTasks.where((doc) => doc.data()['completed'] == true).length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF66621F),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF66621F),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _templateProgressCard(allTasks),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _templateQuickAction(
                          Icons.add_task_rounded,
                          'Add Task',
                          pink,
                          addTask,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _templateQuickAction(
                          Icons.auto_awesome,
                          'AI Tips',
                          mint,
                          openAiTips,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _templateBottomNavigationBar(),
    );
  }

  Widget _templateQuickAction(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomNavAction(Icons.home_rounded, 'Home', () {}),
            _bottomNavAction(
              Icons.calendar_today_rounded,
              'Calendar',
              openCalendar,
            ),
            _bottomNavAction(Icons.bar_chart_rounded, 'Progress', openProgress),
            _bottomNavAction(Icons.person_rounded, 'Profile', openProfile),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryBlue, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================
}
