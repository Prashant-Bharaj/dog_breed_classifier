import 'package:animator/animator.dart';
import 'package:flutter/material.dart';

class HeartAnimation extends StatelessWidget {
  final showHeart;

  HeartAnimation(this.showHeart);

  @override
  Widget build(BuildContext context) {
    return showHeart
        ? Animator(
            duration: Duration(milliseconds: 300),
            tween: Tween(begin: 0.8, end: 1.4),
            curve: Curves.elasticOut,
            cycles: 0,
            builder: (context, animatorState, child) => Center(
              child: Container(
                child: Icon(
                  Icons.favorite,
                  size: 80.0,
                  color: Colors.red,
                ),
              ),
            ),
          )
        : Text("");
  }
}
