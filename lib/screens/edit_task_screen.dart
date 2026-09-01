import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/notification_service.dart';

class EditTaskScreen extends StatefulWidget {
  final String docId;
  final String title;
  final String description;
  final String priority;
  final String category;
  final DateTime? dueDate;
  final String dueTime;

  const EditTaskScreen({
    super.key,
    required this.docId,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    this.dueDate,
    required this.dueTime,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  late String priority;
  late String category;

  DateTime? selectedDate;
  String dueTime = "";

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title);
    descriptionController = TextEditingController(text: widget.description);

    priority = widget.priority;
    category = widget.category;

    selectedDate = widget.dueDate;
    dueTime = widget.dueTime;
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        dueTime = picked.format(context);
      });
    }
  }

  Future<void> updateTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter Task Title")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("tasks")
          .doc(widget.docId)
          .update({
            "title": titleController.text.trim(),
            "description": descriptionController.text.trim(),
            "priority": priority,
            "category": category,
            "dueDate": selectedDate != null
                ? Timestamp.fromDate(selectedDate!)
                : null,
            "dueTime": dueTime,
            "userId": FirebaseAuth.instance.currentUser?.uid,
            "reminderAt":
                NotificationService.reminderDateFromParts(
                      selectedDate,
                      dueTime,
                    ) ==
                    null
                ? null
                : Timestamp.fromDate(
                    NotificationService.reminderDateFromParts(
                      selectedDate,
                      dueTime,
                    )!,
                  ),
            "whatsappReminderSent": false,
          });

      await NotificationService.scheduleTaskReminderFromParts(
        taskId: widget.docId,
        taskTitle: titleController.text.trim(),
        dueDate: selectedDate,
        dueTime: dueTime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Task Updated Successfully"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Task"),
        centerTitle: true,
        backgroundColor: const Color(0xFF17175F),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Container(
          color: const Color(0xFFF5F6FA),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Task Title",
                  prefixIcon: Icon(Icons.task),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(
                  labelText: "Priority",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "High", child: Text("High")),
                  DropdownMenuItem(value: "Medium", child: Text("Medium")),
                  DropdownMenuItem(value: "Low", child: Text("Low")),
                ],
                onChanged: (value) {
                  setState(() {
                    priority = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Study", child: Text("📚 Study")),
                  DropdownMenuItem(value: "Work", child: Text("💼 Work")),
                  DropdownMenuItem(
                    value: "Personal",
                    child: Text("🏠 Personal"),
                  ),
                  DropdownMenuItem(
                    value: "Shopping",
                    child: Text("🛒 Shopping"),
                  ),
                  DropdownMenuItem(value: "Meeting", child: Text("📅 Meeting")),
                ],
                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: pickDate,
                  label: Text(
                    selectedDate == null
                        ? "Select Due Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  onPressed: pickTime,
                  label: Text(dueTime.isEmpty ? "Select Due Time" : dueTime),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.update),
                  label: const Text(
                    "Update Task",
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: updateTask,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
