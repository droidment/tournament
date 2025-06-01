import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/tournament_bloc.dart';
import '../../bloc/tournament_event.dart';
import '../../bloc/tournament_state.dart';
import '../../data/models/tournament_model.dart';

class TournamentManagementPage extends StatefulWidget {
  const TournamentManagementPage({super.key});

  @override
  State<TournamentManagementPage> createState() => _TournamentManagementPageState();
}

class _TournamentManagementPageState extends State<TournamentManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<TournamentBloc>().add(const UserTournamentsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tournaments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/tournaments/create'),
          ),
        ],
      ),
      body: BlocBuilder<TournamentBloc, TournamentState>(
        builder: (context, state) {
          if (state.status == TournamentBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TournamentBlocStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tournaments',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(state.errorMessage ?? 'Unknown error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TournamentBloc>().add(
                          const UserTournamentsLoadRequested(),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.tournaments.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.tournaments.length,
            itemBuilder: (context, index) {
              final tournament = state.tournaments[index];
              return _buildTournamentCard(tournament);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/tournaments/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tournaments yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first tournament to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/tournaments/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create Tournament'),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tournament.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(tournament.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(tournament.startDate)} - ${_formatDate(tournament.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.sports, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getFormatDisplayName(tournament.format),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.category,
                  label: 'Categories',
                  onPressed: () => context.go(
                    '/tournaments/${tournament.id}/categories?name=${Uri.encodeComponent(tournament.name)}',
                  ),
                ),
                _buildActionButton(
                  icon: Icons.group,
                  label: 'Teams',
                  onPressed: () => context.go(
                    '/tournaments/${tournament.id}/teams?name=${Uri.encodeComponent(tournament.name)}',
                  ),
                ),
                _buildActionButton(
                  icon: Icons.location_on,
                  label: 'Resources',
                  onPressed: () => context.go(
                    '/tournaments/${tournament.id}/resources?name=${Uri.encodeComponent(tournament.name)}',
                  ),
                ),
                _buildActionButton(
                  icon: Icons.schedule,
                  label: 'Schedule',
                  onPressed: () => context.go(
                    '/tournaments/${tournament.id}/schedule?name=${Uri.encodeComponent(tournament.name)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TournamentStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case TournamentStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case TournamentStatus.registration:
        color = Colors.blue;
        label = 'Registration';
        break;
      case TournamentStatus.inProgress:
        color = Colors.green;
        label = 'In Progress';
        break;
      case TournamentStatus.completed:
        color = Colors.purple;
        label = 'Completed';
        break;
      case TournamentStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getFormatDisplayName(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.roundRobin:
        return 'Round Robin';
      case TournamentFormat.singleElimination:
        return 'Single Elimination';
      case TournamentFormat.doubleElimination:
        return 'Double Elimination';
      case TournamentFormat.swiss:
        return 'Swiss System';
      case TournamentFormat.custom:
        return 'Custom';
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 