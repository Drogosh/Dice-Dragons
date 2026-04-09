import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../character_selection_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLogin = true; // true - login, false - signup

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Загрузка
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Проверяем авторизацию
        if (snapshot.hasData && snapshot.data != null) {
          // Пользователь авторизован - показываем выбор персонажа
          return const CharacterSelectionScreen();
        } else {
          // Пользователь не авторизован - показываем Auth экраны
          return _buildAuthScreen();
        }
      },
    );
  }


  Widget _buildAuthScreen() {
    if (_isLogin) {
      return LoginScreen(
        onLoginSuccess: () {
          // При успешном входе StreamBuilder перестроится
        },
        onSignupTap: () {
          setState(() => _isLogin = false);
        },
      );
    } else {
      return SignupScreen(
        onSignupSuccess: () {
          // При успешной регистрации StreamBuilder перестроится
        },
        onLoginTap: () {
          setState(() => _isLogin = true);
        },
      );
    }
  }
}


