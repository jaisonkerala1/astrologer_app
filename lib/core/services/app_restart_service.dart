import 'package:flutter/material.dart';

class AppRestartService {
  static final AppRestartService _instance = AppRestartService._internal();
  factory AppRestartService() => _instance;
  AppRestartService._internal();

  static _RestartWidgetState? _restartWidget;

  static void setRestartWidget(_RestartWidgetState widget) {
    _restartWidget = widget;
  }

  static void restartApp() {
    _restartWidget?.restartApp();
  }
}

class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  @override
  State<RestartWidget> createState() => _RestartWidgetState();

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  @override
  void initState() {
    super.initState();
    AppRestartService.setRestartWidget(this);
  }

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
