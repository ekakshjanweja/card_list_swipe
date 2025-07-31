import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Custom scroll physics that snaps to card positions with improved behavior.
///
/// This provides smooth snap-to-card behavior for the card swipe scroll view,
/// ensuring that scrolling always settles on a complete card view rather
/// than leaving cards partially visible. Includes improved snap detection
/// and smoother animations.
class CardSwipeSnapScrollPhysics extends ScrollPhysics {
  /// Width of each card plus spacing
  final double cardWidth;
  final double cardSpacing;
  final double horizontalPadding;
  final int totalCardCount;
  final SpringDescription springPhysics;
  final bool enableSnapping;

  const CardSwipeSnapScrollPhysics({
    required this.cardWidth,
    required this.cardSpacing,
    required this.horizontalPadding,
    required this.totalCardCount,
    super.parent,
    this.springPhysics = const SpringDescription(
      mass: 0.1, // Lighter mass for more responsive feel
      stiffness: 150.0, // Balanced stiffness for smooth movement
      damping: 15.0, // Lower damping for smoother motion
    ),
    this.enableSnapping = true,
  });

  @override
  CardSwipeSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CardSwipeSnapScrollPhysics(
      cardWidth: cardWidth,
      cardSpacing: cardSpacing,
      horizontalPadding: horizontalPadding,
      totalCardCount: totalCardCount,
      parent: buildParent(ancestor),
      springPhysics: springPhysics,
      enableSnapping: enableSnapping,
    );
  }

  @override
  double get minFlingVelocity => 25.0; // Lower threshold for more responsive flings

  @override
  double get maxFlingVelocity => 12000.0; // Higher max velocity for smoother fast scrolling

  @override
  bool get allowImplicitScrolling => false;

  @override
  SpringDescription get spring => springPhysics;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // If snapping is disabled, use parent physics
    if (!enableSnapping) {
      return super.createBallisticSimulation(position, velocity);
    }

    // If we're out of range and not headed back in range, defer to the parent
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final targetPosition = _getSnapPosition(position.pixels);

    // If we're already at the target position, don't animate
    if ((targetPosition - position.pixels).abs() < 1.0) {
      return null;
    }

    // Create spring simulation to snap to target
    return ScrollSpringSimulation(
      springPhysics,
      position.pixels,
      targetPosition,
      velocity,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Provide smoother manual scrolling with reduced friction
    // This makes the scroll feel more responsive to user input
    return offset * 1.1; // Slight boost to make scrolling feel more responsive
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Only apply boundary conditions when we're actually at the boundaries
    if (value < position.minScrollExtent) {
      return value - position.minScrollExtent;
    }
    if (value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  /// Calculate the snap position for a given scroll position
  double _getSnapPosition(double currentPosition) {
    // Calculate the step size (card width + spacing)
    final cardStepSize = cardWidth + cardSpacing;

    // Calculate how many cards are currently visible/removed
    final visibleCardCount = totalCardCount;

    if (visibleCardCount <= 0) {
      return 0.0;
    }

    // Calculate the maximum scroll extent
    final maxScrollExtent = (visibleCardCount - 1) * cardStepSize;

    // Clamp the current position to valid bounds
    final clampedPosition = currentPosition.clamp(0.0, maxScrollExtent);

    // Find the nearest card position
    final cardIndex = (clampedPosition / cardStepSize).round();
    final snapPosition = cardIndex * cardStepSize;

    // Ensure we don't snap beyond the last card
    return math.min(snapPosition, maxScrollExtent);
  }

  /// Get the current card index based on scroll position
  int getCurrentCardIndex(double scrollPosition) {
    final cardStepSize = cardWidth + cardSpacing;
    final adjustedPosition = scrollPosition + horizontalPadding;
    return (adjustedPosition / cardStepSize).round().clamp(
      0,
      totalCardCount - 1,
    );
  }

  /// Get the scroll position for a specific card index
  double getScrollPositionForCard(int cardIndex) {
    final cardStepSize = cardWidth + cardSpacing;
    return cardIndex * cardStepSize - horizontalPadding;
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // Always allow user offset unless we're at the absolute boundaries
    // This ensures scrolling works properly
    return true;
  }
}
