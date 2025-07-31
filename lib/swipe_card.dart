import 'package:flutter/material.dart';
import 'card_swipe_transforms.dart';

/// Simple swipeable card widget that wraps custom content.
///
/// This widget provides swipe-to-dismiss functionality with smooth
/// rolling animations while delegating the visual content to the customWidget.
class SwipeCard extends StatelessWidget {
  /// The index of this card (0-based)
  final int index;

  /// All removed card indices
  final Set<int> removedCards;

  /// Swipe progress for all cards
  final Map<int, double> swipeProgress;

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

  /// Custom transform callback
  final CardSwipeTransforms? Function(
    int cardIndex,
    CardSwipeTransforms baseTransforms,
    double swipeProgress,
    List<int> removedCards,
    double cardWidth,
    double cardSpacing,
  )? customTransformCallback;

  const SwipeCard({
    super.key,
    required this.index,
    required this.removedCards,
    required this.swipeProgress,
    required this.customWidget,
    required this.onDismissed,
    required this.onSwipeUpdate,
    required this.cardWidth,
    this.cardSpacing = 16,
    this.animationDuration = const Duration(milliseconds: 180),
    this.animationCurve = Curves.fastOutSlowIn,
    this.customTransformCallback,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate position (how many cards are before this one)
    int position = 0;
    for (int i = 0; i < index; i++) {
      if (!removedCards.contains(i)) position++;
    }

    final baseOffsetX = position * (cardWidth + cardSpacing);
    final currentProgress = swipeProgress[index] ?? 0.0;

    // Simple cascade effect from previous card
    double cascadeOffset = 0.0;
    if (position > 0) {
      for (int i = 0; i < index; i++) {
        if (!removedCards.contains(i)) {
          final prevProgress = swipeProgress[i] ?? 0.0;
          if (prevProgress > 0.0) {
            cascadeOffset -= prevProgress * (cardWidth + cardSpacing);
            break; // Only apply from the first swiping card
          }
        }
      }
    }

    var transforms = CardSwipeTransforms(
      offsetX: baseOffsetX + cascadeOffset,
      offsetY: 0.0,
      scale: 1.0 - (currentProgress * 0.1),
      opacity: 1.0,
      rotation: 0.0,
    );

    // Apply custom transform if provided
    if (customTransformCallback != null) {
      final customTransforms = customTransformCallback!(
        index,
        transforms,
        currentProgress,
        removedCards.toList(),
        cardWidth,
        cardSpacing,
      );
      if (customTransforms != null) {
        transforms = customTransforms;
      }
    }

    return AnimatedPositioned(
      duration: animationDuration,
      curve: animationCurve,
      left: transforms.offsetX,
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
              dismissThresholds: const {DismissDirection.up: 0.25},
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
