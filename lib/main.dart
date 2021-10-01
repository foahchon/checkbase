import 'package:flutter/material.dart';

import 'package:checkbase/screens/all_checklists_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    navigatorObservers: [routeObserver],
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AllChecklistsScreen()
    );
  }
}