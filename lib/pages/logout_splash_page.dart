import 'package:flutter/material.dart';
import 'dart:math';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoutSplashPage extends StatefulWidget {
  const LogoutSplashPage({super.key});

  @override
  State<LogoutSplashPage> createState() => _LogoutSplashPageState();
}

class _LogoutSplashPageState extends State<LogoutSplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _titleController;
  late final Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _titleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: _StarryBackgroundPainter(_orbitController),
            size: Size.infinite,
          ),
          Center(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.yellow.withOpacity(0.5),
                              Colors.transparent,
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      ...List.generate(9, (index) => _buildPlanet(index)),
                    ],
                  );
                },
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _titleOpacity,
              builder: (context, child) {
                return Opacity(
                  opacity: _titleOpacity.value,
                  child: Text(
                    'Vedic Cosmos',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.cyan.withOpacity(0.5),
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: GestureDetector(
                onTap: () {
                  Get.offAllNamed('/');
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(color: Colors.white30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  child: Text(
                    'Login',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanet(int index) {
    final planets = [
      {'name': 'Sun', 'color': Colors.orange, 'size': 20.0, 'radius': 80.0},
      {'name': 'Moon', 'color': Colors.white, 'size': 18.0, 'radius': 100.0},
      {'name': 'Mars', 'color': Colors.red, 'size': 16.0, 'radius': 120.0},
      {'name': 'Mercury', 'color': Colors.green, 'size': 14.0, 'radius': 140.0},
      {
        'name': 'Jupiter',
        'color': Colors.yellow,
        'size': 22.0,
        'radius': 160.0
      },
      {'name': 'Venus', 'color': Colors.pink, 'size': 18.0, 'radius': 180.0},
      {'name': 'Saturn', 'color': Colors.brown, 'size': 20.0, 'radius': 200.0},
      {'name': 'Rahu', 'color': Colors.grey, 'size': 16.0, 'radius': 220.0},
      {'name': 'Ketu', 'color': Colors.black, 'size': 16.0, 'radius': 240.0},
    ];

    final angle = _orbitController.value * 2 * pi + (index * 2 * pi / 9);
    final x = planets[index]['radius'] * cos(angle);
    final y = planets[index]['radius'] * sin(angle) * 0.5;

    return Positioned(
      left: x +
          MediaQuery.of(context).size.width / 2 -
          (planets[index]['size'] as double) / 2,
      top: y +
          MediaQuery.of(context).size.height / 2 -
          (planets[index]['size'] as double) / 2,
      child: Container(
        width: planets[index]['size'] as double,
        height: planets[index]['size'] as double,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (planets[index]['color'] as Color).withOpacity(0.8),
          border: Border.all(color: Colors.white30),
          boxShadow: [
            BoxShadow(
              color: (planets[index]['color'] as Color).withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Text(
            (planets[index]['name'] as String).substring(0, 1),
            style: TextStyle(
              color: Colors.white,
              fontSize: (planets[index]['size'] as double) * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarryBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  _StarryBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(0);
    final paint = Paint();

    final gradient = RadialGradient(
      center: const Alignment(0.7, -0.6),
      radius: 0.8,
      colors: [
        Colors.purple.withOpacity(0.3),
        Colors.blue.withOpacity(0.2),
        Colors.black,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    for (var i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      final opacity = (sin(animation.value * 2 * pi + i) + 1) / 2 * 0.4 + 0.6;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarryBackgroundPainter oldDelegate) => true;
}
