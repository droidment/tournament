import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/authentication/bloc/auth_bloc.dart';
import 'package:teamapp3/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:teamapp3/features/authentication/presentation/pages/sign_up_page.dart';
import 'package:teamapp3/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:teamapp3/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:teamapp3/features/profile/presentation/pages/profile_page.dart';
import 'package:teamapp3/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/create_tournament_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/tournament_categories_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/tournament_teams_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/tournament_management_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/tournament_resources_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/tournament_schedule_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/tournament_analytics_page.dart';
import 'package:teamapp3/features/tournaments/presentation/pages/tournament_bracket_page.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/category_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/team_bloc.dart';

// Placeholder pages with back buttons
class TournamentsPage extends StatelessWidget {
  const TournamentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tournaments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Tournaments Page',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class TournamentDetailsPage extends StatelessWidget {
  final String tournamentId;
  
  const TournamentDetailsPage({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tournament Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tournament ID: $tournamentId',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static GoRouter router({required AuthBloc authBloc}) {
    return GoRouter(
      initialLocation: '/sign-in',
      routes: [
        // Authentication routes
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        
        // Dashboard route (protected)
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        
        // Tournament routes (protected)
        GoRoute(
          path: '/tournaments',
          builder: (context, state) => BlocProvider(
            create: (context) => TournamentBloc(),
            child: const TournamentManagementPage(),
          ),
        ),
        GoRoute(
          path: '/tournaments/create',
          builder: (context, state) => BlocProvider(
            create: (context) => TournamentBloc(),
            child: const CreateTournamentPage(),
          ),
        ),
        GoRoute(
          path: '/tournaments/:id/categories',
          builder: (context, state) {
            final tournamentId = state.pathParameters['id']!;
            final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
            return BlocProvider(
              create: (context) => CategoryBloc(),
              child: TournamentCategoriesPage(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
              ),
            );
          },
        ),
        GoRoute(
          path: '/tournaments/:id/teams',
          builder: (context, state) {
            final tournamentId = state.pathParameters['id']!;
            final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => TeamBloc()),
                BlocProvider(create: (context) => CategoryBloc()),
              ],
              child: TournamentTeamsPage(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
              ),
            );
          },
        ),
        GoRoute(
          path: '/tournaments/:id/resources',
          builder: (context, state) {
            final tournamentId = state.pathParameters['id']!;
            final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
            return TournamentResourcesPage(
              tournamentId: tournamentId,
              tournamentName: tournamentName,
            );
          },
        ),
        GoRoute(
          path: '/tournaments/:id/schedule',
          builder: (context, state) {
            final tournamentId = state.pathParameters['id']!;
            final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
            return TournamentSchedulePage(
              tournamentId: tournamentId,
              tournamentName: tournamentName,
            );
          },
        ),
        GoRoute(
          path: '/tournaments/:id/analytics',
          builder: (context, state) {
            final tournamentId = state.pathParameters['id']!;
            final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
            return TournamentAnalyticsPage(
              tournamentId: tournamentId,
              tournamentName: tournamentName,
            );
          },
        ),
        GoRoute(
          path: '/tournaments/:id/bracket',
          builder: (context, state) {
            final tournamentId = state.pathParameters['id']!;
            final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
            return TournamentBracketPage(
              tournamentId: tournamentId,
              tournamentName: tournamentName,
            );
          },
        ),
        GoRoute(
          path: '/tournaments/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TournamentDetailsPage(tournamentId: id);
          },
        ),
        
        // Profile routes (protected)
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfilePage(),
        ),
      ],
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState.status == AuthStatus.authenticated;
        final isGoingToAuth = state.uri.toString().startsWith('/sign-') || 
                              state.uri.toString().startsWith('/forgot-');

        // If not authenticated and trying to access protected route
        if (!isAuthenticated && !isGoingToAuth) {
          return '/sign-in';
        }

        // If authenticated and trying to access auth routes
        if (isAuthenticated && isGoingToAuth) {
          return '/dashboard';
        }

        return null; // No redirect needed
      },
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Extension for stream subscription
extension on Stream<dynamic> {
  StreamSubscription<dynamic> listen(void Function(dynamic) onData) {
    return listen(onData);
  }
} 