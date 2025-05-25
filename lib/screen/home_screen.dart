import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grocery Billing System'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Go to Billing'),
          onPressed: () {
            Navigator.pushNamed(context, '/billing');
          },
        ),
      ),
    );
  }
}