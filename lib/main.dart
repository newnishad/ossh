import 'package:flutter/material.dart';
import 'ssh_profiles.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSSH',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SshProfiles(),
    );
  }

}
