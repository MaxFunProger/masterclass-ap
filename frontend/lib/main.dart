import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/core/analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Analytics.init();
  runApp(const MasterclassesApp());
}
