import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamapp3/features/profile/data/models/user_profile_model.dart';

class MyTournamentsSection extends StatelessWidget {

  const MyTournamentsSection({
    super.key,
    required this.tournaments,
    required this.profile,
  });
  final List<Map<String, dynamic>> tournaments;
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Tournaments Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create or join tournaments to see them here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to create tournament
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Tournament'),
              ),
            ],
          ),
        ),
      );
    }

    // Group tournaments by status
    final upcomingTournaments = tournaments
        .where((t) => _getTournamentStatus(t) == TournamentDisplayStatus.upcoming)
        .toList();
    final activeTournaments = tournaments
        .where((t) => _getTournamentStatus(t) == TournamentDisplayStatus.active)
        .toList();
    final completedTournaments = tournaments
        .where((t) => _getTournamentStatus(t) == TournamentDisplayStatus.completed)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'My Tournaments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const Spacer(),
            Chip(
              label: Text(
                '${tournaments.length} Total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              side: BorderSide.none,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.schedule,
                label: 'Upcoming',
                count: upcomingTournaments.length,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.play_arrow,
                label: 'Active',
                count: activeTournaments.length,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                label: 'Completed',
                count: completedTournaments.length,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Active tournaments (if any)
        if (activeTournaments.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Active Tournaments',
            icon: Icons.play_arrow,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          ...activeTournaments.map((tournament) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TournamentCard(tournament: tournament),
              ),),
          const SizedBox(height: 24),
        ],

        // Upcoming tournaments (if any)
        if (upcomingTournaments.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Upcoming Tournaments',
            icon: Icons.schedule,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          ...upcomingTournaments.map((tournament) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TournamentCard(tournament: tournament),
              ),),
          const SizedBox(height: 24),
        ],

        // Completed tournaments (if any)
        if (completedTournaments.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Completed Tournaments',
            icon: Icons.check_circle,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          ...completedTournaments.take(5).map((tournament) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TournamentCard(tournament: tournament),
              ),),
          if (completedTournaments.length > 5)
            TextButton(
              onPressed: () {
                // TODO: Show all completed tournaments
              },
              child: Text('View ${completedTournaments.length - 5} more completed tournaments'),
            ),
        ],
      ],
    );
  }

  TournamentDisplayStatus _getTournamentStatus(Map<String, dynamic> tournament) {
    final now = DateTime.now();
    final startDate = DateTime.parse(tournament['start_date'] as String);
    final endDate = DateTime.parse(tournament['end_date'] as String);

    if (now.isBefore(startDate)) {
      return TournamentDisplayStatus.upcoming;
    } else if (now.isAfter(endDate)) {
      return TournamentDisplayStatus.completed;
    } else {
      return TournamentDisplayStatus.active;
    }
  }
}

enum TournamentDisplayStatus { upcoming, active, completed }

class _StatCard extends StatelessWidget {

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _TournamentCard extends StatelessWidget {

  const _TournamentCard({
    required this.tournament,
  });
  final Map<String, dynamic> tournament;

  Color _getStatusColor() {
    final now = DateTime.now();
    final startDate = DateTime.parse(tournament['start_date'] as String);
    final endDate = DateTime.parse(tournament['end_date'] as String);

    if (now.isBefore(startDate)) {
      return Colors.blue;
    } else if (now.isAfter(endDate)) {
      return Colors.grey;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    final now = DateTime.now();
    final startDate = DateTime.parse(tournament['start_date'] as String);
    final endDate = DateTime.parse(tournament['end_date'] as String);

    if (now.isBefore(startDate)) {
      return 'Upcoming';
    } else if (now.isAfter(endDate)) {
      return 'Completed';
    } else {
      return 'Active';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'organizer':
        return Colors.purple;
      case 'admin':
        return Colors.orange;
      case 'team_manager':
        return Colors.blue;
      case 'player':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'organizer':
        return 'Organizer';
      case 'admin':
        return 'Admin';
      case 'team_manager':
        return 'Team Manager';
      case 'player':
        return 'Player';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final roleColor = _getRoleColor(tournament['my_role'] as String);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // TODO: Navigate to tournament details
        },
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
                          tournament['name'] as String,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (tournament['description'] != null &&
                            (tournament['description'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tournament['description'] as String,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getRoleDisplayName(tournament['my_role'] as String),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(
                      DateTime.parse(tournament['start_date'] as String),
                    ),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    ' - ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(
                      DateTime.parse(tournament['end_date'] as String),
                    ),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (tournament['location'] != null &&
                      (tournament['location'] as String).isNotEmpty) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tournament['location'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 