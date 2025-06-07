import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_event.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_state.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';

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
      body: BlocListener<TournamentBloc, TournamentState>(
        listener: (context, state) {
          if (state.status == TournamentBlocStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Unknown error'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: BlocBuilder<TournamentBloc, TournamentState>(
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
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditTournament(tournament);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(tournament);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  onPressed: () => context.go(
                    '/tournaments/${tournament.id}/analytics?name=${Uri.encodeComponent(tournament.name)}',
                  ),
                ),
                _buildActionButton(
                  icon: Icons.account_tree,
                  label: 'Bracket',
                  onPressed: () => context.go(
                    '/tournaments/${tournament.id}/bracket?name=${Uri.encodeComponent(tournament.name)}',
                  ),
                ),
                // Add empty placeholder for symmetry
                const SizedBox(width: 70),
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
      case TournamentStatus.registration:
        color = Colors.blue;
        label = 'Registration';
      case TournamentStatus.inProgress:
        color = Colors.green;
        label = 'In Progress';
      case TournamentStatus.completed:
        color = Colors.purple;
        label = 'Completed';
      case TournamentStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
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
      case TournamentFormat.tiered:
        return 'Tiered Tournament';
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

  void _showEditTournament(TournamentModel tournament) {
    // Navigate to edit tournament page
    context.go('/tournaments/${tournament.id}/edit');
  }

  void _showDeleteConfirmation(TournamentModel tournament) {
    final tournamentBloc = context.read<TournamentBloc>();
    
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: tournamentBloc,
        child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete Tournament'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${tournament.name}"?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('This action will permanently delete:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      const Text('The tournament and all its data'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.group, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      const Text('All teams and team members'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      const Text('All games and schedules'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      const Text('All statistics and standings'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.category, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      const Text('All categories and resources'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<TournamentBloc, TournamentState>(
            builder: (context, state) {
              return FilledButton(
                                 onPressed: state.isDeleting 
                     ? null 
                     : () {
                         Navigator.of(context).pop();
                         context.read<TournamentBloc>().add(
                           TournamentDeleteRequested(tournament.id),
                         );
                         
                         // Show success message
                         Future.delayed(const Duration(milliseconds: 500), () {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text('Tournament "${tournament.name}" deleted successfully'),
                                 backgroundColor: Colors.green,
                                 duration: const Duration(seconds: 3),
                               ),
                             );
                           }
                         });
                       },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: state.isDeleting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Deleting...'),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_forever, size: 16),
                          const SizedBox(width: 4),
                          const Text('Delete Tournament'),
                        ],
                      ),
              );
            },
          ),
        ],
        ),
      ),
    );
  }
} 