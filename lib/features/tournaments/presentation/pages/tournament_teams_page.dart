import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/tournaments/bloc/team_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/team_event.dart';
import 'package:teamapp3/features/tournaments/bloc/team_state.dart';
import 'package:teamapp3/features/tournaments/bloc/category_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/category_event.dart';
import 'package:teamapp3/features/tournaments/bloc/category_state.dart';
import 'package:teamapp3/features/tournaments/data/models/category_model.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/team_list_item.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/add_team_dialog.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/edit_team_dialog.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/team_export_import_dialog.dart';
import 'package:teamapp3/features/tournaments/data/services/team_import_export_service.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';

class TournamentTeamsPage extends StatefulWidget {

  const TournamentTeamsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });
  final String tournamentId;
  final String tournamentName;

  @override
  State<TournamentTeamsPage> createState() => _TournamentTeamsPageState();
}

class _TournamentTeamsPageState extends State<TournamentTeamsPage> {
  String? _selectedCategoryId;
  TournamentModel? _tournament;
  
  @override
  void initState() {
    super.initState();
    // Load teams and categories
    context.read<TeamBloc>().add(
          TournamentTeamsLoadRequested(widget.tournamentId),
        );
    context.read<CategoryBloc>().add(
          TournamentCategoriesLoadRequested(widget.tournamentId),
        );
    _loadTournamentInfo();
  }

  Future<void> _loadTournamentInfo() async {
    try {
      // You'll need to add this method to your tournament repository
      // For now, we'll assume the tournament format to determine behavior
      setState(() {
        // Default to null, will be set when we have proper repository access
        _tournament = null;
      });
    } catch (e) {
      // Handle error
      print('Error loading tournament info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournamentName} - Teams'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tournaments'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _showExportImportDialog,
            tooltip: 'Export/Import Teams & Resources',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with category filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tournament Teams',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage teams participating in your tournament',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                _buildCategoryFilter(),
              ],
            ),
          ),

          // Teams list
          Expanded(
            child: BlocConsumer<TeamBloc, TeamState>(
              listener: (context, state) {
                if (state.status == TeamBlocStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'An error occurred'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state.status == TeamBlocStatus.success) {
                  if (state.selectedTeam != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Team operation completed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state.status == TeamBlocStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredTeams = _selectedCategoryId == null
                    ? state.teams
                    : state.teams.where((team) => team.categoryId == _selectedCategoryId).toList();

                if (filteredTeams.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildTeamsList(filteredTeams);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeamDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Team'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            Text(
              'Filter by category:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    child: Text('All Categories'),
                  ),
                  ...state.categories.map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategoryId == null ? 'No teams yet' : 'No teams in this category',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategoryId == null 
                ? 'Add teams to get started with your tournament'
                : 'Teams can be assigned to categories when creating or editing them',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddTeamDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Team'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList(List<TeamModel> teams) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return TeamListItem(
          key: ValueKey(team.id),
          team: team,
          onEdit: () => _showEditTeamDialog(team),
          onDelete: () => _showDeleteConfirmation(team),
        );
      },
    );
  }

  void _showAddTeamDialog() {
    final teamBloc = context.read<TeamBloc>();
    final categoryBloc = context.read<CategoryBloc>();
    
    showDialog(
      context: context,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: teamBloc),
          BlocProvider.value(value: categoryBloc),
        ],
        child: AddTeamDialog(
          tournamentId: widget.tournamentId,
          onTeamAdded: (teamData) {
            teamBloc.add(
              TeamCreateRequested(
                tournamentId: widget.tournamentId,
                name: teamData['name'] as String,
                description: teamData['description'] as String?,
                categoryId: teamData['categoryId'] as String?,
                contactEmail: teamData['contactEmail'] as String?,
                contactPhone: teamData['contactPhone'] as String?,
                seed: teamData['seed'] as int?,
                color: teamData['color'] as Color?,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditTeamDialog(TeamModel team) {
    final teamBloc = context.read<TeamBloc>();
    final categoryBloc = context.read<CategoryBloc>();
    
    showDialog(
      context: context,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: teamBloc),
          BlocProvider.value(value: categoryBloc),
        ],
        child: EditTeamDialog(
          team: team,
          onTeamUpdated: (teamData) {
            teamBloc.add(
              TeamUpdateRequested(
                teamId: team.id,
                name: teamData['name'] as String?,
                description: teamData['description'] as String?,
                categoryId: teamData['categoryId'] as String?,
                contactEmail: teamData['contactEmail'] as String?,
                contactPhone: teamData['contactPhone'] as String?,
                seed: teamData['seed'] as int?,
                color: teamData['color'] as Color?,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(TeamModel team) {
    final teamBloc = context.read<TeamBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text(
          'Are you sure you want to delete "${team.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              teamBloc.add(TeamDeleteRequested(team.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team Management Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Managing Teams:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Add new teams with names and details'),
              Text('• Assign teams to tournament categories'),
              Text('• Set contact information for team managers'),
              Text('• Assign seeding for bracket formats'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Team names must be unique within the tournament'),
              Text('• Use categories to organize different divisions'),
              Text('• Seeding helps determine bracket positions'),
              Text('• Contact info helps with communication'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showExportImportDialog() {
    showDialog(
      context: context,
      builder: (context) => TeamExportImportDialog(
        tournamentId: widget.tournamentId,
        tournamentName: widget.tournamentName,
        format: _tournament?.format.value ?? 'roundRobin', // Default format
      ),
    ).then((_) {
      // Refresh teams list after dialog closes
      context.read<TeamBloc>().add(
        TournamentTeamsLoadRequested(widget.tournamentId),
      );
    });
  }


} 