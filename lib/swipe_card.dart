import 'package:flutter/material.dart';
import 'card_swipe_transforms.dart';

/// Simple swipeable card widget that wraps custom content.
///
/// This widget provides swipe-to-dismiss functionality with smooth
/// rolling animations while delegating the visual content to the customWidget.
class SwipeCard extends StatelessWidget {
  /// The index of this card (0-based)
  final int index;

  /// Transform properties for positioning and animation
  final CardSwipeTransforms transforms;

  /// Custom widget to display as card content
  final Widget customWidget;

  /// Callback when the card is dismissed
  final VoidCallback onDismissed;

  /// Callback when swipe progress updates
  final ValueChanged<double> onSwipeUpdate;

  /// Width of the card
  final double cardWidth;

  /// Spacing between cards
  final double cardSpacing;

  /// Duration for card animations
  final Duration animationDuration;

  /// Curve for card animations
  final Curve animationCurve;

  const SwipeCard({
    super.key,
    required this.index,
    required this.transforms,
    required this.customWidget,
    required this.onDismissed,
    required this.onSwipeUpdate,
    required this.cardWidth,
    this.cardSpacing = 16,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: animationDuration,
      curve: animationCurve,
      left: index * (cardWidth + cardSpacing) + transforms.offsetX,
      top: transforms.offsetY,
      child: Transform.rotate(
        angle: transforms.rotation,
        child: Transform.scale(
          scale: transforms.scale,
          child: Opacity(
            opacity: transforms.opacity,
            child: Dismissible(
              key: Key('swipe_card_$index'),
              direction: DismissDirection.up,
              dismissThresholds: const {DismissDirection.up: 0.3},
              onDismissed: (_) => onDismissed(),
              onUpdate: (details) => onSwipeUpdate(details.progress),
              child: SizedBox(width: cardWidth, child: customWidget),
            ),
          ),
        ),
      ),
    );
  }
}
