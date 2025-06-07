import 'package:flutter/material.dart';
import 'package:teamapp3/core/models/team_model.dart';

class TeamListItem extends StatelessWidget {

  const TeamListItem({
    super.key,
    required this.team,
    required this.onEdit,
    required this.onDelete,
  });
  final TeamModel team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
              ),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
      child: ListTile(
        leading: _buildLeadingWidget(teamColor, hasCustomColor),
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
            if (team.contactEmail?.isNotEmpty == true) 
              Row(
                children: [
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
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
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

  Widget _buildLeadingWidget(Color teamColor, bool hasCustomColor) {
    if (team.seed != null) {
      // Display seed number as circular badge
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: teamColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white, 
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${team.seed}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else {
      // Display generic team icon
      return Container(
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
      );
    }
  }
} 