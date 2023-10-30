import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_frame/flutter_web_frame.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quotes_app/views/templates/splash_page_template.dart';
import 'package:quotes_app/views/themes/theme.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  // String supabaseUrl = dotenv.get('SUPABASE_URL');
  // String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');
  tz.initializeTimeZones();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterWebFrame(
      maximumSize: const Size(390, double.infinity),
      builder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quotes App',
          themeMode: ThemeMode.dark,
          darkTheme: MyTheme.darkTheme,
          theme: MyTheme.darkTheme,
          home: const SplashPage(),
        );
      },
    );
  }
}
