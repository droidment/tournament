import 'package:flutter/material.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../../../../core/models/tournament_bracket_model.dart';
import '../../data/services/bracket_generator_service.dart';

class GenerateBracketDialog extends StatefulWidget {
  final String tournamentId;
  final List<TeamModel> teams;
  final List<TournamentResourceModel> resources;
  final Function(TournamentBracketModel) onBracketGenerated;

  const GenerateBracketDialog({
    super.key,
    required this.tournamentId,
    required this.teams,
    required this.resources,
    required this.onBracketGenerated,
  });

  @override
  State<GenerateBracketDialog> createState() => _GenerateBracketDialogState();
}

class _GenerateBracketDialogState extends State<GenerateBracketDialog> {
  final BracketGeneratorService _bracketService = BracketGeneratorService();
  
  // Form controllers
  final _gameDurationController = TextEditingController(text: '60');
  final _timeBetweenGamesController = TextEditingController(text: '30');
  
  // Form state
  String _bracketFormat = 'single_elimination';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  List<String> _selectedResourceIds = [];
  bool _randomizeSeeds = false;
  bool _isLoading = false;
  
  // Seeding
  List<TeamModel> _seedOrder = [];

  @override
  void initState() {
    super.initState();
    _seedOrder = List.from(widget.teams);
    _selectedResourceIds = widget.resources.map((r) => r.id).toList();
  }

  @override
  void dispose() {
    _gameDurationController.dispose();
    _timeBetweenGamesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildBody(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Generate Elimination Bracket',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormatSelection(),
          const SizedBox(height: 16),
          _buildTeamsPreview(),
          const SizedBox(height: 16),
          _buildSeedingSection(),
          const SizedBox(height: 16),
          _buildSchedulingSection(),
          const SizedBox(height: 16),
          _buildResourceSelection(),
          const SizedBox(height: 16),
          _buildGameSettings(),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Format',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'single_elimination',
              label: Text('Single Elimination'),
              icon: Icon(Icons.account_tree),
            ),
            ButtonSegment(
              value: 'double_elimination',
              label: Text('Double Elimination'),
              icon: Icon(Icons.account_tree_outlined),
            ),
          ],
          selected: {_bracketFormat},
          onSelectionChanged: (Set<String> selection) {
            setState(() {
              _bracketFormat = selection.first;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getFormatDescription(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teams (${widget.teams.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bracket Size: ${_calculateBracketSize(widget.teams.length)} teams',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Total Rounds: ${_calculateRounds(_calculateBracketSize(widget.teams.length))}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (_bracketFormat == 'double_elimination')
                Text(
                  'Est. Total Games: ${_calculateDoubleEliminationGames(widget.teams.length)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              if (_bracketFormat == 'single_elimination')
                Text(
                  'Total Games: ${widget.teams.length - 1}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeedingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Team Seeding',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch(
              value: _randomizeSeeds,
              onChanged: (value) {
                setState(() {
                  _randomizeSeeds = value;
                  if (value) {
                    _seedOrder.shuffle();
                  } else {
                    _seedOrder = List.from(widget.teams);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            const Text('Randomize'),
          ],
        ),
        const SizedBox(height: 8),
        if (!_randomizeSeeds) ...[
          Text(
            'Drag to reorder teams by seed (1st seed = strongest team)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSeedingList(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.shuffle, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Seeds will be randomized when bracket is generated'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSeedingList() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ReorderableListView.builder(
        itemCount: _seedOrder.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _seedOrder.removeAt(oldIndex);
            _seedOrder.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final team = _seedOrder[index];
          return ListTile(
            key: ValueKey(team.id),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(team.name),
            trailing: const Icon(Icons.drag_handle),
          );
        },
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Date'),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    child: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Time'),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (time != null) {
                        setState(() => _startTime = time);
                      }
                    },
                    child: Text(_startTime.format(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.resources.map((resource) {
          return CheckboxListTile(
            value: _selectedResourceIds.contains(resource.id),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedResourceIds.add(resource.id);
                } else {
                  _selectedResourceIds.remove(resource.id);
                }
              });
            },
            title: Text(resource.name),
            subtitle: Text(resource.description ?? 'No description'),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGameSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _gameDurationController,
                decoration: const InputDecoration(
                  labelText: 'Game Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _timeBetweenGamesController,
                decoration: const InputDecoration(
                  labelText: 'Break Between Games (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading || _selectedResourceIds.isEmpty 
                ? null 
                : _generateBracket,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate Bracket'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBracket() async {
    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final TournamentBracketModel bracket;
      
      if (_bracketFormat == 'single_elimination') {
        bracket = await _bracketService.generateSingleEliminationBracket(
          tournamentId: widget.tournamentId,
          teams: _randomizeSeeds ? widget.teams : _seedOrder,
          resourceIds: _selectedResourceIds,
          startDate: startDateTime,
          gameDurationMinutes: int.parse(_gameDurationController.text),
          timeBetweenGamesMinutes: int.parse(_timeBetweenGamesController.text),
          randomizeSeeds: _randomizeSeeds,
        );
      } else {
        bracket = await _bracketService.generateDoubleEliminationBracket(
          tournamentId: widget.tournamentId,
          teams: _randomizeSeeds ? widget.teams : _seedOrder,
          resourceIds: _selectedResourceIds,
          startDate: startDateTime,
          gameDurationMinutes: int.parse(_gameDurationController.text),
          timeBetweenGamesMinutes: int.parse(_timeBetweenGamesController.text),
          randomizeSeeds: _randomizeSeeds,
        );
      }

      widget.onBracketGenerated(bracket);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bracket generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating bracket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods
  String _getFormatDescription() {
    switch (_bracketFormat) {
      case 'single_elimination':
        return 'Teams are eliminated after one loss. Fast and decisive.';
      case 'double_elimination':
        return 'Teams must lose twice to be eliminated. More forgiving format.';
      default:
        return '';
    }
  }

  int _calculateBracketSize(int teamCount) {
    int size = 1;
    while (size < teamCount) {
      size *= 2;
    }
    return size;
  }

  int _calculateRounds(int bracketSize) {
    int rounds = 0;
    while (bracketSize > 1) {
      bracketSize ~/= 2;
      rounds++;
    }
    return rounds;
  }

  int _calculateDoubleEliminationGames(int teamCount) {
    // Approximate calculation for double elimination
    return (teamCount * 2) - 2;
  }
} 