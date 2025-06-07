# Tiered Tournament Format Specification

## Overview

The Tiered Tournament Format is a hybrid tournament structure that combines group stage play with tiered playoff brackets. This format is designed to provide all teams with an appropriate level of competition throughout the tournament, regardless of their skill level. The format first groups teams for initial round-robin play, then sorts them into skill-based tiers for elimination rounds.

### Team Count Rules

A critical aspect of this format is handling the total number of teams:

1. Teams must fit evenly into the group and tier structure
2. If there are an odd number of teams or teams that cannot fit evenly into the structure, the excess teams are eliminated before the tournament begins
3. The distribution of teams into tiers depends on the total count of participating teams

Examples:
- With 16 teams: 4 groups of 4 teams → 4 Pro, 8 Intermediate, 4 Novice
- With 20 teams: 5 groups of 4 teams → 5 Pro, 10 Intermediate, 5 Novice
- With 23 teams: 20 teams are used (5 groups of 4), 3 teams are eliminated
- With 24 teams: 6 groups of 4 teams → 8 Pro, 8 Intermediate, 8 Novice

## Format Structure

### Phase 1: Group Stage (Round Robin)

1. Teams are divided into equal-sized groups (e.g., 16 teams into 4 groups of 4 teams each)
2. Within each group, teams play a complete round-robin format where each team plays against all other teams in their group
3. Points are awarded based on game results (typically 2 points for a win, 1 for a tie, 0 for a loss)
4. Teams are ranked within their groups based on:
   - Total points
   - Head-to-head results (if applicable)
   - Point differential or other sport-specific tiebreakers

### Phase 2: Tier Classification

After the group stage, teams are sorted into different tiers based on their group stage performance:

1. **Pro Tier**: Top-performing teams from each group (e.g., 1st place from each group)
2. **Intermediate Tier**: Middle-performing teams from each group (e.g., 2nd and 3rd place from each group)
3. **Novice Tier**: Bottom-performing teams from each group (e.g., 4th place from each group)

### Phase 3: Tiered Playoffs

Each tier conducts its own playoff tournament with a format appropriate to the number of teams:

#### Pro Tier Format
- Teams are seeded based on group stage performance
- Simple elimination bracket (e.g., 1st vs 4th, 2nd vs 3rd in semifinals)
- Winners advance to finals
- Single elimination format

#### Intermediate Tier Format
- Teams are seeded based on group stage performance
- Full elimination bracket with matchups based on seeding (1v8, 2v7, 3v6, 4v5)
- Quarterfinals, semifinals, and finals
- Single elimination format

#### Novice Tier Format
- Similar structure to other tiers but with appropriate number of teams
- May include consolation games to ensure all teams play a minimum number of games

## Implementation Requirements

### Configuration Options

1. **Number of Groups**: Configurable based on total team count
2. **Teams per Group**: Configurable based on total team count and desired group size
3. **Tier Distribution**: Configurable rules for how teams are distributed into tiers
4. **Playoff Format per Tier**: Configurable elimination bracket structure for each tier
5. **Tiebreaker Rules**: Configurable rules for resolving ties within groups

### Data Model Extensions

1. **Group Assignment**: Track which group each team belongs to
2. **Group Standings**: Track team performance within groups
3. **Tier Assignment**: Track which tier each team is assigned to after group play
4. **Playoff Seeding**: Track team seeding within tier playoffs
5. **Multi-phase Results**: Track results across both group and playoff phases

### User Interface Requirements

1. **Group Display**: Clear visualization of groups and standings
2. **Tier Transition**: Clear indication of how teams transition from groups to tiers
3. **Multiple Brackets**: Ability to view separate brackets for each tier
4. **Tournament Progress**: Overall view of tournament progress across all phases

## Example: 16-Team Tournament

### Initial Setup
- 16 teams total
- 4 groups of 4 teams each (Groups A, B, C, D)
- Each team plays 3 games in the group stage

### Tier Classification
- Pro Tier: 1st place teams from Groups A, B, C, D (4 teams)
- Intermediate Tier: 2nd and 3rd place teams from Groups A, B, C, D (8 teams)
- Novice Tier: 4th place teams from Groups A, B, C, D (4 teams)

### Playoff Structure
- Pro Tier: Semifinals (1v4, 2v3 based on group stage performance), then Finals
- Intermediate Tier: Quarterfinals (1v8, 2v7, 3v6, 4v5), Semifinals, Finals
- Novice Tier: Semifinals, then Finals

## Benefits

1. **Guaranteed Games**: All teams play a minimum number of games in the group stage
2. **Appropriate Competition**: Teams compete against others of similar skill level in playoffs
3. **Engagement**: All teams remain engaged throughout the tournament
4. **Efficiency**: Format accommodates large number of teams while limiting total games played
5. **Flexibility**: Structure can be adapted for different numbers of teams and sport requirements

## Technical Considerations

1. **Scheduling Complexity**: System must handle the transition between phases
2. **Result Tracking**: System must track results across multiple phases
3. **Standings Calculation**: Different rules may apply for group standings vs playoff advancement
4. **User Communication**: Clear communication to teams about their progression through the tournament

This format should be implemented as a configurable tournament type that allows organizers to set up the specific parameters for their event while maintaining the core tiered structure.
