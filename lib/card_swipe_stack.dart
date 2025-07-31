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
    this.cardAnimationDuration = const Duration(milliseconds: 300),
    this.cardAnimationCurve = Curves.easeOutCubic,
    this.customTransformCallback,
  });

  @override
  State<CardSwipeStack> createState() => _CardSwipeStackState();
}

class _CardSwipeStackState extends State<CardSwipeStack> {
  final ValueNotifier<List<int>> _removedItems = ValueNotifier<List<int>>([]);
  final Map<int, ValueNotifier<double>> _swipeProgress = {};

  // Cache for expensive calculations
  final Map<int, int> _removedBeforeCache = {};

  /// Calculates how many cards before the given index have been removed
  int _getRemovedBeforeCount(int index) {
    // Use cache if available
    if (_removedBeforeCache.containsKey(index)) {
      return _removedBeforeCache[index]!;
    }

    // Calculate and cache the result
    final removedItems = _removedItems.value;
    final count = removedItems.where((i) => i < index).length;
    _removedBeforeCache[index] = count;

    return count;
  }

  /// Clears the cache when items are removed
  void _clearCache() {
    _removedBeforeCache.clear();
  }

  void _handleCardDismiss(int index) {
    _removedItems.value = [..._removedItems.value, index];
    _clearCache(); // Clear cache when items are removed
    if (mounted) {
      // Dispose and remove the ValueNotifier
      _swipeProgress[index]?.dispose();
      _swipeProgress.remove(index);

      widget.onCardSwipe?.call(index);
    }
  }

  void _handleSwipeUpdate(int index, double progress) {
    // Create ValueNotifier if it doesn't exist
    _swipeProgress[index] ??= ValueNotifier<double>(0.0);

    // Update the ValueNotifier (this will trigger rebuilds only for listening widgets)
    _swipeProgress[index]!.value = progress;

    widget.onCardUpdate?.call(index, progress);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<int>>(
      valueListenable: _removedItems,
      builder: (context, removedItems, child) {
        final List<Widget> cards = [];
        for (int index = widget.itemCount - 1; index >= 0; index--) {
          if (removedItems.contains(index)) {
            continue;
          }

          cards.add(_buildCard(index));
        }

        return SizedBox(
          width: widget.itemCount * (widget.cardWidth + widget.cardSpacing),
          child: Stack(children: cards),
        );
      },
    );
  }

