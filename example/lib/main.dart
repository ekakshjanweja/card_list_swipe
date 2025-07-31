import 'package:flutter/material.dart';
import 'package:card_list_swipe/card_swipe.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Swipe Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String _lastEvent = 'None';
  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    // Show overlay by default
    _animationController.value = 1.0;
    _overlayVisible = true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCardUpdate(int cardIndex, double progress) {
    setState(() {
      _lastEvent =
          'Card $cardIndex updated: ${(progress * 100).toStringAsFixed(1)}%';
    });
    // Fade out overlay if progress > 10%
    if (progress > 0.1 && _overlayVisible) {
      _hideOverlay();
    }
    // Reset overlay if progress goes back to 0 or below 10%
    if (progress <= 0.1 && !_overlayVisible) {
      _showOverlay();
    }
  }

  void _handleCardSwipe(int cardIndex) {
    setState(() {
      _lastEvent = 'Card $cardIndex swiped away!';
    });
    // Fade in overlay on swipe
    if (!_overlayVisible) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayVisible = true;
    _animationController.forward();
  }

  void _hideOverlay() {
    _overlayVisible = false;
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Swipe Demo')),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Card swipe list
          CardSwipe(
            itemCount: 10,
            itemBuilder: (context, index) {
              final cardData = [
                {
                  'title': 'Card 1',
                  'icon': Icons.favorite,
                  'color': Colors.red,
                },
                {'title': 'Card 2', 'icon': Icons.star, 'color': Colors.orange},
                {
                  'title': 'Card 3',
                  'icon': Icons.thumb_up,
                  'color': Colors.green,
                },
                {
                  'title': 'Card 4',
                  'icon': Icons.emoji_emotions,
                  'color': Colors.blue,
                },
                {
                  'title': 'Card 5',
                  'icon': Icons.celebration,
                  'color': Colors.purple,
                },
                {
                  'title': 'Card 6',
                  'icon': Icons.music_note,
                  'color': Colors.pink,
                },
                {
                  'title': 'Card 7',
                  'icon': Icons.sports_esports,
                  'color': Colors.indigo,
                },
                {
                  'title': 'Card 8',
                  'icon': Icons.local_pizza,
                  'color': Colors.brown,
                },
                {'title': 'Card 9', 'icon': Icons.flight, 'color': Colors.teal},
                {
                  'title': 'Card 10',
                  'icon': Icons.camera_alt,
                  'color': Colors.cyan,
                },
              ];

              return CustomCard(
                index: index,
                title: cardData[index]['title'] as String,
                icon: cardData[index]['icon'] as IconData,
                color: cardData[index]['color'] as Color,
              );
            },
            onUpdate: _handleCardUpdate,
            onSwipe: _handleCardSwipe,
            cardWidth: MediaQuery.of(context).size.width * 0.8,
            cardSpacing: 16,
            padding: EdgeInsets.symmetric(horizontal: 16),
            cardAnimationDuration: const Duration(milliseconds: 200),
            cardAnimationCurve: Curves.fastEaseInToSlowEaseOut,
          ),

          // Animated overlay that shows/hides based on swipe progress
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Card Swipe List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Last Event: $_lastEvent',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }
}

class CustomCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final Color color;

  const CustomCard({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.25),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Container(
        height: 386,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.black),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Card ${index + 1}',
              style: const TextStyle(color: Colors.black38, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Custom Widget',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
