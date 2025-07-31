import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Advanced scroll physics with intelligent snap-to-card behavior.
///
/// Features:
/// - Velocity-aware snapping that considers user intent and momentum
/// - Dynamic spring parameters that adapt based on distance and velocity
/// - Smart dead zone handling for predictable snapping behavior
/// - Variable scroll resistance for smoother interaction near snap points
/// - Enhanced boundary conditions with elastic behavior
/// - Adaptive tolerance for different velocity and distance scenarios
///
/// This ensures optimal user experience with smooth, predictable card navigation.
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
      mass: 0.05, // Lighter mass for snappier response
      stiffness: 250.0, // Higher stiffness for more decisive animations
      damping: 12.0, // Lower damping for snappier motion
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
  double get minFlingVelocity => 15.0; // Lower threshold for snappier flings

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

    final targetPosition = _getVelocityAwareSnapPosition(
      position.pixels,
      velocity,
    );
    final distance = (targetPosition - position.pixels).abs();

    // Dynamic tolerance based on velocity and distance
    final tolerance = _calculateSnapTolerance(velocity, distance);
    if (distance < tolerance) {
      return null;
    }

    // Create spring simulation with dynamic parameters
    final dynamicSpring = _getDynamicSpringDescription(distance, velocity);
    return ScrollSpringSimulation(
      dynamicSpring,
      position.pixels,
      targetPosition,
      velocity,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Apply variable resistance based on scroll position
    // Reduce resistance near snap positions for smoother behavior
    final cardStepSize = cardWidth + cardSpacing;
    final currentCardPosition = position.pixels % cardStepSize;
    final distanceFromSnap = math.min(
      currentCardPosition,
      cardStepSize - currentCardPosition,
    );

    // Normalize distance (0.0 = at snap point, 1.0 = halfway between snaps)
    final normalizedDistance = (distanceFromSnap / (cardStepSize * 0.5)).clamp(
      0.0,
      1.0,
    );

    // Variable resistance: less resistance near snap points
    final resistance = 1.0 + (0.3 * normalizedDistance);

    return offset * resistance;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Enhanced boundary conditions with elastic behavior
    const elasticDistance = 50.0; // Distance for elastic effect

    if (value < position.minScrollExtent) {
      final overflow = position.minScrollExtent - value;
      // Apply elastic resistance that increases with distance
      final resistance = 1.0 + (overflow / elasticDistance) * 2.0;
      return (value - position.minScrollExtent) / resistance;
    }

    if (value > position.maxScrollExtent) {
      final overflow = value - position.maxScrollExtent;
      // Apply elastic resistance that increases with distance
      final resistance = 1.0 + (overflow / elasticDistance) * 2.0;
      return (value - position.maxScrollExtent) / resistance;
    }

    return 0.0;
  }

  /// Calculate velocity-aware snap position that considers user intent
  double _getVelocityAwareSnapPosition(
    double currentPosition,
    double velocity,
  ) {
    final cardStepSize = cardWidth + cardSpacing;
    final maxScrollExtent = (totalCardCount - 1) * cardStepSize;
    final clampedPosition = currentPosition.clamp(0.0, maxScrollExtent);

    // Calculate current card index (exact, not rounded)
    final exactCardIndex = clampedPosition / cardStepSize;
    final currentCardIndex = exactCardIndex.floor();
    final nextCardIndex = currentCardIndex + 1;

    // Calculate progress within current card (0.0 to 1.0)
    final progressInCard = exactCardIndex - currentCardIndex;

    // Velocity threshold for directional snapping (optimized for card navigation)
    const velocityThreshold = 120.0;

    int targetCardIndex;

    if (velocity.abs() > velocityThreshold) {
      // High velocity: snap in direction of movement
      if (velocity > 0) {
        // Moving right: snap to next card if we're past the midpoint or have high velocity
        targetCardIndex = (progressInCard > 0.3)
            ? nextCardIndex
            : currentCardIndex;
      } else {
        // Moving left: snap to current card if we're before the midpoint or have high velocity
        targetCardIndex = (progressInCard < 0.7)
            ? currentCardIndex
            : nextCardIndex;
      }
    } else {
      // Low velocity: snap to nearest card with bias toward current position
      const deadZone = 0.12; // Optimized dead zone for better responsiveness

      if (progressInCard < 0.5 - deadZone) {
        targetCardIndex = currentCardIndex;
      } else if (progressInCard > 0.5 + deadZone) {
        targetCardIndex = nextCardIndex;
      } else {
        // In dead zone: consider velocity direction or stay at current if velocity is very low
        if (velocity.abs() < 40.0) {
          targetCardIndex =
              currentCardIndex; // Stay at current for very low velocity
        } else {
          targetCardIndex = velocity > 0 ? nextCardIndex : currentCardIndex;
        }
      }
    }

    // Clamp to valid card indices
    targetCardIndex = targetCardIndex.clamp(0, totalCardCount - 1);

    return targetCardIndex * cardStepSize;
  }

  /// Calculate dynamic snap tolerance based on velocity and distance
  double _calculateSnapTolerance(double velocity, double distance) {
    // Base tolerance
    const baseTolerance = 0.5;

    // Higher tolerance for high velocity (allow more aggressive snapping)
    final velocityFactor = (velocity.abs() / 1000.0).clamp(0.0, 2.0);

    // Lower tolerance for short distances (be more precise for small movements)
    final distanceFactor = (distance / 100.0).clamp(0.1, 1.0);

    return baseTolerance * (1.0 + velocityFactor) * distanceFactor;
  }

  /// Get dynamic spring description based on distance and velocity
  SpringDescription _getDynamicSpringDescription(
    double distance,
    double velocity,
  ) {
    // Base spring parameters
    const baseMass = 0.05;
    const baseStiffness = 250.0;
    const baseDamping = 12.0;

    // Adjust spring parameters based on distance and velocity
    final normalizedDistance = (distance / (cardWidth + cardSpacing)).clamp(
      0.1,
      2.0,
    );
    final normalizedVelocity = (velocity.abs() / 1000.0).clamp(0.1, 3.0);

    // For longer distances: reduce stiffness for smoother animation
    final stiffnessFactor = 1.0 - (normalizedDistance - 1.0) * 0.3;

    // For higher velocities: increase damping to prevent overshooting
    final dampingFactor = 1.0 + normalizedVelocity * 0.2;

    // For very short distances: increase stiffness for snappier response
    final shortDistanceBoost = normalizedDistance < 0.3 ? 1.5 : 1.0;

    return SpringDescription(
      mass: baseMass,
      stiffness: baseStiffness * stiffnessFactor * shortDistanceBoost,
      damping: baseDamping * dampingFactor,
    );
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
    // Enhanced user offset acceptance with smoother boundary handling
    // Allow scrolling with some elastic behavior even at boundaries
    return true;
  }

  /// Check if position is near a card boundary for enhanced snapping behavior
  // ignore: unused_element
  bool _isNearCardBoundary(double position, {double threshold = 0.2}) {
    final cardStepSize = cardWidth + cardSpacing;
    final positionInCard = position % cardStepSize;
    final normalizedPosition = positionInCard / cardStepSize;

    return normalizedPosition < threshold ||
        normalizedPosition > (1.0 - threshold);
  }

  /// Get smooth interpolation factor for position-based animations
  // ignore: unused_element
  double _getSmoothInterpolation(double progress) {
    // Use smooth step function for better easing
    return progress * progress * (3.0 - 2.0 * progress);
  }
}
