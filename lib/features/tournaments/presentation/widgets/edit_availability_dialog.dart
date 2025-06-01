import 'package:flutter/material.dart';
import '../../../../core/models/resource_availability_model.dart';
import '../../data/repositories/resource_availability_repository.dart';

class EditAvailabilityDialog extends StatefulWidget {
  final ResourceAvailabilityModel availability;
  final Function(ResourceAvailabilityModel) onAvailabilityUpdated;

  const EditAvailabilityDialog({
    super.key,
    required this.availability,
    required this.onAvailabilityUpdated,
  });

  @override
  State<EditAvailabilityDialog> createState() => _EditAvailabilityDialogState();
}

class _EditAvailabilityDialogState extends State<EditAvailabilityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ResourceAvailabilityRepository();
  
  // Form controllers
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isAvailable;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    // Parse the time strings from the model
    final startParts = widget.availability.startTime.split(':');
    final endParts = widget.availability.endTime.split(':');
    
    _startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );
    
    _endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );
    
    _isAvailable = widget.availability.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.availability.isRecurring 
            ? 'Edit Recurring Availability' 
            : 'Edit Specific Date Availability'
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the day/date info (non-editable)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.availability.isRecurring ? Icons.repeat : Icons.event,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.availability.isRecurring ? 'Recurring' : 'Specific Date',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            widget.availability.displayDate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Time selection
                Text(
                  'Time Range',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 8),
                              Text(
                                _startTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 8),
                              Text(
                                _endTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Availability toggle
                Row(
                  children: [
                    Switch(
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isAvailable ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            _isAvailable 
                                ? 'Resource can be used during this time'
                                : 'Resource is blocked (maintenance, etc.)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (!_isTimeValid()) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'End time must be after start time',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Show current vs new values
                if (_hasChanges()) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Changes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_timeChanged()) ...[
                          Text(
                            'Time: ${widget.availability.timeRange} → ${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        if (_availabilityChanged()) ...[
                          Text(
                            'Status: ${widget.availability.isAvailable ? 'Available' : 'Unavailable'} → ${_isAvailable ? 'Available' : 'Unavailable'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || !_isTimeValid() || !_hasChanges() ? null : _submitForm,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Availability'),
        ),
      ],
    );
  }

  bool _isTimeValid() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes > startMinutes;
  }

  bool _hasChanges() {
    return _timeChanged() || _availabilityChanged();
  }

  bool _timeChanged() {
    final currentStart = _formatTime(_startTime);
    final currentEnd = _formatTime(_endTime);
    return currentStart != widget.availability.startTime || 
           currentEnd != widget.availability.endTime;
  }

  bool _availabilityChanged() {
    return _isAvailable != widget.availability.isAvailable;
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_isTimeValid() || !_hasChanges()) return;

    setState(() => _isLoading = true);

    try {
      String? startTimeStr;
      String? endTimeStr;
      bool? isAvailable;

      // Only send changed fields
      if (_timeChanged()) {
        startTimeStr = _formatTime(_startTime);
        endTimeStr = _formatTime(_endTime);
      }

      if (_availabilityChanged()) {
        isAvailable = _isAvailable;
      }

      final updatedAvailability = await _repository.updateAvailability(
        availabilityId: widget.availability.id,
        startTime: startTimeStr,
        endTime: endTimeStr,
        isAvailable: isAvailable,
      );

      widget.onAvailabilityUpdated(updatedAvailability);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 