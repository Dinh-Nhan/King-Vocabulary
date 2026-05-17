import 'package:flutter/material.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';
import 'package:king_vocabulary/features/auth/screens/login_screen.dart';
import 'package:king_vocabulary/features/auth/services/auth_service.dart';
import 'package:king_vocabulary/features/home/screens/home_screen.dart';

// Global RouteObserver để track navigation
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Tạo authService một lần duy nhất
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'King Vocabulary',
      theme: buildKingVocabularyTheme(), // ← thêm dòng này
      navigatorObservers: [routeObserver], // ← Thêm observer
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          print(
            '🔄 StreamBuilder rebuild - ConnectionState: ${snapshot.connectionState}',
          );
          print(
            '🔄 Has data: ${snapshot.hasData}, User: ${snapshot.data?.email}',
          );

          // Đang kiểm tra trạng thái
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Có user → vào HomeScreen
          if (snapshot.hasData) {
            print('✅ Chuyển sang HomeScreen');
            return HomeScreen();
          }

          // Không có user → vào LoginScreen
          print('🔵 Hiển thị LoginScreen');
          return const LoginScreen();
        },
      ),
    );
  }
}
