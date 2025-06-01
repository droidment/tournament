import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamapp3/core/router/app_router.dart';
import 'package:teamapp3/features/authentication/bloc/auth_bloc.dart';
import 'package:teamapp3/features/authentication/data/repositories/auth_repository.dart';
import 'package:teamapp3/features/profile/bloc/profile_bloc.dart';
import 'package:teamapp3/features/profile/data/repositories/profile_repository.dart';
import 'package:teamapp3/features/tournaments/bloc/resource_bloc.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_resource_repository.dart';
import 'package:teamapp3/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider(
          create: (context) => ProfileRepository(),
        ),
        RepositoryProvider(
          create: (context) => TournamentResourceRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ResourceBloc(
              resourceRepository: context.read<TournamentResourceRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final authBloc = context.read<AuthBloc>();
            return MaterialApp.router(
              title: 'Tournament Manager',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
                useMaterial3: true,
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: AppRouter.router(authBloc: authBloc),
            );
          },
        ),
      ),
    );
  }
}
