import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/authentication/bloc/auth_bloc.dart';
import 'package:teamapp3/features/profile/bloc/profile_bloc.dart';
import 'package:teamapp3/features/profile/bloc/profile_event.dart';
import 'package:teamapp3/features/profile/bloc/profile_state.dart';
import 'package:teamapp3/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:teamapp3/features/authentication/presentation/widgets/auth_button.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime? _selectedDateOfBirth;
  bool _isInitialized = false;
  bool _updateTriggered = false;

  @override
  void initState() {
    super.initState();
    // Load current profile data when page opens
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(userId));
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeFields(ProfileState state) {
    if (!_isInitialized && state.profile != null) {
      _fullNameController.text = state.profile!.fullName ?? '';
      _bioController.text = state.profile!.bio ?? '';
      _phoneController.text = state.profile!.phone ?? '';
      _locationController.text = state.profile!.location ?? '';
      _selectedDateOfBirth = state.profile!.dateOfBirth;
      _isInitialized = true;
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId != null) {
        setState(() {
          _updateTriggered = true;
        });
        context.read<ProfileBloc>().add(
              ProfileUpdateRequested(
                userId: userId,
                fullName: _fullNameController.text.trim().isEmpty 
                    ? null 
                    : _fullNameController.text.trim(),
                bio: _bioController.text.trim().isEmpty 
                    ? null 
                    : _bioController.text.trim(),
                phone: _phoneController.text.trim().isEmpty 
                    ? null 
                    : _phoneController.text.trim(),
                location: _locationController.text.trim().isEmpty 
                    ? null 
                    : _locationController.text.trim(),
                dateOfBirth: _selectedDateOfBirth,
              ),
            );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date of Birth';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // Only show success message and navigate back when update was triggered
          if (state.status == ProfileStatus.success && _updateTriggered) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/profile');
          } else if (state.status == ProfileStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to update profile'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && !_isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Initialize fields with current profile data
          _initializeFields(state);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update your profile information below',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name Field
                  AuthTextField(
                    controller: _fullNameController,
                    labelText: 'Full Name',
                    keyboardType: TextInputType.name,
                    prefixIcon: Icons.person_outlined,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bio Field
                  AuthTextField(
                    controller: _bioController,
                    labelText: 'Bio',
                    keyboardType: TextInputType.multiline,
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && value.trim().length > 500) {
                        return 'Bio must be less than 500 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  AuthTextField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        // Basic phone validation
                        final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
                        if (!phoneRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid phone number';
                        }
                        if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
                          return 'Phone number must have at least 10 digits';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location Field
                  AuthTextField(
                    controller: _locationController,
                    labelText: 'Location',
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                        return 'Location must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth Field
                  GestureDetector(
                    onTap: () => _selectDateOfBirth(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDate(_selectedDateOfBirth),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDateOfBirth == null 
                                    ? Colors.grey[600] 
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  AuthButton(
                    onPressed: _saveProfile,
                    text: 'Save Changes',
                    isLoading: state.status == ProfileStatus.loading && _isInitialized,
                  ),
                  const SizedBox(height: 16),

                  // Cancel Button
                  OutlinedButton(
                    onPressed: state.status == ProfileStatus.loading 
                        ? null 
                        : () => context.go('/profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "All fields are optional. Fill out what you'd like to share with other tournament participants.",
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 