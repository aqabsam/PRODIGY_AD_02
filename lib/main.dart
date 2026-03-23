import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
        ),
      ),
      home: const TodoHomePage(),
    );
  }
}

class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime createdAt;
  DateTime? dueDate;
  String category;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.category = 'General',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'category': category,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    category: json['category'] ?? 'General',
  );
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  List<Task> _tasks = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  String _selectedCategory = 'General';
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'color': Colors.blue},
    {'name': 'Work', 'color': Colors.red},
    {'name': 'Personal', 'color': Colors.green},
    {'name': 'Shopping', 'color': Colors.orange},
    {'name': 'Health', 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    setState(() {
      _tasks = tasksJson
          .map((json) => Task.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  void _addTask() {
    if (_titleController.text.isEmpty) return;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      createdAt: DateTime.now(),
      dueDate: _selectedDueDate,
      category: _selectedCategory,
    );

    setState(() {
      _tasks.add(newTask);
    });

    _saveTasks();
    _titleController.clear();
    _descriptionController.clear();
    _selectedDueDate = null;
    _selectedCategory = 'General';
    Navigator.of(context).pop();
  }

  void _toggleTask(String id) {
    setState(() {
      final task = _tasks.firstWhere((t) => t.id == id);
      task.isCompleted = !task.isCompleted;
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    _saveTasks();
  }

  List<Task> get _filteredTasks {
    switch (_selectedIndex) {
      case 1:
        return _tasks.where((t) => !t.isCompleted).toList();
      case 2:
        return _tasks.where((t) => t.isCompleted).toList();
      default:
        return _tasks;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['name'] as String,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: cat['color'] as Color,
                          radius: 8,
                        ),
                        const SizedBox(width: 8),
                        Text(cat['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDueDate == null
                          ? 'No due date'
                          : 'Due: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDueDate = picked;
                        });
                      }
                    },
                    child: const Text('Pick Date'),
                  ),
                  if (_selectedDueDate != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDueDate = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _addTask, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _tasks.where((t) => t.isCompleted).length;
    final totalTasks = _tasks.length;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _selectedIndex == 0
                        ? 'My To-Do List'
                        : _selectedIndex == 1
                        ? 'Pending Tasks'
                        : 'Completed Tasks',
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (totalTasks > 0)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '$completedTasks/$totalTasks',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ),
                ],
              ),
              if (_tasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist,
                          size: 80,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first task',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_tasks.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = _filteredTasks[index];
                      return Dismissible(
                        key: Key(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) => _deleteTask(task.id),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) => _toggleTask(task.id),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6)
                                          : null,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    task.category,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: _categories
                                      .firstWhere(
                                        (cat) => cat['name'] == task.category,
                                        orElse: () => {'color': Colors.grey},
                                      )['color']
                                      .withValues(alpha: 0.2),
                                  side: BorderSide(
                                    color: _categories.firstWhere(
                                      (cat) => cat['name'] == task.category,
                                      orElse: () => {'color': Colors.grey},
                                    )['color'],
                                    width: 1,
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      task.description,
                                      style: TextStyle(
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.isCompleted
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.5)
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                if (task.dueDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color:
                                            task.dueDate!.isBefore(
                                                  DateTime.now(),
                                                ) &&
                                                !task.isCompleted
                                            ? Colors.red
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: task.isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    }, childCount: _filteredTasks.length),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
          BottomNavigationBarItem(icon: Icon(Icons.pending), label: 'Pending'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
