import 'package:flutter/material.dart';
import 'package:grocery_billing_system/screen/billing_page.dart';

void main() {
  runApp(GroceryBillingApp());
}

class GroceryBillingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Billing System',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: Colors.teal,                     // Primary accent color
        scaffoldBackgroundColor: Colors.teal,    // App background color
        cardColor: Color(0xFF1E1E1E),                   // Card or container background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyLarge: TextStyle(color: Colors.white),    // For general text
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.tealAccent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2C2C2C),
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: BillingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
