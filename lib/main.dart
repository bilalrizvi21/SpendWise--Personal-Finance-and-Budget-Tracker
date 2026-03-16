import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Services/database_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ Run ONCE to reset old DB schema, then comment out
  //await DatabaseService.instance.deleteDatabase();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SpendWiseApp());
}
