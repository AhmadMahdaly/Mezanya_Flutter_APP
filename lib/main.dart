import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cubit = await AppBootstrap.initialize();
  runApp(MezanyaApp(cubit: cubit));
}
