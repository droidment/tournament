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
    final hasCustomColor = team.color != null;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: hasCustomColor ? teamColor.withOpacity(0.08) : null,
      shape: hasCustomColor 
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: teamColor.withOpacity(0.2),
                width: 1,
              ),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: teamColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: teamColor, 
              width: hasCustomColor ? 2 : 1,
            ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasCustomColor ? Colors.black87 : null,
                ),
              ),
            ),
            if (hasCustomColor) ...[
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: teamColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
              Text(
                team.description!,
                style: TextStyle(
                  color: hasCustomColor ? Colors.black87 : null,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (team.contactEmail?.isNotEmpty == true) ...[
                  Icon(
                    Icons.email,
                    size: 16,
                    color: hasCustomColor ? Colors.black54 : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      team.contactEmail!,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasCustomColor ? Colors.black54 : Colors.grey[600],
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
                    color: hasCustomColor ? Colors.black54 : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Seed: ${team.seed}',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasCustomColor ? Colors.black54 : Colors.grey[600],
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