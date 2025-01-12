import 'package:flutter/material.dart';
import 'dart:math';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class LineCompleteAnimation extends StatefulWidget {
  final int linesCleared;
  final VoidCallback onComplete;
  final double scale;

  const LineCompleteAnimation({
    super.key,
    required this.linesCleared,
    required this.onComplete,
    required this.scale,
  });

  @override
  State<LineCompleteAnimation> createState() => _LineCompleteAnimationState();
}

class _LineCompleteAnimationState extends State<LineCompleteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getLineText() {
    if (widget.linesCleared == 1) return 'Jostle!';
    if (widget.linesCleared == 2) return 'Double!';
    if (widget.linesCleared == 3) return 'Triple!';
    if (widget.linesCleared == 4) return 'Tetris!';
    return 'Clear!';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: GradientText(
                _getLineText(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.purple,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}