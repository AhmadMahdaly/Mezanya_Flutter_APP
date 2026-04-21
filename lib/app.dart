import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/app_shell/presentation/screens/main_shell_screen.dart';
import 'features/app_state/domain/entities/app_state_entity.dart';
import 'features/app_state/presentation/cubits/app_cubit.dart';

class MezanyaApp extends StatelessWidget {
  const MezanyaApp({
    super.key,
    required this.cubit,
  });

  final AppCubit cubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mezanya',
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.tactileManuscript(),
      home: StreamBuilder<AppStateEntity>(
        stream: cubit.stream,
        initialData: cubit.state,
        builder: (context, _) => MainShellScreen(cubit: cubit),
      ),
    );
  }
}

