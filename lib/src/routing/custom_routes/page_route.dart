import 'package:flutter/material.dart';

class TPageRoute {
  static Future<T?> pageRoute<T>(
      BuildContext context,
      int durationInMS,
      Widget className,
      ) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        transitionDuration: Duration(milliseconds: durationInMS),
        pageBuilder: (context, animation, secondaryAnimation) => className,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Add your custom transition here
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}