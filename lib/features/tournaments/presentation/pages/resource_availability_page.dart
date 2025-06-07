import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/core/models/tournament_resource_model.dart';
import 'package:teamapp3/core/models/resource_availability_model.dart';
import 'package:teamapp3/features/tournaments/data/repositories/resource_availability_repository.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/add_availability_dialog.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/edit_availability_dialog.dart';

class ResourceAvailabilityPage extends StatefulWidget {

  const ResourceAvailabilityPage({
    super.key,
    required this.resource,
    required this.tournamentName,
  });
  final TournamentResourceModel resource;
  final String tournamentName;

  @override
  State<ResourceAvailabilityPage> createState() => _ResourceAvailabilityPageState();
}

class _ResourceAvailabilityPageState extends State<ResourceAvailabilityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResourceAvailabilityRepository _repository = ResourceAvailabilityRepository();
  
  List<ResourceAvailabilityModel> _recurringAvailability = [];
  List<ResourceAvailabilityModel> _specificDateAvailability = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      final recurring = await _repository.getRecurringAvailability(widget.resource.id);
      final specificDate = await _repository.getSpecificDateAvailability(widget.resource.id);
      
      setState(() {
        _recurringAvailability = recurring;
        _specificDateAvailability = specificDate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.resource.name} - Availability'),
            Text(
              widget.tournamentName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.repeat),
              text: 'Recurring',
            ),
            Tab(
              icon: Icon(Icons.event),
              text: 'Specific Dates',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecurringTab(),
                _buildSpecificDatesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAvailabilityDialog,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Recurring' : 'Add Specific Date'),
      ),
    );
  }

  Widget _buildRecurringTab() {
    if (_recurringAvailability.isEmpty) {
      return _buildEmptyState(
        icon: Icons.repeat,
        title: 'No recurring schedule',
        subtitle: 'Set up weekly availability for this resource',
        buttonText: 'Add Weekly Schedule',
      );
    }

    // Group by day of week
    final groupedByDay = <int, List<ResourceAvailabilityModel>>{};
    for (final availability in _recurringAvailability) {
      final day = availability.dayOfWeek!;
      groupedByDay.putIfAbsent(day, () => []).add(availability);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7, // Days of the week
      itemBuilder: (context, index) {
        final dayAvailability = groupedByDay[index] ?? [];
        return _buildDayCard(index, dayAvailability);
      },
    );
  }

  Widget _buildSpecificDatesTab() {
    if (_specificDateAvailability.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event,
        title: 'No specific dates',
        subtitle: 'Add availability for specific tournament dates',
        buttonText: 'Add Specific Date',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _specificDateAvailability.length,
      itemBuilder: (context, index) {
        final availability = _specificDateAvailability[index];
        return _buildAvailabilityCard(availability);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddAvailabilityDialog,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayOfWeek, List<ResourceAvailabilityModel> availability) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayName = days[dayOfWeek];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          dayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          availability.isEmpty 
              ? 'No availability' 
              : '${availability.length} time slot${availability.length > 1 ? 's' : ''}',
        ),
        children: availability.map(_buildAvailabilityListItem).toList(),
      ),
    );
  }

  Widget _buildAvailabilityCard(ResourceAvailabilityModel availability) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: _buildAvailabilityListItem(availability),
    );
  }

  Widget _buildAvailabilityListItem(ResourceAvailabilityModel availability) {
    return ListTile(
      leading: Icon(
        availability.isAvailable ? Icons.check_circle : Icons.cancel,
        color: availability.isAvailable ? Colors.green : Colors.red,
      ),
      title: Text(availability.timeRange),
      subtitle: Text(availability.displayDate),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _showEditAvailabilityDialog(availability);
          } else if (value == 'delete') {
            _showDeleteConfirmation(availability);
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
    );
  }

  void _showAddAvailabilityDialog() {
    final isRecurring = _tabController.index == 0;
    
    showDialog(
      context: context,
      builder: (context) => AddAvailabilityDialog(
        resourceId: widget.resource.id,
        isRecurring: isRecurring,
        onAvailabilityAdded: (availability) {
          setState(() {
            if (availability.isRecurring) {
              _recurringAvailability.add(availability);
              _recurringAvailability.sort((a, b) => a.dayOfWeek!.compareTo(b.dayOfWeek!));
            } else {
              _specificDateAvailability.add(availability);
              _specificDateAvailability.sort((a, b) => a.specificDate!.compareTo(b.specificDate!));
            }
          });
        },
      ),
    );
  }

  void _showEditAvailabilityDialog(ResourceAvailabilityModel availability) {
    showDialog(
      context: context,
      builder: (context) => EditAvailabilityDialog(
        availability: availability,
        onAvailabilityUpdated: (updated) {
          setState(() {
            if (updated.isRecurring) {
              final index = _recurringAvailability.indexWhere((a) => a.id == updated.id);
              if (index != -1) {
                _recurringAvailability[index] = updated;
              }
            } else {
              final index = _specificDateAvailability.indexWhere((a) => a.id == updated.id);
              if (index != -1) {
                _specificDateAvailability[index] = updated;
              }
            }
          });
        },
      ),
    );
  }

  void _showDeleteConfirmation(ResourceAvailabilityModel availability) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Availability'),
        content: Text(
          'Are you sure you want to delete the availability slot for ${availability.displayDate} '
          '(${availability.timeRange})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _repository.deleteAvailability(availability.id);
                setState(() {
                  if (availability.isRecurring) {
                    _recurringAvailability.removeWhere((a) => a.id == availability.id);
                  } else {
                    _specificDateAvailability.removeWhere((a) => a.id == availability.id);
                  }
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Availability deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting availability: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
        title: const Text('Resource Availability Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recurring Availability:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Set weekly schedule (same time every week)'),
              Text('• Perfect for regular operating hours'),
              Text('• Applies to all weeks of the tournament'),
              SizedBox(height: 16),
              Text(
                'Specific Date Availability:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Set availability for specific dates'),
              Text('• Overrides recurring schedule'),
              Text('• Use for holidays, special events, or exceptions'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Start with recurring schedule for regular hours'),
              Text('• Add specific dates for exceptions'),
              Text('• Mark slots as unavailable for maintenance'),
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
} 