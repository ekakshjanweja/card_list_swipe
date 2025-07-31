import 'package:flutter/material.dart';
import 'card_swipe_stack.dart';
import 'card_swipe_transforms.dart';

class CardSwipe extends StatefulWidget {
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int itemCount;
  final void Function(int cardIndex, double progress) onUpdate;
  final void Function(int cardIndex) onSwipe;
  final double cardWidth;
  final EdgeInsetsGeometry padding;
  final double cardSpacing;
  final Duration cardAnimationDuration;
  final Curve cardAnimationCurve;
  final ScrollPhysics? scrollPhysics;
  final CardSwipeTransforms? Function(
    int cardIndex,
    CardSwipeTransforms baseTransforms,
    double swipeProgress,
    List<int> removedCards,
    double cardWidth,
    double cardSpacing,
  )? customTransformCallback;

  const CardSwipe({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.onUpdate,
    required this.onSwipe,
    required this.cardWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.cardSpacing = 16,
    this.cardAnimationDuration = const Duration(milliseconds: 180),
    this.cardAnimationCurve = Curves.fastOutSlowIn,
    this.scrollPhysics,
    this.customTransformCallback,
  });

  @override
  State<CardSwipe> createState() => _CardSwipeState();
}

class _CardSwipeState extends State<CardSwipe> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _handleCardSwipe(int cardIndex) {
    widget.onSwipe(cardIndex);
  }

  void _handleCardUpdate(int cardIndex, double progress) {
    widget.onUpdate(cardIndex, progress);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: widget.scrollPhysics,
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverToBoxAdapter(
            child: CardSwipeStack(
              itemBuilder: widget.itemBuilder,
              itemCount: widget.itemCount,
              onCardSwipe: _handleCardSwipe,
              onCardUpdate: _handleCardUpdate,
              cardWidth: widget.cardWidth,
              cardAnimationDuration: widget.cardAnimationDuration,
              cardAnimationCurve: widget.cardAnimationCurve,
              cardSpacing: widget.cardSpacing,
              customTransformCallback: widget.customTransformCallback,
            ),
          ),
        ),
      ],
    );
  }
}
