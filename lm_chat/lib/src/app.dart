import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routing/app_router.dart';

class LmChatApp extends StatelessWidget {
  const LmChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'LM Chat',
      locale: const Locale('pl'),
      supportedLocales: const [Locale('pl')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.white,
          onPrimary: Colors.black,
          primaryContainer: const Color(0xFF444654),
          onPrimaryContainer: Colors.white,
          secondary: const Color(0xFF565869),
          onSecondary: Colors.white,
          tertiary: const Color(0xFF565869),
          onTertiary: Colors.white,
          surface: const Color(0xFF1A1A1A), 
          onSurface: Colors.white,
          surfaceContainer: const Color(0xFF2A2A2A),
          surfaceContainerHigh: const Color(
            0xFF40414F,
          ),
          surfaceContainerHighest: const Color(0xFF353540),
          onSurfaceVariant: const Color(0xFF999AA5),
          outline: const Color(0xFF4F5263),
          outlineVariant: const Color(0xFF353540),
          error: Colors.red.shade300,
          onError: Colors.black,
          errorContainer: Colors.red.shade900,
          onErrorContainer: Colors.red.shade200,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
