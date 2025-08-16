import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:talkbase/pages/auth/login_page.dart';
import 'package:talkbase/pages/auth/signup.dart';
import 'package:talkbase/pages/chat/incoming_call_screen.dart';
import 'package:talkbase/pages/home.dart';
import 'package:talkbase/providers/theme_provider.dart';
import 'package:talkbase/widgets/auth_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // Note: Showing a full screen UI from a background isolate is complex.
  // A common approach is to show a high-priority notification that the user
  // can tap to open the app and see the incoming call screen.
}

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   debugPrint("Handling a background message: ${message.messageId}");
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground notification setup
  await setupForegroundNotifications();

  runApp(const MyApp());
}

// Setup for foreground notifications
Future<void> setupForegroundNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');

    // --- 1. Check if it's an INCOMING CALL ---
    if (message.data['type'] == 'INCOMING_CALL') {
      // Use the navigatorKey to show the IncomingCallScreen
      navigatorKey.currentState?.pushNamed(
        '/incoming_call',
        arguments: {
          'callerName': message.data['callerName'],
          'channelName': message.data['channelName'],
        },
      );
    }
    // --- 2. Otherwise, handle it as a regular notification ---
    else {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'launch_background',
            ),
          ),
        );
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ChatterBox',
            themeMode: themeProvider.themeMode,

            // Light Theme
            theme: ThemeData(
              brightness: Brightness.light,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: Colors.deepPurple,
                unselectedItemColor: Colors.grey[600],
                type: BottomNavigationBarType.fixed,
              ),
            ),

            // Dark Theme
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              // Add this part for the BottomNavigationBar
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                // The background will be dark automatically, but you can be explicit
                // backgroundColor: colorScheme.surface,
                selectedItemColor: Colors.purpleAccent, // A nice color for dark mode
                unselectedItemColor: Colors.grey[400], // Lighter grey for better contrast
                type: BottomNavigationBarType.fixed,
              ),
            ),

            initialRoute: '/',
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignUpPage(),
              '/home': (context) => const HomePage(),
              // '/incoming_call': (context) {
              //   final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              //   return IncomingCallScreen(
              //     callerName: args['callerName'],
              //     channelName: args['channelName'],
              //   );
              // },
            },
          );
        },
      ),
    );
  }
}