  Widget _buildCard(int index) {
    // Create the ValueNotifier if it doesn't exist
    _swipeProgress[index] ??= ValueNotifier<double>(0.0);

    return ValueListenableBuilder<double>(
      valueListenable: _swipeProgress[index]!,
      builder: (context, currentProgress, child) {
        // Check if we need to listen to previous card for cascade effects
        if (index > 0 && !_removedItems.value.contains(index - 1)) {
          _swipeProgress[index - 1] ??= ValueNotifier<double>(0.0);

          return ValueListenableBuilder<double>(
            valueListenable: _swipeProgress[index - 1]!,
            builder: (context, previousProgress, child) {
              return SwipeCard(
                index: index,
                transforms: _calculateCardTransforms(index),
                customWidget: widget.itemBuilder(context, index),
                onDismissed: () => _handleCardDismiss(index),
                onSwipeUpdate: (progress) =>
                    _handleSwipeUpdate(index, progress),
                cardWidth: widget.cardWidth,
                cardSpacing: widget.cardSpacing,
                animationDuration: widget.cardAnimationDuration,
                animationCurve: widget.cardAnimationCurve,
              );
            },
          );
        } else {
          return SwipeCard(
            index: index,
            transforms: _calculateCardTransforms(index),
            customWidget: widget.itemBuilder(context, index),
            onDismissed: () => _handleCardDismiss(index),
            onSwipeUpdate: (progress) => _handleSwipeUpdate(index, progress),
            cardWidth: widget.cardWidth,
            cardSpacing: widget.cardSpacing,
            animationDuration: widget.cardAnimationDuration,
            animationCurve: widget.cardAnimationCurve,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    // Dispose all ValueNotifiers
    for (final notifier in _swipeProgress.values) {
      notifier.dispose();
    }
    _removedItems.dispose();
    super.dispose();
  }

  CardSwipeTransforms _calculateCardTransforms(int index) {
    // Cache removed items for performance
    final removedItems = _removedItems.value;

    // Calculate base offset from removed cards before this one
    final removedBeforeThisCard = _getRemovedBeforeCount(index);

    // Calculate the target position after all removals
    final targetOffsetX =
        -removedBeforeThisCard * (widget.cardWidth + widget.cardSpacing);

    // Start with the target position
    double offsetX = targetOffsetX;
    double offsetY = 0.0;
    double scale = 1.0;
    double opacity = 1.0;

    // Apply current card's swipe progress
    final currentProgress = _swipeProgress[index]?.value ?? 0.0;
    if (currentProgress > 0.0) {
      final currentEffects = _calculateCurrentCardEffects(currentProgress);
      offsetX += currentEffects.offsetX;
      offsetY += currentEffects.offsetY;
      scale *= currentEffects.scale;
      opacity *= currentEffects.opacity;
    }

    // Apply cascade effects from previous cards
    if (index > 0) {
      final cascadeEffects = _calculateCascadeEffects(index);
      offsetX += cascadeEffects.offsetX;
      offsetY += cascadeEffects.offsetY;
      scale *= cascadeEffects.scale;
      opacity *= cascadeEffects.opacity;
    }

    // Create base transforms
    final baseTransforms = CardSwipeTransforms(
      offsetX: offsetX,
      offsetY: offsetY,
      scale: scale,
      opacity: opacity,
    );

    // Apply custom transform callback if provided
    if (widget.customTransformCallback != null) {
      final customTransforms = widget.customTransformCallback!(
        index,
        baseTransforms,
        currentProgress,
        removedItems,
        widget.cardWidth,
        widget.cardSpacing,
      );

      if (customTransforms != null) {
        return customTransforms;
      }
    }

    return baseTransforms;
  }

  /// Calculates transform effects for the current card being swiped
  CardSwipeTransforms _calculateCurrentCardEffects(double progress) {
    // No horizontal transformation for the card being swiped
    final offsetX = 0.0;

    // Apply additional effects based on progress
    if (widget.customTransformCallback == null) {
      // Default combined effects when no custom callback
      final opacity = 1.0; // No opacity change
      final scale = 1.0 - (progress * 0.1); // Scale down slightly
      final rotation = 0.0; // No rotation

      return CardSwipeTransforms(
        offsetX: offsetX,
        offsetY: 0.0,
        scale: scale,
        opacity: opacity,
        rotation: rotation,
      );
    }

    return CardSwipeTransforms(
      offsetX: offsetX,
      offsetY: 0.0,
      scale: 1.0,
      opacity: 1.0,
      rotation: 0.0,
    );
  }

  /// Calculates cascade effects from previous cards being swiped
  CardSwipeTransforms _calculateCascadeEffects(int index) {
    if (index <= 0) return CardSwipeTransforms.identity();

    // Check if the previous card exists and hasn't been removed
    if (_removedItems.value.contains(index - 1)) {
      return CardSwipeTransforms.identity();
    }

    final previousCardProgress = _swipeProgress[index - 1]?.value ?? 0.0;
    if (previousCardProgress <= 0.0) return CardSwipeTransforms.identity();

    // Cascade effect: cards move as previous ones are swiped
    final cascadeOffset =
        -previousCardProgress * (widget.cardWidth + widget.cardSpacing);

    // Subtle scale and opacity changes for cascade effect

    return CardSwipeTransforms(
      offsetX: cascadeOffset,
      offsetY: 0.0,
      scale: 1.0,
      opacity: 1.0,
    );
  }
}
