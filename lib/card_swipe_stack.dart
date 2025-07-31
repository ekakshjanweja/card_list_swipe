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
  )? customTransformCallback;

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

class _CardSwipeStackState extends State<CardSwipeStack> {
  final Set<int> _removedCards = <int>{};
  final Map<int, double> _swipeProgress = <int, double>{};

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    // Count remaining cards
    int remainingCount = 0;
    for (int index = 0; index < widget.itemCount; index++) {
      if (!_removedCards.contains(index)) remainingCount++;
    }

    // Build cards from back to front for proper z-ordering
    for (int index = widget.itemCount - 1; index >= 0; index--) {
      if (_removedCards.contains(index)) continue;

      cards.add(SwipeCard(
        key: ValueKey(index),
        index: index,
        removedCards: _removedCards,
        swipeProgress: _swipeProgress,
        customWidget: widget.itemBuilder(context, index),
        onDismissed: () {
          setState(() {
            _removedCards.add(index);
            _swipeProgress.remove(index);
          });
          widget.onCardSwipe?.call(index);
        },
        onSwipeUpdate: (progress) {
          setState(() {
            _swipeProgress[index] = progress;
          });
          widget.onCardUpdate?.call(index, progress);
        },
        cardWidth: widget.cardWidth,
        cardSpacing: widget.cardSpacing,
        animationDuration: widget.cardAnimationDuration,
        animationCurve: widget.cardAnimationCurve,
        customTransformCallback: widget.customTransformCallback,
      ));
    }

    // Calculate width based on remaining cards
    final effectiveWidth = remainingCount > 0
        ? remainingCount * (widget.cardWidth + widget.cardSpacing)
        : widget.cardWidth;

    return SizedBox(
      width: effectiveWidth,
      child: Stack(children: cards),
    );
  }
}
