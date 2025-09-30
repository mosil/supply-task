import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'firebase_options.dart';
import 'src/pages/create_edit_task_page.dart';
import 'src/pages/edit_profile_page.dart';
import 'src/pages/login_page.dart';
import 'src/pages/my_tasks_page.dart';
import 'src/pages/task_details_page.dart';
import 'src/pages/user_profile_page.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/project_provider.dart';
import 'src/providers/task_provider.dart';
import 'src/providers/task_type_provider.dart';

import 'src/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setPathUrlStrategy();

  // Instantiate providers outside of the widget tree to be accessible by the router
  final _authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskTypeProvider()),
        ChangeNotifierProxyProvider<ProjectProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (context, projectProvider, previousTaskProvider) {
            previousTaskProvider?.updateProject(projectProvider.currentProjectId);
            return previousTaskProvider ?? TaskProvider();
          },
        ),
      ],
      child: MyApp(router: _createRouter(_authProvider)),
    ),
  );
}

GoRouter _createRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
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
      GoRoute(
        path: '/my-tasks/:type',
        pageBuilder: (context, state) {
          final typeString = state.pathParameters['type']!;
          final type = MyTasksType.values.firstWhere((e) => e.name == typeString);
          return NoTransitionPage(
            child: MyTasksPage(type: type),
          );
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final location = state.matchedLocation;

      final isGoingToLogin = location == '/login';
      final isGoingToProtected = location.startsWith('/profile') || location == '/task/new' || location.endsWith('/edit');

      if (!isLoggedIn && isGoingToProtected) {
        return '/login';
      }

      if (isLoggedIn && authProvider.isNewUser && location != '/profile/edit') {
        return '/profile/edit';
      }

      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }

      return null;
    },
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF264653), // Desaturated Dark Blue-Green
      onPrimary: Colors.white,
      secondary: Color(0xFF4A6363),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFFF5F5F5), // Light Greyish White
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
    );

    return MaterialApp.router(
      title: 'Supply Task',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.secondary, width: 2.0),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          hintStyle: TextStyle(color: Colors.grey.shade700),
        ),
      ),
      routerConfig: router,
    );
  }
}
