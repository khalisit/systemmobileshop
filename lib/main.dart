import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kurd_localization/kurd_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'pages/dashboard_screen.dart';
import 'pages/login_screen.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Check if client is already initialized
    Supabase.instance.client;
  } catch (_) {
    await SupabaseConfig.init();
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'ئایتی سەنتەر - سیستەمی کۆگا و فرۆشتن',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: [
        ...kurdishLocalizations,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ckb')],
      locale: const Locale('ckb'),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: authState.isAuthenticated
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}
