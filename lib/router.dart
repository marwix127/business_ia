import 'package:business_ia/UI/pages/add_exercise_page.dart';
import 'package:business_ia/UI/pages/exercise_list_page.dart';
import 'package:business_ia/UI/widgets/main_scaffold.dart';
import 'package:business_ia/models/training.dart';
import 'package:go_router/go_router.dart';

import 'UI/pages/trainings_history_page.dart';
import 'UI/pages/login_page.dart';
import 'UI/pages/register_page.dart';
import 'infrastructure/services/firebase/auth_state_notifier.dart';
import 'UI/pages/ia_chat.dart';
import 'UI/pages/training_page.dart';
import 'UI/pages/exercises_categories.dart';
import 'UI/pages/exercises_by_categories.dart';
import 'UI/pages/grafics_page.dart';

late final GoRouter router;

GoRouter createRouter(AuthStateNotifier authState) {
  return GoRouter(
    refreshListenable: authState, // Se actualiza al cambiar el auth
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final loggingIn = state.uri.toString() == '/login';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LogInPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/training',
        builder: (context, state) {
          final training = state.extra as Training?;
          return TrainingPage(training: training);
        },
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => ExercisesCategories(),
      ),
      GoRoute(
        path: '/exercises-by-category',
        builder: (context, state) {
          final categoria = state.uri.queryParameters['categoria'] ?? '';
          return ExercisesByCategories(categoria: categoria);
        },
      ),

      GoRoute(
        path: '/add-exercise',
        builder: (context, state) => const AddExercisePage(),
      ),
      GoRoute(
        path: '/exercise-list',
        builder: (context, state) => const ExerciseListPage(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TrainingHistoryPage(),
          ),
          GoRoute(
            path: '/ia-chat',
            builder: (context, state) => const IAChatPage(),
          ),
          GoRoute(
            path: '/grafics',
            builder: (context, state) => const GraficsPage(),
          ),
        ],
      ),
    ],
  );
}



