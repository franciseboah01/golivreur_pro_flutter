import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/commercant_provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'utils/app_transitions.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/commercant/home_commercant.dart';

void main() {
  runApp(const GoLivreurProApp());
}

class GoLivreurProApp extends StatelessWidget {
  const GoLivreurProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CommercantProvider()),
      ],
      child: MaterialApp(
        title: 'GoLivreur Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(redirectRole: 'commercant', redirectRoute: '/home'),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return AppTransitions.fadeScale(const LoginScreen(
                redirectRole: 'commercant',
                redirectRoute: '/home',
              ));
            case '/register':
              return AppTransitions.slideUp(const RegisterScreen());
            case '/home':
              return AppTransitions.fadeScale(const HomeCommercant());
            default:
              return AppTransitions.slideRight(const HomeCommercant());
          }
        },
      ),
    );
  }
}