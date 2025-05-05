import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Task {
  final String id; // Firestore document ID
  final String title;
  final DateTime date;
  final TimeOfDay time;
  bool completed;
  final String userId;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.completed,
    required this.userId,
  });

  // Convert Firestore document to Task
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['date'] as Timestamp;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      date: timestamp.toDate(),
      time: TimeOfDay(
        hour: data['timeHour'] ?? 0,
        minute: data['timeMinute'] ?? 0,
      ),
      completed: data['completed'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  // Convert Task to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'completed': completed,
      'userId': userId,
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch tasks from Firestore for the current user
  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .get();

      setState(() {
        _tasks.clear();
        _tasks.addAll(snapshot.docs.map((doc) => Task.fromFirestore(doc)));
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching tasks: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask(Task task) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .add(task.toFirestore());
      await _fetchTasks(); // Refresh tasks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task added successfully!'),
          backgroundColor: Color(0xFF673AB7),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error adding task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleTaskCompletion(int index) async {
    try {
      final task = _tasks[index];
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'completed': !task.completed,
      });
      setState(() {
        task.completed = !task.completed;
      });
    } catch (e) {
      print('Error toggling task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask(int index) async {
    try {
      final task = _tasks[index];
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task.id)
          .delete();
      setState(() {
        _tasks.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted!'),
          backgroundColor: Color(0xFF673AB7),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error deleting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Task> get _pendingTasks =>
      _tasks.where((task) => !task.completed).toList();
  List<Task> get _completedTasks =>
      _tasks.where((task) => task.completed).toList();

  Task? get _urgentTask {
    if (_pendingTasks.isEmpty) return null;

    Task earliestTask = _pendingTasks[0];
    DateTime earliestDateTime = _getDateTime(earliestTask);

    for (var task in _pendingTasks) {
      final dateTime = _getDateTime(task);
      if (dateTime.isBefore(earliestDateTime)) {
        earliestDateTime = dateTime;
        earliestTask = task;
      }
    }

    return earliestTask;
  }

  DateTime _getDateTime(Task task) {
    return DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.time.hour,
      task.time.minute,
    );
  }

  bool _isUrgent(Task task) {
    if (_urgentTask == null) return false;
    return task == _urgentTask;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'To-Do-List',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF673AB7),
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'All (${_tasks.length})'),
            Tab(text: 'Pending (${_pendingTasks.length})'),
            Tab(text: 'Completed (${_completedTasks.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskBottomSheet(context),
        backgroundColor: const Color(0xFF673AB7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllTasksView(),
                    _buildPendingTasksView(),
                    _buildCompletedTasksView(),
                  ],
                ),
      ),
    );
  }

  Widget _buildAllTasksView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_urgentTask != null) _buildUrgentTaskSection(),
        Expanded(
          child:
              _tasks.isEmpty
                  ? _buildEmptyState('No tasks yet!')
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(
                        _tasks[index],
                        onToggle: () => _toggleTaskCompletion(index),
                        onDelete: () => _deleteTask(index),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildPendingTasksView() {
    return _pendingTasks.isEmpty
        ? _buildEmptyState('No pending tasks!')
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pendingTasks.length,
          itemBuilder: (context, index) {
            final taskIndex = _tasks.indexOf(_pendingTasks[index]);
            return _buildTaskCard(
              _pendingTasks[index],
              onToggle: () => _toggleTaskCompletion(taskIndex),
              onDelete: () => _deleteTask(taskIndex),
            );
          },
        );
  }

  Widget _buildCompletedTasksView() {
    return _completedTasks.isEmpty
        ? _buildEmptyState('No completed tasks!')
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _completedTasks.length,
          itemBuilder: (context, index) {
            final taskIndex = _tasks.indexOf(_completedTasks[index]);
            return _buildTaskCard(
              _completedTasks[index],
              onToggle: () => _toggleTaskCompletion(taskIndex),
              onDelete: () => _deleteTask(taskIndex),
            );
          },
        );
  }

  Widget _buildUrgentTaskSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFF673AB7), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.priority_high, color: Color(0xFF673AB7)),
                SizedBox(width: 8),
                Text(
                  'Urgent Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF673AB7),
                  ),
                ),
              ],
            ),
          ),
          if (_urgentTask != null)
            _buildTaskCard(
              _urgentTask!,
              onToggle: () {
                final index = _tasks.indexOf(_urgentTask!);
                _toggleTaskCompletion(index);
              },
              onDelete: () {
                final index = _tasks.indexOf(_urgentTask!);
                _deleteTask(index);
              },
              showUrgentBadge: false,
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    Task task, {
    required VoidCallback onToggle,
    required VoidCallback onDelete,
    bool showUrgentBadge = true,
  }) {
    final bool isUrgent = _isUrgent(task);
    final formattedDate = DateFormat('MMM dd, yyyy').format(task.date);
    final formattedTime = task.time.format(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration:
                                    task.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                color:
                                    task.completed ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                          if (isUrgent && showUrgentBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF673AB7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    task.completed ? Icons.replay : Icons.check,
                    size: 18,
                  ),
                  label: Text(task.completed ? 'Mark Undone' : 'Mark Complete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF673AB7),
                    side: const BorderSide(color: Color(0xFF673AB7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Delete Task',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTaskBottomSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _taskController = TextEditingController();
    DateTime? _selectedDate;
    TimeOfDay? _selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_task, color: Color(0xFF673AB7)),
                        SizedBox(width: 8),
                        Text(
                          'Add New Task',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF673AB7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _taskController,
                                decoration: InputDecoration(
                                  labelText: 'Task Title',
                                  hintText: 'Enter task title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF673AB7),
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.task_alt,
                                    color: Color(0xFF673AB7),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a task title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF673AB7),
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Color(0xFF673AB7),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedDate == null
                                            ? 'Select a date'
                                            : DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(_selectedDate!),
                                        style: TextStyle(
                                          color:
                                              _selectedDate == null
                                                  ? Colors.grey
                                                  : Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Due Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime:
                                            _selectedTime ?? TimeOfDay.now(),
                                        builder: (context, child) {
                                          return Theme(
                                            data: ThemeData.light().copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary: Color(0xFF673AB7),
                                                    onPrimary: Colors.white,
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Color(0xFF673AB7),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedTime == null
                                            ? 'Select a time'
                                            : _selectedTime!.format(context),
                                        style: TextStyle(
                                          color:
                                              _selectedTime == null
                                                  ? Colors.grey
                                                  : Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a date'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (_selectedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a time'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User not authenticated'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            _addTask(
                              Task(
                                id: '', // Will be set by Firestore
                                title: _taskController.text,
                                date: _selectedDate!,
                                time: _selectedTime!,
                                completed: false,
                                userId: user.uid,
                              ),
                            );

                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF673AB7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
