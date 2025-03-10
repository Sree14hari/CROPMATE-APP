import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SeasonalCarePage extends StatefulWidget {
  const SeasonalCarePage({Key? key}) : super(key: key);

  @override
  _SeasonalCarePageState createState() => _SeasonalCarePageState();
}

class _SeasonalCarePageState extends State<SeasonalCarePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _months = [
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
    'December'
  ];

  final Map<String, String> _seasons = {
    'January': 'Winter',
    'February': 'Winter',
    'March': 'Spring',
    'April': 'Spring',
    'May': 'Spring',
    'June': 'Summer',
    'July': 'Summer',
    'August': 'Summer',
    'September': 'Fall',
    'October': 'Fall',
    'November': 'Fall',
    'December': 'Winter'
  };

  final Map<String, List<SeasonalTask>> _monthlyTasks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final currentMonth = DateTime.now().month - 1; // 0-based index
    _tabController = TabController(
      length: 12,
      vsync: this,
      initialIndex: currentMonth,
    );
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString('seasonal_tasks');

      if (tasksJson != null) {
        final Map<String, dynamic> decodedTasks = jsonDecode(tasksJson);

        decodedTasks.forEach((month, tasks) {
          _monthlyTasks[month] = (tasks as List)
              .map((task) => SeasonalTask.fromJson(task))
              .toList();
        });
      } else {
        // Initialize with default tasks if none exist
        _initializeDefaultTasks();
      }
    } catch (e) {
      print('Error loading tasks: $e');
      _initializeDefaultTasks();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _initializeDefaultTasks() {
    // Initialize with default seasonal care tips for each month
    for (var month in _months) {
      _monthlyTasks[month] = _getDefaultTasksForMonth(month);
    }
    _saveTasks();
  }

  List<SeasonalTask> _getDefaultTasksForMonth(String month) {
    final season = _seasons[month]!;
    final List<SeasonalTask> tasks = [];

    // Common tasks for all seasons
    tasks.add(SeasonalTask(
      title: 'Check for pests',
      description: 'Inspect plants for common pests and treat as needed.',
      isCompleted: false,
    ));

    // Season-specific tasks
    switch (season) {
      case 'Winter':
        tasks.add(SeasonalTask(
          title: 'Reduce watering',
          description: 'Most plants need less water during winter dormancy.',
          isCompleted: false,
        ));
        tasks.add(SeasonalTask(
          title: 'Protect from frost',
          description:
              'Move sensitive plants indoors or cover outdoor plants during freezing temperatures.',
          isCompleted: false,
        ));
        break;
      case 'Spring':
        tasks.add(SeasonalTask(
          title: 'Start seeds',
          description:
              'Begin planting seeds for summer vegetables and flowers.',
          isCompleted: false,
        ));
        tasks.add(SeasonalTask(
          title: 'Fertilize plants',
          description:
              'Apply balanced fertilizer as plants enter active growth phase.',
          isCompleted: false,
        ));
        tasks.add(SeasonalTask(
          title: 'Increase watering',
          description: 'Gradually increase watering as temperatures rise.',
          isCompleted: false,
        ));
        break;
      case 'Summer':
        tasks.add(SeasonalTask(
          title: 'Water deeply',
          description:
              'Water plants deeply in the morning to prevent evaporation.',
          isCompleted: false,
        ));
        tasks.add(SeasonalTask(
          title: 'Mulch soil',
          description: 'Apply mulch to retain moisture and suppress weeds.',
          isCompleted: false,
        ));
        tasks.add(SeasonalTask(
          title: 'Prune flowering plants',
          description: 'Remove spent flowers to encourage continued blooming.',
          isCompleted: false,
        ));
        break;
      case 'Fall':
        tasks.add(SeasonalTask(
          title: 'Prepare for winter',
          description:
              'Clean up garden beds and prepare plants for colder weather.',
          isCompleted: false,
        ));
        tasks.add(SeasonalTask(
          title: 'Reduce fertilizing',
          description:
              'Slow down or stop fertilizing as plants prepare for dormancy.',
          isCompleted: false,
        ));
        tasks.add(SeasonalTask(
          title: 'Plant spring bulbs',
          description: 'Plant bulbs that will bloom in spring.',
          isCompleted: false,
        ));
        break;
    }

    // Add month-specific tasks
    if (month == 'January') {
      tasks.add(SeasonalTask(
        title: 'Plan your garden',
        description:
            'Use this time to plan your garden layout for the coming year.',
        isCompleted: false,
      ));
    } else if (month == 'April') {
      tasks.add(SeasonalTask(
        title: 'Divide perennials',
        description: 'Divide and replant overcrowded perennial plants.',
        isCompleted: false,
      ));
    } else if (month == 'October') {
      tasks.add(SeasonalTask(
        title: 'Harvest remaining crops',
        description: 'Harvest any remaining vegetables before frost.',
        isCompleted: false,
      ));
    }

    return tasks;
  }

  Future<void> _saveTasks() async {
    try {
      final Map<String, List<Map<String, dynamic>>> tasksToSave = {};

      _monthlyTasks.forEach((month, tasks) {
        tasksToSave[month] = tasks.map((task) => task.toJson()).toList();
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('seasonal_tasks', jsonEncode(tasksToSave));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  void _toggleTaskCompletion(String month, int index) {
    setState(() {
      _monthlyTasks[month]![index].isCompleted =
          !_monthlyTasks[month]![index].isCompleted;
    });
    _saveTasks();
  }

  void _addTask(String month) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Task for $month'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _monthlyTasks[month]!.add(SeasonalTask(
                    title: titleController.text,
                    description: descriptionController.text,
                    isCompleted: false,
                  ));
                });
                _saveTasks();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seasonal Plant Care',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: _months
              .map((month) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(month,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _months.map((month) => _buildMonthTab(month)).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _addTask(_months[_tabController.index]);
        },
        backgroundColor: Colors.green,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthTab(String month) {
    final season = _seasons[month]!;
    final tasks = _monthlyTasks[month] ?? [];
    final seasonColor = _getSeasonColor(season);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                seasonColor.withOpacity(0.2),
                seasonColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: seasonColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getSeasonIcon(season),
                    color: seasonColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    season,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: seasonColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getSeasonDescription(season),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 60,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks for $month',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _addTask(month);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: seasonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : AnimatedList(
                  key: GlobalKey<AnimatedListState>(),
                  initialItemCount: tasks.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index, animation) {
                    final task = tasks[index];
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuint,
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: seasonColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Checkbox(
                              value: task.isCompleted,
                              activeColor: seasonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (_) =>
                                  _toggleTaskCompletion(month, index),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                task.description,
                                style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? Colors.grey
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[300]),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _monthlyTasks[month]!.removeAt(index);
                                });
                                _saveTasks();
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getSeasonIcon(String season) {
    switch (season) {
      case 'Winter':
        return Icons.ac_unit;
      case 'Spring':
        return Icons.local_florist;
      case 'Summer':
        return Icons.wb_sunny;
      case 'Fall':
        return Icons.eco;
      default:
        return Icons.calendar_today;
    }
  }

  Color _getSeasonColor(String season) {
    switch (season) {
      case 'Winter':
        return Colors.blue;
      case 'Spring':
        return Colors.green;
      case 'Summer':
        return Colors.orange;
      case 'Fall':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getSeasonDescription(String season) {
    switch (season) {
      case 'Winter':
        return 'Focus on protecting plants from cold and reducing watering. Indoor plants need less water and fertilizer.';
      case 'Spring':
        return 'Time for planting, fertilizing, and gradually increasing watering as plants enter active growth.';
      case 'Summer':
        return 'Maintain consistent watering, protect from heat stress, and monitor for pests and diseases.';
      case 'Fall':
        return 'Prepare plants for dormancy, clean up garden beds, and plant spring-flowering bulbs.';
      default:
        return '';
    }
  }
}

class SeasonalTask {
  String title;
  String description;
  bool isCompleted;

  SeasonalTask({
    required this.title,
    required this.description,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  factory SeasonalTask.fromJson(Map<String, dynamic> json) {
    return SeasonalTask(
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
    );
  }
}
