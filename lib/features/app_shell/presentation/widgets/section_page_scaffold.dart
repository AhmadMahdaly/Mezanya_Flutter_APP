import 'package:flutter/material.dart';

class SectionPageScaffold extends StatelessWidget {
  const SectionPageScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}
