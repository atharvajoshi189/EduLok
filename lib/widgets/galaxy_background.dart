import 'package:flutter/material.dart';

class GalaxyBackground extends StatelessWidget {
  final Widget child;
  const GalaxyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/galaxy_background.jpg'),
          fit: BoxFit.cover, // Poori screen cover karega
        ),
      ),
      child: child,
    );
  }
}