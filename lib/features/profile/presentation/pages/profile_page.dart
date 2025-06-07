import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/authentication/bloc/auth_bloc.dart';
import 'package:teamapp3/features/profile/bloc/profile_bloc.dart';
import 'package:teamapp3/features/profile/bloc/profile_event.dart';
import 'package:teamapp3/features/profile/bloc/profile_state.dart';
import 'package:teamapp3/features/profile/presentation/widgets/my_tournaments_section.dart';
import 'package:teamapp3/features/profile/presentation/widgets/profile_header.dart';
import 'package:teamapp3/features/profile/presentation/widgets/profile_info_section.dart';
import 'package:teamapp3/features/profile/presentation/widgets/tournament_roles_section.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load profile data when page opens
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(userId));
      context.read<ProfileBloc>().add(MyTournamentsLoadRequested(userId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToEditProfile() {
    context.push('/profile/edit');
  }

  void _signOut() {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
            tooltip: 'Edit Profile',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sign_out') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sign_out',
                child: Row(
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.badge), text: 'Roles'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Tournaments'),
          ],
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.profile == null) {
            return const Center(
              child: Text('No profile data available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final userId = context.read<AuthBloc>().state.user?.id;
              if (userId != null) {
                context.read<ProfileBloc>().add(ProfileRefreshRequested(userId));
              }
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                // Profile Tab
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ProfileHeader(profile: state.profile!),
                      const SizedBox(height: 24),
                      ProfileInfoSection(profile: state.profile!),
                    ],
                  ),
                ),
                // Roles Tab
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: TournamentRolesSection(profile: state.profile!),
                ),
                // Tournaments Tab
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: MyTournamentsSection(
                    tournaments: state.myTournaments,
                    profile: state.profile!,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 