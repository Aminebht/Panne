import 'package:flutter/material.dart';

class SpinningImage extends StatefulWidget {
  @override
  _SpinningImageState createState() => _SpinningImageState();
}

class _SpinningImageState extends State<SpinningImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Container(
        height: 25.0,
        width: 25.0,
        child: Image.asset('assets/logos/wheel.png'),
      ),
      builder: (BuildContext context, Widget? _widget) {
        return Transform.rotate(
          angle: _controller.value * 6.28,
          child: _widget,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
