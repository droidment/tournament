import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamapp3/features/profile/data/models/user_profile_model.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserProfileModel profile;

  const ProfileInfoSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bio
            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
              _InfoItem(
                icon: Icons.description,
                label: 'Bio',
                value: profile.bio!,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

            // Phone
            if (profile.phone != null && profile.phone!.isNotEmpty) ...[
              _InfoItem(
                icon: Icons.phone,
                label: 'Phone',
                value: profile.phone!,
              ),
              const SizedBox(height: 16),
            ],

            // Location
            if (profile.location != null && profile.location!.isNotEmpty) ...[
              _InfoItem(
                icon: Icons.location_on,
                label: 'Location',
                value: profile.location!,
              ),
              const SizedBox(height: 16),
            ],

            // Date of Birth
            if (profile.dateOfBirth != null) ...[
              _InfoItem(
                icon: Icons.cake,
                label: 'Date of Birth',
                value: DateFormat('MMMM d, yyyy').format(profile.dateOfBirth!),
              ),
              const SizedBox(height: 16),
            ],

            // Member Since
            _InfoItem(
              icon: Icons.calendar_today,
              label: 'Member Since',
              value: DateFormat('MMMM yyyy').format(profile.createdAt),
            ),

            // If no additional info is available
            if ((profile.bio == null || profile.bio!.isEmpty) &&
                (profile.phone == null || profile.phone!.isEmpty) &&
                (profile.location == null || profile.location!.isEmpty) &&
                profile.dateOfBirth == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete your profile by adding your bio, phone, location, and other details.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 