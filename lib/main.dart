import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/wishlist_provider.dart';
import 'services/db_platform/db_platform.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDatabaseFactory();

  runApp(const ShoppingHubApp());
}

class ShoppingHubApp extends StatelessWidget {
  const ShoppingHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => WishlistProvider())],
      child: MaterialApp(
        title: 'ShoppingHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
