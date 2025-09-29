import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'src/pages/create_edit_task_page.dart';
import 'src/pages/edit_profile_page.dart';
import 'src/pages/login_page.dart';
import 'src/pages/task_details_page.dart';
import 'src/pages/user_profile_page.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/task_provider.dart';

import 'src/pages/home_page.dart';

void main() {
  setPathUrlStrategy();
  runApp(const App());
}

// Instantiate providers outside of the widget tree to be accessible by the router
final _authProvider = AuthProvider();

final _router = GoRouter(
  refreshListenable: _authProvider, // Re-evaluate routes on auth changes
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
    ),
    GoRoute(
      path: '/task/new',
      pageBuilder: (context, state) => const NoTransitionPage(child: CreateEditTaskPage()),
    ),
    GoRoute(
      path: '/task/:id',
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['id']!;
        return NoTransitionPage(child: TaskDetailsPage(taskId: taskId));
      },
    ),
    GoRoute(
      path: '/task/:id/edit',
      pageBuilder: (context, state) => NoTransitionPage(child: CreateEditTaskPage(taskId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => const NoTransitionPage(child: UserProfilePage()),
    ),
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) => const NoTransitionPage(child: EditProfilePage()),
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = _authProvider.isLoggedIn;
    final location = state.matchedLocation;

    // Define protected routes
    final isGoingToLogin = location == '/login';
    final isGoingToProtected = location.startsWith('/profile') || location == '/task/new' || location.endsWith('/edit');

    // If not logged in and trying to access a protected route, redirect to login
    if (!isLoggedIn && isGoingToProtected) {
      return '/login';
    }

    // If logged in and trying to go to login page, redirect to home
    if (isLoggedIn && isGoingToLogin) {
      return '/';
    }

    // No redirect needed
    return null;
  },
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider.value(value: _authProvider),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Supply Task',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          textTheme: const TextTheme(
            bodySmall: TextStyle(fontSize: 14.0),
            bodyMedium: TextStyle(fontSize: 16.0),
            bodyLarge: TextStyle(fontSize: 18.0),
            titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          tabBarTheme: const TabBarThemeData(labelStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
        ),
        routerConfig: _router,
      ),
    );
  }
}
