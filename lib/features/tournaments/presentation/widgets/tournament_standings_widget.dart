import 'package:flutter/material.dart';
import 'package:teamapp3/core/models/tournament_standings_model.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';

class TournamentStandingsWidget extends StatefulWidget {

  const TournamentStandingsWidget({
    super.key,
    required this.standings,
    this.format,
    this.showFullStats = true,
    this.onRefresh,
  });
  final TournamentStandingsModel standings;
  final TournamentFormat? format;
  final bool showFullStats;
  final VoidCallback? onRefresh;

  @override
  State<TournamentStandingsWidget> createState() => _TournamentStandingsWidgetState();
}

class _TournamentStandingsWidgetState extends State<TournamentStandingsWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (widget.standings.teamStandings.isEmpty)
              _buildEmptyState()
            else
              _buildStandingsTable(),
            if (widget.standings.lastUpdated != null)
              _buildLastUpdated(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFormatIcon(),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHeaderTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.standings.phase != null)
                  Text(
                    widget.standings.phase!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.onRefresh != null)
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Standings',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No standings available yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some games to see the standings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 56,
        dataRowHeight: 56,
        headingRowColor: WidgetStateProperty.all(
          Theme.of(context).colorScheme.surface,
        ),
        columns: _buildTableColumns(),
        rows: _buildTableRows(),
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    final columns = [
      const DataColumn(
        label: Text(
          'Pos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Team',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];

    // Add format-specific columns
    if (_isRoundRobinFormat()) {
      columns.addAll([
        const DataColumn(
          label: Text(
            'Pts',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Tournament Points',
        ),
        const DataColumn(
          label: Text(
            'W-L-D',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Wins-Losses-Draws',
        ),
        const DataColumn(
          label: Text(
            'PF',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Points For',
        ),
        const DataColumn(
          label: Text(
            'PA',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Points Against',
        ),
        const DataColumn(
          label: Text(
            'PD',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Point Difference',
        ),
      ]);
    } else if (_isEliminationFormat()) {
      columns.addAll([
        const DataColumn(
          label: Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const DataColumn(
          label: Text(
            'W-L',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Wins-Losses',
        ),
        if (widget.showFullStats) ...[
          const DataColumn(
            label: Text(
              'PF',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            tooltip: 'Points For',
          ),
          const DataColumn(
            label: Text(
              'PA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            tooltip: 'Points Against',
          ),
        ],
      ]);
    } else if (_isSwissFormat()) {
      columns.addAll([
        const DataColumn(
          label: Text(
            'MP',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Match Points',
        ),
        const DataColumn(
          label: Text(
            'W-L-D',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Wins-Losses-Draws',
        ),
        const DataColumn(
          label: Text(
            'TB',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          tooltip: 'Tie-Break (Buchholz)',
        ),
        if (widget.showFullStats) ...[
          const DataColumn(
            label: Text(
              'PD',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            tooltip: 'Point Difference',
          ),
        ],
      ]);
    }

    return columns;
  }

  List<DataRow> _buildTableRows() {
    return widget.standings.teamStandings.asMap().entries.map((entry) {
      final index = entry.key;
      final team = entry.value;
      
      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (index % 2 == 0) {
              return Theme.of(context).colorScheme.surface.withOpacity(0.5);
            }
            return null;
          },
        ),
        cells: _buildTableCells(team),
      );
    }).toList();
  }

  List<DataCell> _buildTableCells(TeamStandingModel team) {
    final cells = [
      DataCell(
        Container(
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            color: _getPositionColor(team.position),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              team.position.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (team.status != 'active')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(team.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusIcon(team.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (team.status != 'active') const SizedBox(width: 8),
            Flexible(
              child: Text(
                team.teamName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: team.isEliminated ? Colors.grey : null,
                  decoration: team.isEliminated ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ];

    // Add format-specific cells
    if (_isRoundRobinFormat()) {
      cells.addAll([
        DataCell(
          Text(
            team.points.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text(team.record)),
        DataCell(Text(team.pointsFor.toString())),
        DataCell(Text(team.pointsAgainst.toString())),
        DataCell(
          Text(
            team.pointsDifference >= 0 
                ? '+${team.pointsDifference}' 
                : team.pointsDifference.toString(),
            style: TextStyle(
              color: team.pointsDifference >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ]);
    } else if (_isEliminationFormat()) {
      cells.addAll([
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(team.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusColor(team.status)),
            ),
            child: Text(
              team.statusDisplayName,
              style: TextStyle(
                color: _getStatusColor(team.status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(Text('${team.wins}-${team.losses}')),
        if (widget.showFullStats) ...[
          DataCell(Text(team.pointsFor.toString())),
          DataCell(Text(team.pointsAgainst.toString())),
        ],
      ]);
    } else if (_isSwissFormat()) {
      cells.addAll([
        DataCell(
          Text(
            (team.points / 2).toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text(team.record)),
        DataCell(
          Text(
            team.tieBreakValue?.toStringAsFixed(1) ?? '0.0',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (widget.showFullStats) ...[
          DataCell(
            Text(
              team.pointsDifference >= 0 
                  ? '+${team.pointsDifference}' 
                  : team.pointsDifference.toString(),
              style: TextStyle(
                color: team.pointsDifference >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ]);
    }

    return cells;
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated: ${_formatDateTime(widget.standings.lastUpdated!)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          if (widget.standings.isFinal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'FINAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isRoundRobinFormat() => widget.standings.format == 'round_robin';
  bool _isEliminationFormat() => 
      widget.standings.format == 'single_elimination' || 
      widget.standings.format == 'double_elimination';
  bool _isSwissFormat() => widget.standings.format == 'swiss';

  IconData _getFormatIcon() {
    switch (widget.standings.format) {
      case 'round_robin':
        return Icons.refresh;
      case 'single_elimination':
      case 'double_elimination':
        return Icons.account_tree;
      case 'swiss':
        return Icons.grid_view;
      case 'pro_elimination':
      case 'intermediate_elimination':
      case 'novice_elimination':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }

  String _getHeaderTitle() {
    switch (widget.standings.format) {
      case 'round_robin':
        return 'Round Robin Standings';
      case 'single_elimination':
        return 'Single Elimination Bracket';
      case 'double_elimination':
        return 'Double Elimination Bracket';
      case 'swiss':
        return 'Swiss System Standings';
      case 'pro_elimination':
        return 'Pro Tier Bracket';
      case 'intermediate_elimination':
        return 'Intermediate Tier Bracket';
      case 'novice_elimination':
        return 'Novice Tier Bracket';
      default:
        return 'Tournament Standings';
    }
  }

  Color _getPositionColor(int position) {
    if (position == 1) return Colors.amber; // Gold
    if (position == 2) return Colors.grey; // Silver
    if (position == 3) return Colors.brown; // Bronze
    return Theme.of(context).primaryColor;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'champion':
        return Colors.amber;
      case 'finalist':
        return Colors.grey;
      case 'semifinalist':
        return Colors.brown;
      case 'eliminated':
        return Colors.red;
      case 'active':
      default:
        return Colors.green;
    }
  }

  String _getStatusIcon(String? status) {
    switch (status) {
      case 'champion':
        return '🏆';
      case 'finalist':
        return '🥈';
      case 'semifinalist':
        return '🥉';
      case 'eliminated':
        return '❌';
      case 'active':
      default:
        return '✅';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
} 