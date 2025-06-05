import 'package:flutter/material.dart';
import '../../../../core/models/tournament_bracket_model.dart';
import '../../../../core/models/team_model.dart';

class TournamentBracketWidget extends StatefulWidget {
  final TournamentBracketModel bracket;
  final Map<String, TeamModel> teamMap;
  final Function(BracketMatchModel)? onMatchTap;
  final bool showScores;
  final bool isInteractive;

  const TournamentBracketWidget({
    super.key,
    required this.bracket,
    required this.teamMap,
    this.onMatchTap,
    this.showScores = true,
    this.isInteractive = true,
  });

  @override
  State<TournamentBracketWidget> createState() => _TournamentBracketWidgetState();
}

class _TournamentBracketWidgetState extends State<TournamentBracketWidget> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _winnersHorizontalController = ScrollController();
  final ScrollController _losersHorizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _winnersHorizontalController.dispose();
    _losersHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: _buildBracket(),
          ),
        ],
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
            Icons.account_tree,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getBracketTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.bracket.isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'COMPLETE',
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

  Widget _buildBracket() {
    if (widget.bracket.rounds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No bracket data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (widget.bracket.isDoubleElimination) {
      return _buildDoubleEliminationBracket();
    } else {
      return _buildSingleEliminationBracket();
    }
  }

  Widget _buildSingleEliminationBracket() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        trackVisibility: true,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (ScrollNotification notification) {
            return notification.depth == 1;
          },
          child: SingleChildScrollView(
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: _buildBracketTree(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoubleEliminationBracket() {
    // For now, treat double elimination as single elimination to avoid complex layout issues
    return _buildSimplifiedBracket();
  }

  Widget _buildSimplifiedBracket() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        trackVisibility: true,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (ScrollNotification notification) {
            return notification.depth == 1;
          },
          child: SingleChildScrollView(
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: _buildSimpleRoundsRow(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleRoundsRow() {
    final rounds = widget.bracket.rounds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rounds.asMap().entries.map((entry) {
        final index = entry.key;
        final round = entry.value;
        
        return Row(
          children: [
            _buildSimpleRoundColumn(round, index),
            if (index < rounds.length - 1)
              const SizedBox(width: 40), // Simple spacing instead of connector lines
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSimpleRoundColumn(BracketRoundModel round, int roundIndex) {
    return Column(
      children: [
        // Round header
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            round.roundName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Matches with simple spacing
        SizedBox(
          width: 200,
          child: Column(
            children: round.matches.map((match) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildMatchCard(match),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBracketSection(List<BracketRoundModel> rounds, [ScrollController? scrollController]) {
    if (rounds.isEmpty) return const SizedBox.shrink();

    final controller = scrollController ?? _horizontalController;
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: _buildRoundsRow(rounds),
      ),
    );
  }

  Widget _buildBracketTree() {
    final rounds = widget.bracket.rounds;
    return _buildRoundsRow(rounds);
  }

  Widget _buildRoundsRow(List<BracketRoundModel> rounds) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rounds.asMap().entries.map((entry) {
        final index = entry.key;
        final round = entry.value;
        
        return Row(
          children: [
            _buildRoundColumn(round, index),
            if (index < rounds.length - 1)
              _buildConnectorLines(round, rounds[index + 1]),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRoundColumn(BracketRoundModel round, int roundIndex) {
    return Column(
      children: [
        // Round header
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            round.roundName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Matches with simpler spacing to avoid overflow
        SizedBox(
          width: 200,
          child: Column(
            children: round.matches.map((match) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildMatchCard(match),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BracketMatchModel match) {
    final team1 = match.team1Id != null ? widget.teamMap[match.team1Id!] : null;
    final team2 = match.team2Id != null ? widget.teamMap[match.team2Id!] : null;
    
    return GestureDetector(
      onTap: widget.isInteractive && widget.onMatchTap != null 
          ? () => widget.onMatchTap!(match) 
          : null,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: _getMatchCardColor(match),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: match.isComplete ? Colors.green : Colors.grey[300]!,
            width: match.isComplete ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTeamRow(
              team1, 
              match.team1Score, 
              match.winnerId == team1?.id,
              isTop: true,
            ),
            const Divider(height: 1),
            _buildTeamRow(
              team2, 
              match.team2Score, 
              match.winnerId == team2?.id,
              isTop: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(TeamModel? team, int? score, bool isWinner, {required bool isTop}) {
    final teamName = team?.name ?? 'TBD';
    final displayScore = widget.showScores && score != null ? score.toString() : '';
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isWinner ? Colors.green.withOpacity(0.1) : null,
          borderRadius: isTop 
              ? const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                )
              : const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
        ),
        child: Row(
          children: [
            if (isWinner)
              Icon(
                Icons.emoji_events,
                size: 16,
                color: Colors.amber,
              ),
            if (isWinner) const SizedBox(width: 4),
            Expanded(
              child: Text(
                teamName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  color: team == null ? Colors.grey : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (displayScore.isNotEmpty)
              Text(
                displayScore,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.green[700] : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorLines(BracketRoundModel currentRound, BracketRoundModel nextRound) {
    return Container(
      width: 40,
      height: _calculateRoundHeight(currentRound),
      child: CustomPaint(
        painter: BracketConnectorPainter(
          currentRound.matches.length,
          nextRound.matches.length,
        ),
      ),
    );
  }

  Widget _buildGrandFinal() {
    final grandFinalRound = widget.bracket.rounds.firstWhere(
      (r) => r.bracketType == 'grand_final',
    );
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            'Grand Final',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 200,
              child: _buildMatchCard(grandFinalRound.matches.first),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getBracketTitle() {
    if (widget.bracket.isDoubleElimination) {
      return 'Double Elimination Bracket';
    } else {
      return 'Single Elimination Bracket';
    }
  }

  Color _getMatchCardColor(BracketMatchModel match) {
    if (match.isBye) return Colors.grey[100]!;
    if (match.isComplete) return Colors.green[50]!;
    return Colors.white;
  }

  double _calculateRoundHeight(BracketRoundModel round) {
    const matchHeight = 80.0;
    const matchSpacing = 16.0;
    return (round.matches.length * matchHeight) + 
           ((round.matches.length - 1) * matchSpacing) + 
           100; // Extra padding
  }

  double pow(num base, num exponent) {
    return 1.0; // Simplified for now
  }
}

class BracketConnectorPainter extends CustomPainter {
  final int currentRoundMatches;
  final int nextRoundMatches;

  BracketConnectorPainter(this.currentRoundMatches, this.nextRoundMatches);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const matchHeight = 80.0;
    const matchSpacing = 16.0;

    // Draw connecting lines between matches
    for (int i = 0; i < nextRoundMatches; i++) {
      final parentMatch1 = i * 2;
      final parentMatch2 = (i * 2) + 1;

      if (parentMatch1 < currentRoundMatches) {
        final y1 = (parentMatch1 * (matchHeight + matchSpacing)) + (matchHeight / 2);
        final y3 = (i * (matchHeight + matchSpacing * 2)) + (matchHeight / 2);
        
        // Horizontal line from first parent
        canvas.drawLine(
          Offset(0, y1),
          Offset(size.width / 2, y1),
          paint,
        );

        if (parentMatch2 < currentRoundMatches) {
          final y2 = (parentMatch2 * (matchHeight + matchSpacing)) + (matchHeight / 2);
          
          // Horizontal line from second parent
          canvas.drawLine(
            Offset(0, y2),
            Offset(size.width / 2, y2),
            paint,
          );

          // Vertical connecting line
          canvas.drawLine(
            Offset(size.width / 2, y1),
            Offset(size.width / 2, y2),
            paint,
          );
        }

        // Line to next round
        canvas.drawLine(
          Offset(size.width / 2, y3),
          Offset(size.width, y3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 