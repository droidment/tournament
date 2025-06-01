import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/authentication/bloc/auth_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tournament Manager'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              PopupMenuButton(
                icon: CircleAvatar(
                  backgroundImage: state.userProfile?.avatarUrl != null
                      ? NetworkImage(state.userProfile!.avatarUrl!)
                      : null,
                  child: state.userProfile?.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => context.push('/profile'),
                    child: const Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () {
                      context.read<AuthBloc>().add(const AuthSignOutRequested());
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${state.userProfile?.fullName ?? state.user?.email ?? 'User'}!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your tournaments and teams from here.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        context,
                        title: 'Create Tournament',
                        icon: Icons.add_circle,
                        color: Colors.blue,
                        onTap: () => context.push('/tournaments/create'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'My Tournaments',
                        icon: Icons.sports_tennis,
                        color: Colors.green,
                        onTap: () => context.push('/tournaments'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Profile Settings',
                        icon: Icons.settings,
                        color: Colors.orange,
                        onTap: () => context.push('/profile'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Browse Tournaments',
                        icon: Icons.search,
                        color: Colors.purple,
                        onTap: () => context.push('/tournaments'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 