import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String category = 'General';
  String priority = 'Medium';

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isSaving = false;

  static const Color primaryBlue = Color(0xFF17175F);

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime today = DateTime(now.year, now.month, now.day);

    DateTime initialDate = selectedDate ?? today;

    // Make sure initial date is never before today.
    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2035),
      helpText: 'SELECT DUE DATE',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });

    // If today is selected and previously selected time is already
    // in the past, remove that time.
    if (selectedTime != null) {
      final DateTime selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      if (selectedDateTime.isBefore(now)) {
        setState(() {
          selectedTime = null;
        });

        showMessage(
          'The selected time has already passed. Please select a new time.',
        );
      }
    }
  }

  // ============================================================
  // SELECT TIME
  // ============================================================

  Future<void> selectTime() async {
    if (selectedDate == null) {
      showMessage('Please select the due date first.');
      return;
    }

    final DateTime now = DateTime.now();

    final DateTime today = DateTime(now.year, now.month, now.day);

    final bool isToday =
        selectedDate!.year == today.year &&
        selectedDate!.month == today.month &&
        selectedDate!.day == today.day;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      helpText: 'SELECT REMINDER TIME',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (pickedTime == null) return;

    if (isToday) {
      final DateTime selectedDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (selectedDateTime.isBefore(now)) {
        showMessage('Past time cannot be selected.');
        return;
      }
    }

    setState(() {
      selectedTime = pickedTime;
    });
  }

  // ============================================================
  // CHECK DUPLICATE TASK
  // ============================================================

  Future<bool> taskAlreadyExists(String title) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return false;
    }

    final String newTitle = title.trim().toLowerCase();

    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    for (final doc in snapshot.docs) {
      final String existingTitle =
          doc.data()['title']?.toString().trim().toLowerCase() ?? '';

      if (existingTitle == newTitle) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // SAVE TASK
  // ============================================================

  Future<void> saveTask() async {
    if (isSaving) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      showMessage('Please login before adding a task.');
      return;
    }

    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (title.isEmpty) {
      showMessage('Please enter a task title.');
      return;
    }

    if (selectedDate == null) {
      showMessage('Please select a due date.');
      return;
    }

    if (selectedTime == null) {
      showMessage('Please select a reminder time.');
      return;
    }

    // ==========================================================
    // IMPORTANT:
    // FORMAT TIME BEFORE ANY ASYNC OPERATION.
    //
    // This fixes:
    // use_build_context_synchronously
    // ==========================================================

    final String formattedDueTime = selectedTime!.format(context);

    // ==========================================================
    // CREATE SELECTED DATE + TIME
    // ==========================================================

    final DateTime now = DateTime.now();

    final DateTime selectedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // ==========================================================
    // DO NOT ALLOW PAST DATE/TIME
    // ==========================================================

    if (selectedDateTime.isBefore(now)) {
      showMessage(
        'Past date and time cannot be added. Please select a future time.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // ========================================================
      // CHECK DUPLICATE
      // ========================================================

      final bool duplicate = await taskAlreadyExists(title);

      if (duplicate) {
        if (!mounted) return;

        setState(() {
          isSaving = false;
        });

        showMessage('A task with the same name already exists!');

        return;
      }

      // ========================================================
      // CREATE REMINDER DATE/TIME
      // ========================================================

      final DateTime? reminderDateTime =
          NotificationService.reminderDateFromParts(
            selectedDate,
            formattedDueTime,
          );

      // ========================================================
      // CHECK REMINDER TIME
      // ========================================================

      if (reminderDateTime != null && reminderDateTime.isBefore(now)) {
        if (!mounted) return;

        setState(() {
          isSaving = false;
        });

        showMessage(
          'Reminder time has already passed. Please select a future time.',
        );

        return;
      }

      // ========================================================
      // FIRESTORE TASK DATA
      // ========================================================

      final Map<String, dynamic> taskData = {
        'userId': currentUser.uid,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,

        'dueDate': Timestamp.fromDate(
          DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day),
        ),

        'dueTime': formattedDueTime,

        'reminderAt': reminderDateTime == null
            ? null
            : Timestamp.fromDate(reminderDateTime),

        'whatsappReminderSent': false,

        'completed': false,

        'createdAt': FieldValue.serverTimestamp(),
      };

      // ========================================================
      // ADD TO FIRESTORE
      // ========================================================

      final DocumentReference<Map<String, dynamic>> task =
          await FirebaseFirestore.instance.collection('tasks').add(taskData);

      // ========================================================
      // SCHEDULE NOTIFICATION
      // ========================================================

      await NotificationService.scheduleTaskReminderFromParts(
        taskId: task.id,
        taskTitle: title,
        dueDate: selectedDate,
        dueTime: formattedDueTime,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('Task added successfully!', backgroundColor: Colors.green);

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('Unable to add task:\n$e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TITLE
              // ==================================================
              const Text(
                'Task Title',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  prefixIcon: const Icon(Icons.task_alt),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              const Text(
                'Description',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter task description',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 65),
                    child: Icon(Icons.description),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CATEGORY
              // ==================================================
              const Text(
                'Category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('General')),
                  DropdownMenuItem(value: 'Study', child: Text('Study')),
                  DropdownMenuItem(value: 'Work', child: Text('Work')),
                  DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                  DropdownMenuItem(value: 'Meeting', child: Text('Meeting')),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    category = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // PRIORITY
              // ==================================================
              const Text(
                'Priority',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.priority_high),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    priority = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // DUE DATE
              // ==================================================
              const Text(
                'Due Date',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Select due date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedDate == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // REMINDER TIME
              // ==================================================
              const Text(
                'Reminder Time',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedTime == null
                              ? 'Select reminder time'
                              : selectedTime!.format(context),
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedTime == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // ADD TASK
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? 'Saving...' : 'Add Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // DATE/TIME INFORMATION
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: primaryBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only today or future dates and times can be selected. '
                        'Past dates and times are not allowed.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // DUPLICATE INFORMATION
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: primaryBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Task names must be unique. '
                        'A task with the same name cannot be created again.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
