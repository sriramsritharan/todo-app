import 'package:flutter/material.dart';

void main() {
  runApp(const EffectiveTodoApp());
}

class EffectiveTodoApp extends StatelessWidget {
  const EffectiveTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FocusTask Master',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo primary
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// Task Model mapping to core features & best practices
class Task {
  String title;
  String label;         // e.g., '@work', '@home', '@study'
  String priority;      // 'P1' (High), 'P2' (Medium), 'P3' (Low)
  String dueDate;       // e.g., 'Today', 'Tomorrow', 'Nov 15'
  bool isMyDay;         // Daily Planner View flag
  bool isCompleted;     
  int rolloverCount;    // Tracks the "Infinite Inbox" trap (if rolled over too many times)

  Task({
    required this.title,
    this.label = '@work',
    this.priority = 'P2',
    this.dueDate = 'Today',
    this.isMyDay = false,
    this.isCompleted = false,
    this.rolloverCount = 0,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Master Inbox / Task List pre-loaded with sample data
  final List<Task> _tasks = [
    Task(title: 'Review quarterly financial report', label: '@work', priority: 'P1', dueDate: 'Today', isMyDay: true),
    Task(title: 'Call plumber for kitchen sink leak', label: '@home', priority: 'P1', dueDate: 'Today', isMyDay: true),
    Task(title: '30 minutes cardio workout', label: '@health', priority: 'P2', dueDate: 'Today', isMyDay: true),
    Task(title: 'Clear unread email inbox', label: '@work', priority: 'P3', dueDate: 'Tomorrow', isMyDay: false, rolloverCount: 3), // Triggers inbox trap warning
    Task(title: 'Read 2 chapters of system design book', label: '@study', priority: 'P2', dueDate: 'Tomorrow', isMyDay: false),
  ];

  final TextEditingController _quickCaptureController = TextEditingController();

  // Quick Capture Function (Capture immediately so you don't forget)
  void _quickCapture() {
    if (_quickCaptureController.text.trim().isNotEmpty) {
      setState(() {
        _tasks.insert(
          0,
          Task(
            title: _quickCaptureController.text.trim(),
            label: '@work',
            priority: 'P2',
            dueDate: 'Today',
            isMyDay: true, // Automatically pull into My Day for quick capture
          ),
        );
        _quickCaptureController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚡ Task captured & added to My Day!'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _toggleCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
  }

  void _toggleMyDay(Task task) {
    setState(() {
      task.isMyDay = !task.isMyDay;
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Task> myDayTasks = _tasks.where((t) => t.isMyDay && !t.isCompleted).toList();

    final List<Widget> pages = [
      // TAB 0: My Day (Daily Planner View - Limit focus to avoid overwhelm)
      MyDayView(
        tasks: _tasks,
        myDayTasks: myDayTasks,
        onToggleCompletion: _toggleCompletion,
        onToggleMyDay: _toggleMyDay,
        onDelete: _deleteTask,
      ),
      // TAB 1: Master Inbox (All Tasks & Rollover Guardrail)
      MasterInboxView(
        tasks: _tasks,
        controller: _quickCaptureController,
        onQuickCapture: _quickCapture,
        onToggleCompletion: _toggleCompletion,
        onToggleMyDay: _toggleMyDay,
        onDelete: _deleteTask,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: Color(0xFF4F46E5)),
            label: 'My Day',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox, color: Color(0xFF4F46E5)),
            label: 'Master Inbox',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// TAB 1: My Day View (Focused Daily Planner)
// -------------------------------------------------------------------------
class MyDayView extends StatelessWidget {
  final List<Task> tasks;
  final List<Task> myDayTasks;
  final Function(Task) onToggleCompletion;
  final Function(Task) onToggleMyDay;
  final Function(Task) onDelete;

  const MyDayView({
    super.key,
    required this.tasks,
    required this.myDayTasks,
    required this.onToggleCompletion,
    required this.onToggleMyDay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    int completedCount = tasks.where((t) => t.isMyDay && t.isCompleted).length;
    int totalMyDay = tasks.where((t) => t.isMyDay).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('☀️ My Day Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Night-Before Rule Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF818CF8)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rule of 3 Focus',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick only what you can realistically finish today to eliminate overwhelm.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: totalMyDay == 0 ? 0 : completedCount / totalMyDay,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Focused Tasks for Today',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: tasks.where((t) => t.isMyDay).isEmpty
                  ? const Center(child: Text('No tasks in My Day. Add some from the Master Inbox!'))
                  : ListView(
                      children: tasks.where((t) => t.isMyDay).map((task) {
                        return TaskCard(
                          task: task,
                          onToggleCompletion: onToggleCompletion,
                          onToggleMyDay: onToggleMyDay,
                          onDelete: onDelete,
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// TAB 2: Master Inbox (Quick Capture & Infinite Inbox Safeguard)
// -------------------------------------------------------------------------
class MasterInboxView extends StatelessWidget {
  final List<Task> tasks;
  final TextEditingController controller;
  final VoidCallback onQuickCapture;
  final Function(Task) onToggleCompletion;
  final Function(Task) onToggleMyDay;
  final Function(Task) onDelete;

  const MasterInboxView({
    super.key,
    required this.tasks,
    required this.controller,
    required this.onQuickCapture,
    required this.onToggleCompletion,
    required this.onToggleMyDay,
    required this.onDelete,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'P1': return Colors.redAccent;
      case 'P2': return Colors.orangeAccent;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('📥 Master Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Quick Capture Widget
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '⚡ Quick Capture task immediately...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => onQuickCapture(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onQuickCapture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All Captured Commitments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  bool isRolloverTrap = task.rolloverCount >= 3;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isRolloverTrap ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) => onToggleCompletion(task),
                                activeColor: const Color(0xFF4F46E5),
                              ),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? Colors.grey : Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  task.isMyDay ? Icons.wb_sunny : Icons.wb_sunny_outlined,
                                  color: task.isMyDay ? Colors.orange : Colors.grey,
                                ),
                                tooltip: 'Toggle My Day view',
                                onPressed: () => onToggleMyDay(task),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () => onDelete(task),
                              ),
                            ],
                          ),
                          // Metadata: Priorities, Labels, Due Dates & Infinite Inbox Trap warning
                          Padding(
                            padding: const EdgeInsets.only(left: 48.0, right: 8.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // Priority Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(task.priority).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    task.priority,
                                    style: TextStyle(color: _getPriorityColor(task.priority), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Label Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    task.label,
                                    style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                // Due Date
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(task.dueDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                                // Infinite Inbox Trap Warning Badge
                                if (isRolloverTrap)
                                  const ContainerBadge(
                                    text: '⚠️ Rolled over 3+ times (Delegate/Delete?)',
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Task Card for My Day View
class TaskCard extends StatelessWidget {
  final Task task;
  final Function(Task) onToggleCompletion;
  final Function(Task) onToggleMyDay;
  final Function(Task) onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleCompletion,
    required this.onToggleMyDay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggleCompletion(task),
          activeColor: const Color(0xFF4F46E5),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text('${task.label} • Priority: ${task.priority}', style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
          tooltip: 'Remove from My Day',
          onPressed: () => onToggleMyDay(task),
        ),
      ),
    );
  }
}

// Small helper widget for warnings
class ContainerBadge extends StatelessWidget {
  final String text;
  final Color color;

  const ContainerBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}