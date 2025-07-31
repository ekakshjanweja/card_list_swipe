# Card List Swipe

A Flutter package that provides a horizontally scrollable stack of dismissible cards with rolling animation effects, perfect for mailbox-style interfaces and modern card-based UIs.

## Features

- **Horizontal Card Stack**: Smoothly scrollable stack of cards with custom spacing
- **Swipe-to-Dismiss**: Swipe cards up to dismiss them with smooth animations
- **Rolling Animations**: Cards automatically reposition with rolling effects when others are dismissed
- **Customizable Animations**: Full control over animation duration, curves, and physics
- **Snap Scrolling**: Optional snap-to-card behavior for precise positioning
- **Custom Transforms**: Advanced transform callbacks for custom animation effects
- **Progress Tracking**: Real-time swipe progress updates
- **Cascade Effects**: Cards respond to each other's movements for realistic physics
- **Performance Optimized**: Efficient rendering with ValueNotifier-based updates

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  card_list_swipe: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:card_list_swipe/card_list_swipe.dart';

CardSwipe(
  itemCount: 10,
  itemBuilder: (context, index) {
    return CustomCard(
      title: 'Card ${index + 1}',
      color: Colors.blue,
    );
  },
  onUpdate: (cardIndex, progress) {
    print('Card $cardIndex: ${(progress * 100).toStringAsFixed(1)}%');
  },
  onSwipe: (cardIndex) {
    print('Card $cardIndex dismissed!');
  },
  cardWidth: 300,
)
```

## Basic Usage

### Simple Card List

```dart
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Card Swipe Demo')),
      body: CardSwipe(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.primaries[index % Colors.primaries.length],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Card ${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        onUpdate: (cardIndex, progress) {
          // Handle swipe progress updates
          print('Card $cardIndex progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
        onSwipe: (cardIndex) {
          // Handle card dismissal
          print('Card $cardIndex was dismissed!');
        },
        cardWidth: MediaQuery.of(context).size.width * 0.8,
      ),
    );
  }
}
```

## Advanced Usage

### Custom Animations and Physics

```dart
CardSwipe(
  itemCount: 10,
  itemBuilder: (context, index) => CustomCard(index: index),
  onUpdate: (cardIndex, progress) {
    // Custom progress handling
  },
  onSwipe: (cardIndex) {
    // Custom dismissal handling
  },
  cardWidth: 300,
  cardSpacing: 20,
  padding: EdgeInsets.symmetric(horizontal: 16),
  cardAnimationDuration: Duration(milliseconds: 400),
  cardAnimationCurve: Curves.easeOutBack,
  springPhysics: SpringDescription(
    mass: 0.1,
    stiffness: 150.0,
    damping: 15.0,
  ),
  enableSnapping: true,
)
```

### Custom Transform Callbacks

```dart
CardSwipe(
  itemCount: 5,
  itemBuilder: (context, index) => CustomCard(index: index),
  onUpdate: (cardIndex, progress) {},
  onSwipe: (cardIndex) {},
  cardWidth: 300,
  customTransformCallback: (cardIndex, baseTransforms, swipeProgress, removedCards, cardWidth, cardSpacing) {
    // Custom transform logic
    if (cardIndex == 0 && swipeProgress > 0) {
      return CardSwipeTransforms.combined(
        progress: swipeProgress,
        maxOpacity: 1.0,
        minOpacity: 0.3,
        maxScale: 1.0,
        minScale: 0.8,
        maxRotation: 0.0,
        minRotation: -0.2,
      );
    }
    return null; // Use default behavior
  },
)
```

## API Reference

### CardSwipe

The main widget for creating swipeable card lists.

#### Required Parameters

- `itemBuilder`: Function that builds each card widget
- `itemCount`: Total number of cards to display
- `onUpdate`: Callback for swipe progress updates
- `onSwipe`: Callback when a card is dismissed
- `cardWidth`: Width of each card

#### Optional Parameters

- `padding`: Horizontal padding around the card list (default: `EdgeInsets.symmetric(horizontal: 16)`)
- `cardSpacing`: Space between cards (default: `16`)
- `cardAnimationDuration`: Duration for card animations (default: `Duration(milliseconds: 300)`)
- `cardAnimationCurve`: Animation curve for card movements (default: `Curves.easeOutCubic`)
- `springPhysics`: Spring physics for scroll behavior
- `scrollPhysics`: Custom scroll physics (overrides default)
- `enableSnapping`: Whether to snap to card positions (default: `false`)
- `customTransformCallback`: Advanced transform control

### CardSwipeTransforms

Utility class for creating custom transform effects.

#### Factory Constructors

- `CardSwipeTransforms.identity()`: No transformations
- `CardSwipeTransforms.rolling()`: Rolling animation effect
- `CardSwipeTransforms.fade()`: Fade in/out effect
- `CardSwipeTransforms.scale()`: Scale effect
- `CardSwipeTransforms.rotate()`: Rotation effect
- `CardSwipeTransforms.combined()`: Combined effects

#### Properties

- `offsetX`: Horizontal offset
- `offsetY`: Vertical offset
- `scale`: Scale factor (0.0 to 1.0+)
- `opacity`: Opacity level (0.0 to 1.0)
- `rotation`: Rotation angle in radians

### CardSwipeSnapScrollPhysics

Custom scroll physics for snap-to-card behavior.

#### Parameters

- `cardWidth`: Width of each card
- `cardSpacing`: Space between cards
- `horizontalPadding`: Horizontal padding
- `totalCardCount`: Total number of cards
- `springPhysics`: Spring physics configuration
- `enableSnapping`: Whether snapping is enabled

## Examples

### Mailbox-Style Interface

```dart
CardSwipe(
  itemCount: emails.length,
  itemBuilder: (context, index) {
    final email = emails[index];
    return EmailCard(
      subject: email.subject,
      sender: email.sender,
      preview: email.preview,
      timestamp: email.timestamp,
    );
  },
  onUpdate: (cardIndex, progress) {
    // Update UI based on swipe progress
    if (progress > 0.5) {
      // Show delete confirmation
    }
  },
  onSwipe: (cardIndex) {
    // Remove email from list
    setState(() {
      emails.removeAt(cardIndex);
    });
  },
  cardWidth: MediaQuery.of(context).size.width * 0.9,
  enableSnapping: true,
)
```

### Photo Gallery with Swipe

```dart
CardSwipe(
  itemCount: photos.length,
  itemBuilder: (context, index) {
    return PhotoCard(
      imageUrl: photos[index].url,
      caption: photos[index].caption,
    );
  },
  onSwipe: (cardIndex) {
    // Archive or delete photo
    archivePhoto(photos[cardIndex]);
  },
  cardWidth: 350,
  cardSpacing: 12,
  customTransformCallback: (cardIndex, baseTransforms, swipeProgress, removedCards, cardWidth, cardSpacing) {
    // Add parallax effect
    return CardSwipeTransforms(
      offsetX: baseTransforms.offsetX,
      offsetY: baseTransforms.offsetY,
      scale: baseTransforms.scale * (1.0 - swipeProgress * 0.1),
      opacity: baseTransforms.opacity,
      rotation: swipeProgress * 0.1, // Slight rotation on swipe
    );
  },
)
```

## Performance Tips

1. **Use const constructors** for static widgets in your `itemBuilder`
2. **Keep card widgets lightweight** - avoid expensive operations in build methods
3. **Use `enableSnapping: false`** if you don't need precise card positioning
4. **Limit `itemCount`** to reasonable numbers (typically < 100)
5. **Optimize custom transforms** - avoid complex calculations in transform callbacks

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.
