import 'package:flutter/material.dart';

class CountUpAnimation extends StatefulWidget {
  final double startValue;
  final double endValue;
  final Duration duration;
  final TextStyle? textStyle;
  final String? prefix;
  final String? suffix;
  final int? decimalPlaces;
  final Curve curve;

  const CountUpAnimation({
    super.key,
    required this.startValue,
    required this.endValue,
    this.duration = const Duration(milliseconds: 1500),
    this.textStyle,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<CountUpAnimation> createState() => _CountUpAnimationState();
}

class _CountUpAnimationState extends State<CountUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.startValue,
      end: widget.endValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(CountUpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endValue != widget.endValue) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.endValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _controller.reset();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_hasStarted) {
      _hasStarted = true;
      // Add a small delay to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start animation after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStarted) {
        _startAnimation();
      }
    });

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final formattedValue = _formatValue(currentValue);
        
        return Text(
          '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}',
          style: widget.textStyle,
        );
      },
    );
  }

  String _formatValue(double value) {
    if (widget.decimalPlaces == 0) {
      return value.round().toString();
    } else {
      return value.toStringAsFixed(widget.decimalPlaces!);
    }
  }
}

class CountUpAnimationController {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _startValue = 0;
  double _endValue = 0;
  int? _decimalPlaces = 0;
  String? _prefix;
  String? _suffix;
  TextStyle? _textStyle;
  Curve _curve = Curves.easeOutCubic;

  CountUpAnimationController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    _controller = AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }

  void animateTo({
    required double endValue,
    double? startValue,
    int? decimalPlaces,
    String? prefix,
    String? suffix,
    TextStyle? textStyle,
    Curve? curve,
    Duration? duration,
  }) {
    _startValue = startValue ?? _animation.value;
    _endValue = endValue;
    _decimalPlaces = decimalPlaces ?? _decimalPlaces;
    _prefix = prefix ?? _prefix;
    _suffix = suffix ?? _suffix;
    _textStyle = textStyle ?? _textStyle;
    _curve = curve ?? _curve;

    _animation = Tween<double>(
      begin: _startValue,
      end: _endValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _curve,
    ));

    _controller.reset();
    _controller.forward();
  }

  Animation<double> get animation => _animation;
  AnimationController get controller => _controller;

  void dispose() {
    _controller.dispose();
  }
}
