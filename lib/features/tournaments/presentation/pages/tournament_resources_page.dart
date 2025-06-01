import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/resource_bloc.dart';
import '../../bloc/resource_event.dart';
import '../../bloc/resource_state.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../widgets/resource_list_item.dart';
import '../widgets/add_resource_dialog.dart';
import '../widgets/edit_resource_dialog.dart';
import '../pages/resource_availability_page.dart';

class TournamentResourcesPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentResourcesPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentResourcesPage> createState() => _TournamentResourcesPageState();
}

class _TournamentResourcesPageState extends State<TournamentResourcesPage> {
  String? _selectedType;
  
  @override
  void initState() {
    super.initState();
    context.read<ResourceBloc>().add(
          TournamentResourcesLoadRequested(widget.tournamentId),
        );
    context.read<ResourceBloc>().add(
          ResourceTypesLoadRequested(widget.tournamentId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournamentName} - Resources'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tournaments'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with type filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tournament Resources',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage courts, fields, and other resources for your tournament',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                _buildTypeFilter(),
              ],
            ),
          ),

          // Resources list
          Expanded(
            child: BlocConsumer<ResourceBloc, ResourceState>(
              listener: (context, state) {
                if (state.status == ResourceBlocStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'An error occurred'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state.status == ResourceBlocStatus.success) {
                  if (state.selectedResource != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resource operation completed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state.status == ResourceBlocStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredResources = _selectedType == null
                    ? state.resources
                    : state.resources.where((resource) => resource.type == _selectedType).toList();

                if (filteredResources.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildResourcesList(filteredResources);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddResourceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Resource'),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return BlocBuilder<ResourceBloc, ResourceState>(
      builder: (context, state) {
        if (state.resourceTypes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            Text(
              'Filter by type:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedType,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...state.resourceTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_formatResourceType(type)),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
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
            Icons.location_on_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedType == null ? 'No resources yet' : 'No resources of this type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedType == null 
                ? 'Add courts, fields, or other resources to enable scheduling'
                : 'Resources help organize your tournament schedule',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddResourceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Resource'),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesList(List<TournamentResourceModel> resources) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return ResourceListItem(
          key: ValueKey(resource.id),
          resource: resource,
          onEdit: () => _showEditResourceDialog(resource),
          onDelete: () => _showDeleteConfirmation(resource),
          onManageAvailability: () => _navigateToAvailabilityPage(resource),
        );
      },
    );
  }

  void _showAddResourceDialog() {
    final resourceBloc = context.read<ResourceBloc>();
    
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: resourceBloc,
        child: AddResourceDialog(
          tournamentId: widget.tournamentId,
          onResourceAdded: (resourceData) {
            resourceBloc.add(
              ResourceCreateRequested(
                tournamentId: widget.tournamentId,
                name: resourceData['name'] as String,
                type: resourceData['type'] as String,
                description: resourceData['description'] as String?,
                capacity: resourceData['capacity'] as int?,
                location: resourceData['location'] as String?,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditResourceDialog(TournamentResourceModel resource) {
    final resourceBloc = context.read<ResourceBloc>();
    
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: resourceBloc,
        child: EditResourceDialog(
          resource: resource,
          onResourceUpdated: (resourceData) {
            resourceBloc.add(
              ResourceUpdateRequested(
                resourceId: resource.id,
                name: resourceData['name'] as String?,
                type: resourceData['type'] as String?,
                description: resourceData['description'] as String?,
                capacity: resourceData['capacity'] as int?,
                location: resourceData['location'] as String?,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(TournamentResourceModel resource) {
    final resourceBloc = context.read<ResourceBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text(
          'Are you sure you want to delete "${resource.name}"? '
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
              resourceBloc.add(ResourceDeleteRequested(resource.id));
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
        title: const Text('Resource Management Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Managing Resources:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Add courts, fields, tables, or any playing surfaces'),
              Text('• Specify capacity for simultaneous games'),
              Text('• Set location information for easy identification'),
              Text('• Use different types to organize resources'),
              SizedBox(height: 16),
              Text(
                'Common Resource Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Court - for tennis, basketball, badminton'),
              Text('• Field - for soccer, football, cricket'),
              Text('• Table - for table tennis, board games'),
              Text('• Pitch - for cricket, rugby'),
              Text('• Pool - for swimming competitions'),
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

  String _formatResourceType(String type) {
    return type.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  void _navigateToAvailabilityPage(TournamentResourceModel resource) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResourceAvailabilityPage(
          resource: resource,
          tournamentName: widget.tournamentName,
        ),
      ),
    );
  }
} 