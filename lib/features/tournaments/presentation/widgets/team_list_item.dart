import 'package:flutter/material.dart';
import '../../../../core/models/team_model.dart';

class TeamListItem extends StatelessWidget {
  final TeamModel team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TeamListItem({
    super.key,
    required this.team,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = team.color ?? Theme.of(context).primaryColor;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: teamColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: team.color != null 
                ? Border.all(color: teamColor, width: 2)
                : null,
          ),
          child: Icon(
            Icons.group,
            color: teamColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (team.color != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: team.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (team.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(team.description!),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (team.contactEmail?.isNotEmpty == true) ...[
                  Icon(
                    Icons.email,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      team.contactEmail!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (team.seed != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Seed: ${team.seed}',
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
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 