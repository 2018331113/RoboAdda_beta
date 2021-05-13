import 'package:flutter/material.dart';

class NoInternetConnection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ListView(
        children: [
          Image.asset(
            'images/connectionLost.png',
          )
        ],
      ),
    );
  }
}
