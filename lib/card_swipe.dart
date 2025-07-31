import 'package:flutter/material.dart';
import 'card_swipe_stack.dart';
import 'card_swipe_snap_scroll_physics.dart';
import 'card_swipe_transforms.dart';

/// Main card swipe widget that displays a horizontally scrollable
/// stack of dismissible custom widgets with rolling animation effects.
///
/// This widget works similarly to ListView.builder, accepting an itemBuilder
/// function for creating swipeable card interfaces.
/// All styling should be applied directly to the card widgets themselves.
/// All animations are fully customizable.
class CardSwipe extends StatefulWidget {
  /// Builder function for creating cards dynamically
  /// Takes (context, index) and returns a Widget
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Number of items to build
  final int itemCount;

  /// Callback triggered when a card is swiped (progress updates)
  /// Parameters: (cardIndex, swipeProgress)
  final void Function(int cardIndex, double progress) onUpdate;

  /// Callback triggered when a card is dismissed/swiped away
  /// Parameters: (cardIndex)
  final void Function(int cardIndex) onSwipe;

  /// Width of each card (used for positioning calculations)
  final double cardWidth;

  /// Horizontal padding around the card swipe
  final EdgeInsetsGeometry padding;

  /// Spacing between cards
  final double cardSpacing;

  /// Duration for card position and transform animations
  final Duration cardAnimationDuration;

  /// Curve for card position and transform animations
  final Curve cardAnimationCurve;

  /// Spring physics for scroll snap behavior
  final SpringDescription springPhysics;

  /// Custom scroll physics (optional)
  /// If provided, this will be used instead of the default CardSwipeSnapScrollPhysics
  final ScrollPhysics? scrollPhysics;

  /// Whether to enable snapping to card positions
  /// When true, scrolling will snap to complete card views
  /// When false, scrolling will be free-form without snapping
  final bool enableSnapping;

  /// Custom transform callback for advanced animation control
  /// Parameters: (cardIndex, baseTransforms, swipeProgress, removedCards, cardWidth, cardSpacing)
  /// Returns: Custom CardSwipeTransforms or null to use default behavior
  final CardSwipeTransforms? Function(
    int cardIndex,
    CardSwipeTransforms baseTransforms,
    double swipeProgress,
    List<int> removedCards,
    double cardWidth,
    double cardSpacing,
  )?
  customTransformCallback;

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
    this.springPhysics = const SpringDescription(
      mass: 0.05, // Lighter mass for snappier response
      stiffness: 250.0, // Higher stiffness for more decisive animations
      damping: 12.0, // Lower damping for snappier motion
    ),
    this.scrollPhysics,
    this.enableSnapping = false,
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
    final effectiveCardWidth = widget.cardWidth;

    return CustomScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics:
          widget.scrollPhysics ??
          CardSwipeSnapScrollPhysics(
            cardWidth: effectiveCardWidth,
            cardSpacing: widget.cardSpacing,
            horizontalPadding: widget.padding.horizontal,
            totalCardCount: widget.itemCount,
            parent: const ClampingScrollPhysics(),
            springPhysics: widget.springPhysics,
            enableSnapping: widget.enableSnapping,
          ),
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
