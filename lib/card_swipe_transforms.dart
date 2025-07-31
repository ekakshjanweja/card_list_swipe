/// Model class for storing card transformation properties used in card swipe animations.
///
/// This class encapsulates the visual transform properties needed to create
/// smooth rolling animations between mailbox cards during swipe interactions.
class CardSwipeTransforms {
  /// Horizontal offset for card positioning
  final double offsetX;

  /// Vertical offset for card positioning
  final double offsetY;

  /// Scale factor for card size (0.0 to 1.0+)
  final double scale;

  /// Opacity level for card visibility (0.0 to 1.0)
  final double opacity;

  /// Rotation angle in radians
  final double rotation;

  const CardSwipeTransforms({
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.opacity,
    this.rotation = 0.0,
  });

  /// Creates a default transform with no modifications
  factory CardSwipeTransforms.identity() {
    return const CardSwipeTransforms(
      offsetX: 0.0,
      offsetY: 0.0,
      scale: 1.0,
      opacity: 1.0,
      rotation: 0.0,
    );
  }

  /// Creates a transform for rolling animation based on swipe progress
  factory CardSwipeTransforms.rolling({
    required double progress,
    required double cardWidth,
    required double cardSpacing,
  }) {
    return CardSwipeTransforms(
      offsetX: -progress * (cardWidth + cardSpacing),
      offsetY: 0.0,
      scale: 1.0,
      opacity: 1.0,
    );
  }

  /// Creates a transform with fade effect based on swipe progress
  factory CardSwipeTransforms.fade({
    required double progress,
    double maxOpacity = 1.0,
    double minOpacity = 0.0,
  }) {
    return CardSwipeTransforms(
      offsetX: 0.0,
      offsetY: 0.0,
      scale: 1.0,
      opacity: maxOpacity - (progress * (maxOpacity - minOpacity)),
    );
  }

  /// Creates a transform with scale effect based on swipe progress
  factory CardSwipeTransforms.scale({
    required double progress,
    double maxScale = 1.0,
    double minScale = 0.8,
  }) {
    return CardSwipeTransforms(
      offsetX: 0.0,
      offsetY: 0.0,
      scale: maxScale - (progress * (maxScale - minScale)),
      opacity: 1.0,
    );
  }

  /// Creates a transform with rotation effect based on swipe progress
  factory CardSwipeTransforms.rotate({
    required double progress,
    double maxRotation = 0.0,
    double minRotation = -0.1,
  }) {
    return CardSwipeTransforms(
      offsetX: 0.0,
      offsetY: 0.0,
      scale: 1.0,
      opacity: 1.0,
      rotation: maxRotation - (progress * (maxRotation - minRotation)),
    );
  }

  /// Creates a transform with combined effects (fade + scale + rotation)
  factory CardSwipeTransforms.combined({
    required double progress,
    double maxOpacity = 1.0,
    double minOpacity = 0.0,
    double maxScale = 1.0,
    double minScale = 0.8,
    double maxRotation = 0.0,
    double minRotation = -0.1,
  }) {
    return CardSwipeTransforms(
      offsetX: 0.0,
      offsetY: 0.0,
      scale: maxScale - (progress * (maxScale - minScale)),
      opacity: maxOpacity - (progress * (maxOpacity - minOpacity)),
      rotation: maxRotation - (progress * (maxRotation - minRotation)),
    );
  }

  @override
  String toString() =>
      'CardSwipeTransforms(offsetX: $offsetX, offsetY: $offsetY, scale: $scale, opacity: $opacity, rotation: $rotation)';
}
