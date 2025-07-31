import 'package:flutter/material.dart';
import 'swipe_card.dart';
import 'card_swipe_transforms.dart';

class CardSwipeStack extends StatefulWidget {
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int itemCount;
  final void Function(int cardIndex)? onCardSwipe;
  final void Function(int cardIndex, double progress)? onCardUpdate;
  final double cardWidth;
  final double cardSpacing;
  final Duration cardAnimationDuration;
  final Curve cardAnimationCurve;

  final CardSwipeTransforms? Function(
    int cardIndex,
    CardSwipeTransforms baseTransforms,
    double swipeProgress,
    List<int> removedCards,
    double cardWidth,
    double cardSpacing,
  )?
  customTransformCallback;

  const CardSwipeStack({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.onCardSwipe,
    this.onCardUpdate,
    required this.cardWidth,
    this.cardSpacing = 16,
    this.cardAnimationDuration = const Duration(milliseconds: 180),
    this.cardAnimationCurve = Curves.fastOutSlowIn,
    this.customTransformCallback,
  });

  @override
  State<CardSwipeStack> createState() => _CardSwipeStackState();
}

/// Consolidated state for tracking card information
class _CardState {
  final Set<int> removedCards;
  final Map<int, double> swipeProgress;

  const _CardState({required this.removedCards, required this.swipeProgress});

  _CardState copyWith({
    Set<int>? removedCards,
    Map<int, double>? swipeProgress,
  }) {
    return _CardState(
      removedCards: removedCards ?? this.removedCards,
      swipeProgress: swipeProgress ?? this.swipeProgress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CardState &&
        removedCards.length == other.removedCards.length &&
        removedCards.every((card) => other.removedCards.contains(card)) &&
        swipeProgress.length == other.swipeProgress.length &&
        swipeProgress.entries.every(
          (entry) => other.swipeProgress[entry.key] == entry.value,
        );
  }

  @override
  int get hashCode => Object.hash(removedCards, swipeProgress);
}

class _CardSwipeStackState extends State<CardSwipeStack> {
  late ValueNotifier<_CardState> _cardState;

  @override
  void initState() {
    super.initState();
    _cardState = ValueNotifier(
      _CardState(removedCards: <int>{}, swipeProgress: <int, double>{}),
    );
  }

  void _handleCardDismiss(int index) {
    if (!mounted) return;

    final currentState = _cardState.value;
    final newRemovedCards = Set<int>.from(currentState.removedCards)
      ..add(index);
    final newSwipeProgress = Map<int, double>.from(currentState.swipeProgress)
      ..remove(index);

    _cardState.value = currentState.copyWith(
      removedCards: newRemovedCards,
      swipeProgress: newSwipeProgress,
    );

    widget.onCardSwipe?.call(index);
  }

  void _handleSwipeUpdate(int index, double progress) {
    if (!mounted) return;

    final currentState = _cardState.value;
    final newSwipeProgress = Map<int, double>.from(currentState.swipeProgress)
      ..[index] = progress;

    _cardState.value = currentState.copyWith(swipeProgress: newSwipeProgress);

    widget.onCardUpdate?.call(index, progress);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_CardState>(
      valueListenable: _cardState,
      builder: (context, cardState, child) {
        final List<Widget> cards = [];
        final List<int> remainingCards = [];

        // Collect remaining cards in ascending order
        for (int index = 0; index < widget.itemCount; index++) {
          if (!cardState.removedCards.contains(index)) {
            remainingCards.add(index);
          }
        }

        // Calculate layout parameters
        final remainingCardCount = remainingCards.length;

        // Create mapping from card index to visual position (0, 1, 2, 3...)
        final Map<int, int> cardToVisualPosition = {};
        for (int i = 0; i < remainingCards.length; i++) {
          cardToVisualPosition[remainingCards[i]] = i;
        }

        // Build cards from back to front for proper z-ordering
        for (int i = remainingCards.length - 1; i >= 0; i--) {
          final cardIndex = remainingCards[i];
          cards.add(_buildCard(cardIndex, cardState, cardToVisualPosition));
        }

        // Calculate width based on remaining cards, minimum of 1 card width
        final effectiveWidth = remainingCardCount > 0
            ? remainingCardCount * (widget.cardWidth + widget.cardSpacing)
            : widget.cardWidth;

        return SizedBox(
          width: effectiveWidth,
          child: Stack(children: cards),
        );
      },
    );
  }

