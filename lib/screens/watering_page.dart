import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:path_provider/path_provider.dart';
import 'package:app_settings/app_settings.dart';

class WateringPage extends StatefulWidget {
  const WateringPage({Key? key}) : super(key: key);

  @override
  _WateringPageState createState() => _WateringPageState();
}

class _WateringPageState extends State<WateringPage> {
  final List<WateringSchedule> _schedules = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSchedules();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    // Check if we have permission to schedule exact alarms
    if (Platform.isAndroid) {
      // For Android 12+, we need to check and request permission
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Remove the extra parentheses and use the correct method
      final bool? hasPermission =
          await androidPlugin?.areNotificationsEnabled();

      if (hasPermission == false) {
        // Show a dialog explaining why we need this permission
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
                'To ensure you receive watering reminders at the correct time, please grant notification permissions.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Use the correct method to request permissions
                  await androidPlugin?.requestNotificationsPermission();
                },
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      tz_init.initializeTimeZones();
      final String timeZoneName = tz.local.name;

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Handle notification tap
        },
      );
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _scheduleNotification(WateringSchedule schedule) async {
    try {
      final int id = schedule.plant.hashCode;

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'watering_channel',
        'Watering Reminders',
        channelDescription: 'Notifications for plant watering reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      // Make sure we're scheduling for a future time
      final scheduledDate = tz.TZDateTime.from(
        schedule.nextWatering.isAfter(DateTime.now())
            ? schedule.nextWatering
            : DateTime.now().add(const Duration(minutes: 1)),
        tz.local,
      );

      // Use inexact scheduling as a fallback if exact scheduling fails
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Time to water your ${schedule.plant}!',
          'Your ${schedule.plant} needs water today.',
          scheduledDate,
          platformChannelSpecifics,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (exactAlarmError) {
        // If exact alarm fails, try with inexact timing
        print('Falling back to inexact alarm: $exactAlarmError');
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Time to water your ${schedule.plant}!',
          'Your ${schedule.plant} needs water today.',
          scheduledDate,
          platformChannelSpecifics,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = prefs.getString('watering_schedules');

    if (schedulesJson != null) {
      final List<dynamic> decoded = jsonDecode(schedulesJson);
      setState(() {
        _schedules.clear();
        for (var item in decoded) {
          _schedules.add(WateringSchedule.fromJson(item));
        }
      });
    }
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson =
        jsonEncode(_schedules.map((s) => s.toJson()).toList());
    await prefs.setString('watering_schedules', schedulesJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Watering Schedule',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          // Enhanced header section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: Colors.blue[400],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keep your plants healthy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track watering schedules and get reminders',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Schedule list or empty state
          Expanded(
            child:
                _schedules.isEmpty ? _buildEmptyState() : _buildScheduleList(),
          ),
        ],
      ),
      // Only show the floating action button when there are schedules
      floatingActionButton: _schedules.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showAddScheduleDialog();
              },
              backgroundColor: Colors.blue[600],
              icon: const Icon(Icons.add),
              label: const Text('Add Plant'),
            )
          : null,
    );
  }

  // Enhanced empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: Colors.blue[300],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No watering schedules yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add your first plant to start tracking when to water your plants',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAddScheduleDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Plant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced schedule list
  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final daysUntilWatering =
            schedule.nextWatering.difference(DateTime.now()).inDays;

        // Determine status color based on days until watering
        Color statusColor = Colors.blue;
        String statusText = 'Water in $daysUntilWatering days';

        if (daysUntilWatering <= 0) {
          statusColor = Colors.red;
          statusText = 'Water today!';
        } else if (daysUntilWatering == 1) {
          statusColor = Colors.orange;
          statusText = 'Water tomorrow';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Status indicator
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Plant image or icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: schedule.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(schedule.imagePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.local_florist,
                              size: 40,
                              color: Colors.green[700],
                            ),
                    ),
                    const SizedBox(width: 16),

                    // Plant details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.plant,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Frequency: ${schedule.frequency}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Last watered: ${_formatDate(schedule.lastWatered)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _deleteSchedule(index);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 18,
                      ),
                      label: Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.red[400],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _markAsWatered(index);
                      },
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                      ),
                      label: const Text('Watered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAsWatered(int index) async {
    final schedule = _schedules[index];
    final wateringInterval = schedule.frequency.contains('7')
        ? 7
        : schedule.frequency.contains('14')
            ? 14
            : schedule.frequency.contains('30')
                ? 30
                : 3;

    final nextWatering = DateTime.now().add(Duration(days: wateringInterval));

    setState(() {
      _schedules[index] = WateringSchedule(
        plant: schedule.plant,
        frequency: schedule.frequency,
        lastWatered: DateTime.now(),
        nextWatering: nextWatering,
        imagePath: schedule.imagePath,
      );
    });

    // Cancel existing notification and schedule a new one
    await flutterLocalNotificationsPlugin.cancel(schedule.plant.hashCode);
    await _scheduleNotification(_schedules[index]);

    await _saveSchedules();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plant marked as watered'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteSchedule(int index) async {
    final schedule = _schedules[index];

    // Cancel notification for this plant
    await flutterLocalNotificationsPlugin.cancel(schedule.plant.hashCode);

    setState(() {
      _schedules.removeAt(index);
    });

    await _saveSchedules();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule removed'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showAddScheduleDialog() async {
    String plantName = '';
    String frequency = 'Every 7 days';
    File? selectedImage;

    final picker = ImagePicker();

    Future<void> pickImage() async {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
      }
    }

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                // Wrap the container in a SingleChildScrollView to handle keyboard overflow
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dialog header
                        const Text(
                          'Add New Plant',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a watering schedule for your plant',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Image picker
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              await pickImage();
                              setDialogState(() {});
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: selectedImage != null
                                    ? DecorationImage(
                                        image: FileImage(selectedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: selectedImage == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 40,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add Photo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Plant name field
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Plant Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.eco),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (value) {
                            plantName = value;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Watering frequency dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Watering Frequency',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          value: frequency,
                          items: const [
                            DropdownMenuItem(
                              value: 'Every 3 days',
                              child: Text('Every 3 days'),
                            ),
                            DropdownMenuItem(
                              value: 'Every 7 days',
                              child: Text('Every 7 days'),
                            ),
                            DropdownMenuItem(
                              value: 'Every 14 days',
                              child: Text('Every 14 days'),
                            ),
                            DropdownMenuItem(
                              value: 'Every 30 days',
                              child: Text('Every 30 days'),
                            ),
                          ],
                          onChanged: (value) {
                            frequency = value!;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (plantName.isNotEmpty) {
                                  final days = frequency.contains('3')
                                      ? 3
                                      : frequency.contains('7')
                                          ? 7
                                          : frequency.contains('14')
                                              ? 14
                                              : 30;

                                  final nextWatering =
                                      DateTime.now().add(Duration(days: days));

                                  // Save image if selected
                                  String? imagePath;
                                  if (selectedImage != null) {
                                    final appDir =
                                        await getApplicationDocumentsDirectory();
                                    final fileName =
                                        '${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    final savedImage = await selectedImage!
                                        .copy('${appDir.path}/$fileName');
                                    imagePath = savedImage.path;
                                  }

                                  final newSchedule = WateringSchedule(
                                    plant: plantName,
                                    frequency: frequency,
                                    lastWatered: DateTime.now(),
                                    nextWatering: nextWatering,
                                    imagePath: imagePath,
                                  );

                                  setState(() {
                                    _schedules.add(newSchedule);
                                  });

                                  // Schedule notification
                                  await _scheduleNotification(newSchedule);

                                  await _saveSchedules();

                                  Navigator.pop(context);

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${plantName} added to your watering schedule'),
                                      backgroundColor: Colors.green[600],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Show error for empty plant name
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please enter a plant name'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Add Plant'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class WateringSchedule {
  final String plant;
  final String frequency;
  final DateTime lastWatered;
  final DateTime nextWatering;
  final String? imagePath; // Changed from image to imagePath

  WateringSchedule({
    required this.plant,
    required this.frequency,
    required this.lastWatered,
    required this.nextWatering,
    this.imagePath,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'plant': plant,
      'frequency': frequency,
      'lastWatered': lastWatered.toIso8601String(),
      'nextWatering': nextWatering.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  // Create from JSON
  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      plant: json['plant'],
      frequency: json['frequency'],
      lastWatered: DateTime.parse(json['lastWatered']),
      nextWatering: DateTime.parse(json['nextWatering']),
      imagePath: json['imagePath'],
    );
  }
}
