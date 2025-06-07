import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/tournaments/data/services/tiered_tournament_service.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_tier_model.dart';

class TieredTournamentDemoPage extends StatefulWidget {
  const TieredTournamentDemoPage({super.key});

  @override
  State<TieredTournamentDemoPage> createState() => _TieredTournamentDemoPageState();
}

class _TieredTournamentDemoPageState extends State<TieredTournamentDemoPage> {
  late TieredTournamentStructure structure;
  int selectedTeamCount = 16;

  @override
  void initState() {
    super.initState();
    _calculateStructure();
  }

  void _calculateStructure() {
    structure = TieredTournamentService.calculateOptimalStructure(selectedTeamCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiered Tournament Demo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTeamCountSelector(),
            const SizedBox(height: 24),
            _buildStructureOverview(),
            const SizedBox(height: 24),
            _buildPhaseBreakdown(),
            const SizedBox(height: 24),
            _buildAdvantages(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Tiered Tournament Format',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Three-phase tournament with group stage, tier classification, and tiered playoffs',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCountSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Number of Teams',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Slider(
              value: selectedTeamCount.toDouble(),
              min: 8,
              max: 32,
              divisions: 6,
              label: '$selectedTeamCount teams',
              onChanged: (value) {
                setState(() {
                  selectedTeamCount = value.round();
                  _calculateStructure();
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('8 teams', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('$selectedTeamCount teams', 
                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('32 teams', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Structure',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStructureRow('Total Teams', '${structure.totalTeams}', Colors.blue),
            _buildStructureRow('Usable Teams', '${structure.usableTeams}', Colors.green),
            if (structure.eliminatedTeams > 0)
              _buildStructureRow('Eliminated Teams', '${structure.eliminatedTeams}', Colors.red),
            const Divider(),
            _buildStructureRow('Groups', '${structure.numGroups}', Colors.orange),
            _buildStructureRow('Teams per Group', '${structure.groupSize}', Colors.orange),
            const Divider(),
            _buildStructureRow('Pro Tier', '${structure.proTierTeams} teams', Colors.amber),
            _buildStructureRow('Intermediate Tier', '${structure.intermediateTierTeams} teams', Colors.lightBlue),
            _buildStructureRow('Novice Tier', '${structure.noviceTierTeams} teams', Colors.lightGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Three Tournament Phases',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPhaseCard(
          phase: 1,
          title: 'Group Stage',
          subtitle: 'Round-robin within groups',
          description: 'Teams are distributed across ${structure.numGroups} groups using snake-draft seeding. Each team plays every other team in their group once.',
          icon: Icons.groups,
          color: Colors.blue,
          details: [
            '${structure.numGroups} groups of ${structure.groupSize} teams each',
            'Round-robin format within each group',
            'Configurable scoring (2-1-0 by default)',
            'Teams ranked by points, then tiebreakers',
          ],
        ),
        const SizedBox(height: 16),
        _buildPhaseCard(
          phase: 2,
          title: 'Tier Classification',
          subtitle: 'Sort teams into performance tiers',
          description: 'Based on group stage results, teams are sorted into Pro, Intermediate, and Novice tiers. Lowest performers may be eliminated.',
          icon: Icons.leaderboard,
          color: Colors.orange,
          details: [
            'Pro: Top performers (${structure.proTierTeams} teams)',
            'Intermediate: Middle performers (${structure.intermediateTierTeams} teams)',
            'Novice: Developing teams (${structure.noviceTierTeams} teams)',
            if (structure.eliminatedTeams > 0) 'Eliminates ${structure.eliminatedTeams} lowest teams',
          ],
        ),
        const SizedBox(height: 16),
        _buildPhaseCard(
          phase: 3,
          title: 'Tiered Playoffs',
          subtitle: 'Separate elimination brackets',
          description: 'Each tier runs its own single-elimination playoff bracket, ensuring competitive balance and giving every team a chance to win their tier.',
          icon: Icons.emoji_events,
          color: Colors.purple,
          details: [
            'Three separate elimination brackets',
            'Pro Champion, Intermediate Champion, Novice Champion',
            'Teams seeded by tier performance',
            'Guaranteed competitive matches',
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseCard({
    required int phase,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required List<String> details,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phase $phase: $title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      detail,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantages() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Key Advantages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdvantageItem(
              '⚖️ Competitive Balance',
              'Teams compete against similar skill levels in playoffs',
            ),
            _buildAdvantageItem(
              '🎯 Multiple Champions',
              'Three different winners (Pro, Intermediate, Novice)',
            ),
            _buildAdvantageItem(
              '🏐 Guaranteed Games',
              'Every team gets significant playing time in group stage',
            ),
            _buildAdvantageItem(
              '📊 Fair Assessment',
              'Full tiebreaker system with head-to-head and point differential',
            ),
            _buildAdvantageItem(
              '🚀 Scalable Design',
              'Works efficiently with any number of teams (8-32+)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.split(' ')[0],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.substring(title.indexOf(' ') + 1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to create tournament with tiered format pre-selected
            context.pop(); // Return to previous page
            // The user can now select "Tiered Tournament" from the format dropdown
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Tiered Tournament'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _showDetailedExample(context);
          },
          icon: const Icon(Icons.info_outline),
          label: const Text('View Example Walkthrough'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showDetailedExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Example: 16-Team Tournament'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Phase 1: Group Stage',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                const Text('• 4 groups (A, B, C, D) with 4 teams each'),
                const Text('• Snake-draft seeding: 1→A, 2→B, 3→C, 4→D, 5→D, 6→C, 7→B, 8→A...'),
                const Text('• Each team plays 3 group games'),
                const Text('• Teams ranked by points (2-1-0 scoring)'),
                const SizedBox(height: 16),
                const Text(
                  'Phase 2: Tier Classification',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                const Text('• 1st place teams → Pro Tier (4 teams)'),
                const Text('• 2nd & 3rd place teams → Intermediate Tier (8 teams)'),
                const Text('• 4th place teams → Novice Tier (4 teams)'),
                const Text('• Tiebreakers: head-to-head, point differential'),
                const SizedBox(height: 16),
                const Text(
                  'Phase 3: Tiered Playoffs',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const SizedBox(height: 8),
                const Text('• Pro Bracket: 4 teams → 2 rounds → Pro Champion'),
                const Text('• Intermediate Bracket: 8 teams → 3 rounds → Intermediate Champion'),
                const Text('• Novice Bracket: 4 teams → 2 rounds → Novice Champion'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Games per Team:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• Group Stage: 3 games guaranteed'),
                      Text('• Playoffs: 1-3 additional games'),
                      Text('• Minimum: 4 games | Maximum: 6 games'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
} 