  /// Builds a single card with all necessary transforms applied
  Widget _buildCard(
    int index,
    _CardState cardState,
    Map<int, int> cardToVisualPosition,
  ) {
    return SwipeCard(
      index: index,
      transforms: _calculateCardTransforms(
        index,
        cardState,
        cardToVisualPosition,
      ),
      customWidget: widget.itemBuilder(context, index),
      onDismissed: () => _handleCardDismiss(index),
      onSwipeUpdate: (progress) => _handleSwipeUpdate(index, progress),
      cardWidth: widget.cardWidth,
      cardSpacing: widget.cardSpacing,
      animationDuration: widget.cardAnimationDuration,
      animationCurve: widget.cardAnimationCurve,
    );
  }

  @override
  void dispose() {
    _cardState.dispose();
    super.dispose();
  }

  /// Calculates all transforms for a card including position, scale, and cascade effects
  CardSwipeTransforms _calculateCardTransforms(
    int index,
    _CardState cardState,
    Map<int, int> cardToVisualPosition,
  ) {
    // Get the visual position (0, 1, 2, 3...) for this card
    final visualPosition = cardToVisualPosition[index] ?? 0;

    // Calculate base position - each card gets consecutive visual position
    final baseOffsetX =
        visualPosition * (widget.cardWidth + widget.cardSpacing);

    // Get current card's swipe progress
    final currentProgress = cardState.swipeProgress[index] ?? 0.0;

    // Get previous card's swipe progress for cascade effect
    // Find the previous card in the visual order, not the original index order
    double previousProgress = 0.0;
    if (visualPosition > 0) {
      // Find the card that has visualPosition - 1
      for (final entry in cardToVisualPosition.entries) {
        if (entry.value == visualPosition - 1) {
          previousProgress = cardState.swipeProgress[entry.key] ?? 0.0;
          break;
        }
      }
    }

    // Calculate combined transforms
    final transforms = _calculateCombinedTransforms(
      targetOffsetX: baseOffsetX,
      currentProgress: currentProgress,
      previousProgress: previousProgress,
    );

    // Apply custom transform callback if provided
    if (widget.customTransformCallback != null) {
      final customTransforms = widget.customTransformCallback!(
        index,
        transforms,
        currentProgress,
        cardState.removedCards.toList(),
        widget.cardWidth,
        widget.cardSpacing,
      );

      if (customTransforms != null) {
        return customTransforms;
      }
    }

    return transforms;
  }

  /// Calculates combined transforms including base position, current card effects, and cascade effects
  CardSwipeTransforms _calculateCombinedTransforms({
    required double targetOffsetX,
    required double currentProgress,
    required double previousProgress,
  }) {
    // Start with the target position from removed cards
    double offsetX = targetOffsetX;
    double offsetY = 0.0;
    double scale = 1.0;
    double opacity = 1.0;
    double rotation = 0.0;

    // Apply current card's swipe effects
    if (currentProgress > 0.0) {
      // Default effects when no custom callback (will be overridden if custom callback is provided)
      if (widget.customTransformCallback == null) {
        scale =
            1.0 -
            (currentProgress *
                0.15); // More pronounced scale feedback while swiping
      }
    }

    // Apply cascade effects from previous card being swiped
    if (previousProgress > 0.0) {
      offsetX += -previousProgress * (widget.cardWidth + widget.cardSpacing);
    }

    return CardSwipeTransforms(
      offsetX: offsetX,
      offsetY: offsetY,
      scale: scale,
      opacity: opacity,
      rotation: rotation,
    );
  }
}
