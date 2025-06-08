import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkbase/pages/auth/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'pages/landing_page.dart';
import 'pages/auth/login_register_page.dart';
import 'pages/chat/chat_room_list_page.dart';
import 'core/services/chat_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider())
        // ProxyProvider<AuthProvider, ChatProvider>(
        //   update: (context, auth, previous) {
        //     final token = auth.token ?? '';
        //     final tenant = auth.tenant ?? '';
        //     final chatService = ChatService(token, tenant);
        //     return ChatProvider(chatService);
        //   },
        // ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ChatterBox',
            theme: ThemeData(
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            initialRoute: '/',
            routes: {
              '/': (context) =>
              auth.isLoggedIn ? const ChatRoomListPage() : const LandingPage(),
              '/login': (context) => const LoginPage(),
              '/chat': (context) => const ChatRoomListPage(),
            },
          );
        },
      ),
    );
  }
}
