import 'package:botovod/SelectorView.dart';
import 'package:botovod/DrawingView.dart';
import 'package:flutter/material.dart';

void main() {


  runApp(MaterialApp(
    theme: ThemeData(
      primaryColor: Colors.blueAccent,
      backgroundColor: Colors.lightBlueAccent[100],
    ),
    initialRoute: '/',
    routes: {
      '/': (context) => SelectorView(),
      '/canvas': (context) => DrawingView(),
    },
  ));
}
