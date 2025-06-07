import 'package:flutter/material.dart';
import 'package:teamapp3/core/models/tournament_resource_model.dart';

class ResourceListItem extends StatelessWidget {

  const ResourceListItem({
    super.key,
    required this.resource,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAvailability,
  });
  final TournamentResourceModel resource;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageAvailability;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getTypeColor(resource.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(resource.type),
            color: _getTypeColor(resource.type),
          ),
        ),
        title: Text(
          resource.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatResourceType(resource.type)),
            if (resource.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(resource.description!),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (resource.location?.isNotEmpty == true) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      resource.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (resource.capacity != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Capacity: ${resource.capacity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            } else if (value == 'availability') {
              onManageAvailability();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'availability',
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Manage Availability', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
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
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'court':
        return Icons.sports_tennis;
      case 'field':
        return Icons.grass;
      case 'table':
        return Icons.table_restaurant;
      case 'pitch':
        return Icons.sports_soccer;
      case 'pool':
        return Icons.pool;
      default:
        return Icons.location_on;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'court':
        return Colors.blue;
      case 'field':
        return Colors.green;
      case 'table':
        return Colors.orange;
      case 'pitch':
        return Colors.purple;
      case 'pool':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _formatResourceType(String type) {
    return type.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase(),
    ).join(' ');
  }
} 