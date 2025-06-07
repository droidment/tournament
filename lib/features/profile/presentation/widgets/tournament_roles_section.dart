import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamapp3/features/profile/data/models/user_profile_model.dart';

class TournamentRolesSection extends StatelessWidget {

  const TournamentRolesSection({
    super.key,
    required this.profile,
  });
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    if (profile.tournamentRoles.isEmpty) {
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
                Icons.badge_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Tournament Roles Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join or create tournaments to see your roles here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.badge,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Tournament Roles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Role summary cards
        Row(
          children: [
            Expanded(
              child: _RoleSummaryCard(
                icon: Icons.admin_panel_settings,
                label: 'Organizer',
                count: profile.tournamentRoles
                    .where((role) => role.role == UserRole.organizer)
                    .length,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleSummaryCard(
                icon: Icons.supervisor_account,
                label: 'Admin',
                count: profile.tournamentRoles
                    .where((role) => role.role == UserRole.admin)
                    .length,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RoleSummaryCard(
                icon: Icons.group,
                label: 'Team Manager',
                count: profile.tournamentRoles
                    .where((role) => role.role == UserRole.teamManager)
                    .length,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleSummaryCard(
                icon: Icons.sports,
                label: 'Player',
                count: profile.tournamentRoles
                    .where((role) => role.role == UserRole.player)
                    .length,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Detailed role list
        Text(
          'Role Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        ...profile.tournamentRoles.map((role) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TournamentRoleCard(role: role),
            ),),
      ],
    );
  }
}

class _RoleSummaryCard extends StatelessWidget {

  const _RoleSummaryCard({
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
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

class _TournamentRoleCard extends StatelessWidget {

  const _TournamentRoleCard({
    required this.role,
  });
  final TournamentRole role;

  Color _getRoleColor() {
    switch (role.role) {
      case UserRole.organizer:
        return Colors.purple;
      case UserRole.admin:
        return Colors.orange;
      case UserRole.teamManager:
        return Colors.blue;
      case UserRole.player:
        return Colors.green;
    }
  }

  IconData _getRoleIcon() {
    switch (role.role) {
      case UserRole.organizer:
        return Icons.admin_panel_settings;
      case UserRole.admin:
        return Icons.supervisor_account;
      case UserRole.teamManager:
        return Icons.group;
      case UserRole.player:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: roleColor.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getRoleIcon(),
            color: roleColor,
            size: 20,
          ),
        ),
        title: Text(
          role.tournamentName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: roleColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    role.role.displayName,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Joined ${DateFormat('MMM d, yyyy').format(role.joinedAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
      ),
    );
  }
} 