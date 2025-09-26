# Skeleton Loader Components

A beautiful, minimal theme-compatible skeleton loader system for Flutter applications. These components provide smooth loading animations that automatically adapt to your app's theme (light/dark mode).

## Features

- 🎨 **Theme Compatible**: Automatically adapts to light and dark themes
- ✨ **Beautiful Animations**: Smooth shimmer effects with customizable timing
- 🔧 **Highly Customizable**: Support for custom colors, durations, and shapes
- 📱 **Responsive**: Works seamlessly across different screen sizes
- 🚀 **Performance Optimized**: Efficient animations with proper disposal
- 🎯 **Element-by-Element**: Individual skeleton loaders for different UI components

## Components

### Core Components

#### `SkeletonLoader`
The base skeleton loader component with shimmer animation.

```dart
SkeletonLoader(
  width: 200,
  height: 20,
  borderRadius: BorderRadius.circular(4),
)
```

#### `SkeletonText`
Multi-line text skeleton with customizable line count and spacing.

```dart
SkeletonText(
  lines: 3,
  height: 16,
  spacing: 8,
)
```

#### `SkeletonCircle`
Circular skeleton loader for avatars and circular elements.

```dart
SkeletonCircle(size: 40)
```

### Specialized Components

#### `SkeletonCard`
Card-like skeleton with proper padding and styling.

```dart
SkeletonCard(
  children: [
    SkeletonText(lines: 2),
    SizedBox(height: 16),
    SkeletonLoader(width: 100, height: 20),
  ],
)
```

#### `SkeletonStatCard`
Pre-built skeleton for statistics cards.

```dart
SkeletonStatCard()
```

#### `SkeletonConsultationCard`
Specialized skeleton for consultation cards.

```dart
SkeletonConsultationCard()
```

#### `SkeletonListItem`
List item skeleton with optional avatar.

```dart
SkeletonListItem(
  showAvatar: true,
  textLines: 2,
)
```

#### `SkeletonButton`
Button-shaped skeleton loader.

```dart
SkeletonButton(
  width: 120,
  height: 40,
)
```

#### `SkeletonImage`
Image placeholder skeleton.

```dart
SkeletonImage(
  width: 200,
  height: 150,
)
```

#### `SkeletonChart`
Chart/graph placeholder skeleton.

```dart
SkeletonChart(
  width: 300,
  height: 200,
)
```

## Usage Examples

### Basic Usage

```dart
// Simple text skeleton
SkeletonLoader(
  width: 150,
  height: 16,
)

// Multi-line text
SkeletonText(
  lines: 3,
  height: 14,
  spacing: 6,
)

// Circular avatar
SkeletonCircle(size: 50)
```

### Customization

```dart
SkeletonLoader(
  width: 200,
  height: 20,
  borderRadius: BorderRadius.circular(8),
  baseColor: Colors.grey[300],
  highlightColor: Colors.grey[100],
  duration: Duration(milliseconds: 2000),
  curve: Curves.easeInOut,
)
```

### Integration with Loading States

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool _isLoading = true;
  List<Data> _data = [];

  @override
  Widget build(BuildContext context) {
    return _isLoading 
        ? _buildSkeletonContent()
        : _buildRealContent();
  }

  Widget _buildSkeletonContent() {
    return Column(
      children: [
        SkeletonText(lines: 2),
        SizedBox(height: 16),
        ...List.generate(5, (index) => 
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonListItem(),
          ),
        ),
      ],
    );
  }

  Widget _buildRealContent() {
    return Column(
      children: _data.map((item) => 
        ListTile(
          title: Text(item.title),
          subtitle: Text(item.subtitle),
        ),
      ).toList(),
    );
  }
}
```

## Consultation Analytics Integration

For the consultation analytics module, specialized skeleton loaders are available:

```dart
// Weekly analytics skeleton
WeeklyAnalyticsSkeleton()

// Monthly analytics skeleton  
MonthlyAnalyticsSkeleton()

// All-time analytics skeleton
AllTimeAnalyticsSkeleton()

// Complete analytics screen skeleton
ConsultationAnalyticsScreenSkeleton()
```

## Theme Integration

The skeleton loaders automatically integrate with your app's theme service:

```dart
Consumer<ThemeService>(
  builder: (context, themeService, child) {
    return SkeletonLoader(
      // Colors automatically adapt to theme
      // baseColor and highlightColor are optional
    );
  },
)
```

## Best Practices

1. **Match Real Content**: Design skeleton loaders to match the layout of your actual content
2. **Appropriate Timing**: Use reasonable animation durations (1-2 seconds)
3. **Theme Consistency**: Let the skeleton loaders use automatic theme colors
4. **Performance**: Dispose of animations properly when widgets are destroyed
5. **Accessibility**: Ensure skeleton loaders don't interfere with screen readers

## Customization Options

### Colors
- `baseColor`: Base color of the skeleton (defaults to theme-appropriate gray)
- `highlightColor`: Highlight color for the shimmer effect

### Animation
- `duration`: Animation duration (default: 1500ms)
- `curve`: Animation curve (default: Curves.easeInOut)

### Shape
- `borderRadius`: Border radius for rounded corners
- `width`/`height`: Dimensions of the skeleton

## Demo

Use `SkeletonDemoScreen` to see all components in action:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SkeletonDemoScreen(),
  ),
);
```

## Performance Notes

- Skeleton loaders use `SingleTickerProviderStateMixin` for efficient animations
- Animations are automatically disposed when widgets are destroyed
- The shimmer effect is optimized for smooth performance
- Use `const` constructors where possible for better performance

## Troubleshooting

### Common Issues

1. **Animation not starting**: Ensure the widget is mounted before starting animations
2. **Theme colors not updating**: Make sure you're using `Consumer<ThemeService>`
3. **Performance issues**: Check for proper animation disposal and avoid too many simultaneous animations

### Debug Mode

Enable debug mode to see skeleton loader boundaries:

```dart
SkeletonLoader(
  // ... other properties
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.red, width: 1),
    ),
  ),
)
```

## Contributing

When adding new skeleton components:

1. Follow the existing naming conventions
2. Ensure theme compatibility
3. Add proper documentation
4. Include usage examples
5. Test with different themes and screen sizes

## License

This skeleton loader system is part of the astrologer app project and follows the same licensing terms.
