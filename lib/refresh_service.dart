import 'package:flutter/material.dart';

class AnimatedSync extends AnimatedWidget {
  VoidCallback callback;
  AnimatedSync({Key? key, required Animation<double> animation, required this.callback})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return Transform.rotate(
      angle: animation.value,
      child: IconButton(
          icon: Icon(Icons.sync), // <-- Icon
          onPressed: () => callback()),
    );
  }
}

