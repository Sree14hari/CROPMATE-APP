// ignore_for_file: unused_element

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plantricz/screens/disease_detection_page.dart';
import 'package:plantricz/screens/plant_identification_page.dart';
import 'package:plantricz/screens/plants_page.dart';
import 'package:plantricz/screens/seasonal_care_page.dart'; // Add this import
import 'package:plantricz/screens/watering_page.dart';
import 'package:plantricz/services/weather_service.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 0;
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  String _currentDate = '';
  bool _isLoading = true;
  String _errorMessage = '';
  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    _currentDate = _getCurrentDate();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
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
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _loadWeatherData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final weatherData = await _weatherService.getCurrentWeather();
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load weather data';
        _isLoading = false;
      });
      print('Error loading weather: $e');
    }
  }

  Widget _buildCircularButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(color: Colors.white),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset("assets/plant1.svg", width: 120),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        // Add seasonal care calendar button
                        IconButton(
                          icon: const Icon(Icons.calendar_month,
                              color: Color.fromARGB(255, 0, 0, 0)),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const SeasonalCarePage(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  var curve = Curves.easeOutBack;
                                  var curveTween = CurveTween(curve: curve);

                                  var fadeAnimation = Tween<double>(
                                    begin: 0.0,
                                    end: 1.0,
                                  ).animate(animation.drive(curveTween));

                                  var scaleAnimation = Tween<double>(
                                    begin: 0.5,
                                    end: 1.0,
                                  ).animate(animation.drive(curveTween));

                                  return FadeTransition(
                                    opacity: fadeAnimation,
                                    child: ScaleTransition(
                                      scale: scaleAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 500),
                              ),
                            );
                          },
                          tooltip: 'Seasonal Care Calendar',
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_outlined,
                              color: Colors.black),
                          onPressed: () {
                            // Show custom popup dialog instead of Snackbar
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: MaterialLocalizations.of(context)
                                  .modalBarrierDismissLabel,
                              barrierColor: Colors.black54,
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              pageBuilder: (BuildContext context,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation) {
                                return Container();
                              },
                              transitionBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                // Define custom curves for more fluid animation
                                final CurvedAnimation curvedAnimation =
                                    CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                  reverseCurve: Curves.easeInBack,
                                );

                                return ScaleTransition(
                                  scale: Tween<double>(begin: 0.5, end: 1.0)
                                      .animate(curvedAnimation),
                                  child: FadeTransition(
                                    opacity: Tween<double>(begin: 0.0, end: 1.0)
                                        .animate(curvedAnimation),
                                    child: Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      child: AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, child) {
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10.0,
                                                  offset:
                                                      const Offset(0.0, 10.0),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Animated icon with rotation
                                                Transform.scale(
                                                  scale: Tween<double>(
                                                          begin: 0.5, end: 1.0)
                                                      .animate(CurvedAnimation(
                                                        parent: animation,
                                                        curve: Interval(
                                                            0.0, 0.5,
                                                            curve: Curves
                                                                .elasticOut),
                                                      ))
                                                      .value,
                                                  child: const Icon(
                                                    Icons.chat_bubble_outline,
                                                    color: Colors.green,
                                                    size: 60,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                // Slide in title from top
                                                Transform.translate(
                                                  offset: Offset(
                                                      0,
                                                      Tween<double>(
                                                              begin: -20.0,
                                                              end: 0.0)
                                                          .animate(
                                                              CurvedAnimation(
                                                            parent: animation,
                                                            curve: Interval(
                                                                0.2, 0.7,
                                                                curve: Curves
                                                                    .easeOutCubic),
                                                          ))
                                                          .value),
                                                  child: Opacity(
                                                    opacity: Tween<double>(
                                                            begin: 0.0,
                                                            end: 1.0)
                                                        .animate(
                                                            CurvedAnimation(
                                                          parent: animation,
                                                          curve: Interval(
                                                              0.2, 0.7,
                                                              curve: Curves
                                                                  .easeIn),
                                                        ))
                                                        .value,
                                                    child: const Text(
                                                      'Coming Soon!',
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                // Fade in description text
                                                Opacity(
                                                  opacity: Tween<double>(
                                                          begin: 0.0, end: 1.0)
                                                      .animate(CurvedAnimation(
                                                        parent: animation,
                                                        curve: Interval(
                                                            0.4, 0.9,
                                                            curve:
                                                                Curves.easeIn),
                                                      ))
                                                      .value,
                                                  child: const Text(
                                                    'Our chat feature is currently under development. Stay tuned for updates!',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                // Button with bounce effect
                                                Transform.scale(
                                                  scale: Tween<double>(
                                                          begin: 0.8, end: 1.0)
                                                      .animate(CurvedAnimation(
                                                        parent: animation,
                                                        curve: Interval(
                                                            0.6, 1.0,
                                                            curve: Curves
                                                                .elasticOut),
                                                      ))
                                                      .value,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    style: TextButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 30,
                                                          vertical: 10),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'OK',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _getPage(_page),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.white,
        buttonBackgroundColor: Colors.green,
        height: 60,
        index: _page,
        items: const [
          Icon(Icons.home_outlined, size: 30, color: Colors.black),
          Icon(Icons.local_florist_outlined, size: 30, color: Colors.black),
          Icon(Icons.person_outline, size: 30, color: Colors.black),
        ],
        onTap: (index) {
          HapticFeedback.mediumImpact(); // Add haptic feedback
          setState(() {
            _page = index;
          });
        },
      ),
    );
  }

  Widget _getPage(int page) {
    switch (page) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildPlantsPage();
      case 2:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildPlantsPage() {
    // Import the PlantsPage from plant_identification_page.dart
    return const PlantsPage();
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Weather section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _weatherData?['location']?['name'] ??
                                        'Unknown Location',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentDate,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.wb_sunny,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_weatherData?['data']?['values']?['temperature'] ?? 'N/A'}°C',
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.water_drop,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Humidity: ${_weatherData?['data']?['values']?['humidity'] ?? 'N/A'}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.air,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Wind: ${_weatherData?['data']?['values']?['windSpeed'] ?? 'N/A'} km/h',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: TextButton.icon(
                              onPressed: _loadWeatherData,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Refresh',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white24,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
          Divider(
            color: Colors.lightGreen.withOpacity(0.9),
            thickness: 2.0,
            indent: 100.0,
            endIndent: 100.0,
          ),
          // Features Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   'Plant Care Tools',
                //   style: TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.black87,
                //   ),
                // ),
                const SizedBox(height: 16),
                // Circular buttons for plant care tools
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildCircularButton(
                      title: 'Disease Detection',
                      icon: Icons.local_hospital_rounded,
                      color: Colors.redAccent,
                      onTap: () {
                        // Add custom page transition animation
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    DiseaseDetectionPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              var curve = Curves.easeOutBack;
                              var curveTween = CurveTween(curve: curve);

                              var fadeAnimation = Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(animation.drive(curveTween));

                              var scaleAnimation = Tween<double>(
                                begin: 0.5,
                                end: 1.0,
                              ).animate(animation.drive(curveTween));

                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: ScaleTransition(
                                  scale: scaleAnimation,
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                    // _buildCircularButton(
                    //   title: 'Plant Care',
                    //   icon: Icons.lightbulb_outline,
                    //   color: Colors.amber,
                    //   onTap: () {
                    //     // Navigate to plant care tips
                    //   },
                    // ),
                    _buildCircularButton(
                      title: 'Identify',
                      icon: Icons.eco,
                      color: Colors.green,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        // Add custom page transition animation
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PlantIdentificationPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              var curve = Curves.easeOutBack;
                              var curveTween = CurveTween(curve: curve);

                              var fadeAnimation = Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(animation.drive(curveTween));

                              var scaleAnimation = Tween<double>(
                                begin: 0.5,
                                end: 1.0,
                              ).animate(animation.drive(curveTween));

                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: ScaleTransition(
                                  scale: scaleAnimation,
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                    _buildCircularButton(
                      title: 'Watering',
                      icon: Icons.water_drop,
                      color: Colors.blueAccent,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const WateringPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              var curve = Curves.easeOutBack;
                              var curveTween = CurveTween(curve: curve);

                              var fadeAnimation = Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(animation.drive(curveTween));

                              var scaleAnimation = Tween<double>(
                                begin: 0.5,
                                end: 1.0,
                              ).animate(animation.drive(curveTween));

                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: ScaleTransition(
                                  scale: scaleAnimation,
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          Divider(
            color: Colors.lightGreen.withOpacity(0.9),
            thickness: 2.0,
            indent: 100.0,
            endIndent: 100.0,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return const Center(child: Text('Profile Page - Coming Soon'));
  }

  Widget _buildGridCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
