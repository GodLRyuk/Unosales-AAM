import 'package:flutter/material.dart';

class GlowingText extends StatefulWidget {
  final String text;
  final double fontSize;

  const GlowingText({Key? key, required this.text, required this.fontSize})
      : super(key: key);

  @override
  _GlowingTextState createState() => _GlowingTextState();
}

class _GlowingTextState extends State<GlowingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double glow = 5 + (_controller.value * 15);
        return Text(
          widget.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.fontSize,
            shadows: [
              Shadow(blurRadius: glow, color: Colors.white),
              Shadow(blurRadius: glow * 2, color: Colors.purpleAccent),
            ],
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
