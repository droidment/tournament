import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teamapp3/features/tournaments/data/services/team_import_export_service.dart';

class TeamExportImportDialog extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final String format;

  const TeamExportImportDialog({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.format,
  });

  @override
  State<TeamExportImportDialog> createState() => _TeamExportImportDialogState();
}

class _TeamExportImportDialogState extends State<TeamExportImportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamImportExportService _service = TeamImportExportService();
  
  bool _isExporting = false;
  bool _isImporting = false;
  ExportResult? _exportResult;
  ImportResult? _importResult;
  ImportSummary? _importSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.import_export, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teams & Resources Export/Import',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.tournamentName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Export', icon: Icon(Icons.upload)),
                  Tab(text: 'Import', icon: Icon(Icons.download)),
                ],
              ),
            ),
            
            // Tab Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExportTab(),
                  _buildImportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Export Format',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exports teams and resources in JSON format including:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureItem('• Team names, descriptions, and contact info'),
                      _buildFeatureItem('• Team seeds and colors'),
                      _buildFeatureItem('• Resource names, types, and descriptions'),
                      _buildFeatureItem('• Resource capacity and location info'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Export Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _performExport,
                  icon: _isExporting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                  label: Text(_isExporting ? 'Exporting...' : 'Export Teams & Resources'),
                ),
              ),
            ],
          ),
          
          if (_exportResult != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Export Successful',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Successfully exported ${_exportResult!.totalCount} items:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    if (_exportResult!.teamsCount > 0)
                      Text('• ${_exportResult!.teamsCount} teams'),
                    if (_exportResult!.resourcesCount > 0)
                      Text('• ${_exportResult!.resourcesCount} resources'),
                    const SizedBox(height: 8),
                    Text(
                      'Data has been copied to clipboard. You can also download it as a file.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy to Clipboard'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _saveToFile,
                          icon: const Icon(Icons.save),
                          label: const Text('Save File'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner for tiered tournaments
          if (widget.format == 'tiered') ...[
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tiered Tournament: Teams without seeds will be assigned default seed 10',
                        style: TextStyle(color: Colors.amber.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Import Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _pickImportFile,
                  icon: _isImporting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                  label: Text(_isImporting ? 'Processing...' : 'Select JSON File'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Import Preview
          if (_importResult != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Preview',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            
                            // Teams Section
                            if (_importResult!.teams.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.group, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Teams (${_importResult!.teams.length})',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...(_importResult!.teams.take(5).map((team) => Padding(
                                padding: const EdgeInsets.only(left: 24, bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        team.name,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                                                         if (widget.format == 'tiered' && team.seed != null)
                                       Text(
                                         'Seed: ${team.seed}',
                                         style: Theme.of(context).textTheme.bodySmall,
                                       ),
                                  ],
                                ),
                              ))),
                              if (_importResult!.teams.length > 5)
                                                                 Padding(
                                   padding: const EdgeInsets.only(left: 24),
                                   child: Text(
                                     '... and ${_importResult!.teams.length - 5} more',
                                     style: Theme.of(context).textTheme.bodySmall,
                                   ),
                                 ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Resources Section
                            if (_importResult!.resources.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resources (${_importResult!.resources.length})',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...(_importResult!.resources.take(5).map((resource) => Padding(
                                padding: const EdgeInsets.only(left: 24, bottom: 4),
                                child: Text(
                                  '${resource.name} (${resource.type})',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ))),
                              if (_importResult!.resources.length > 5)
                                                                 Padding(
                                   padding: const EdgeInsets.only(left: 24),
                                   child: Text(
                                     '... and ${_importResult!.resources.length - 5} more',
                                     style: Theme.of(context).textTheme.bodySmall,
                                   ),
                                 ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Warnings
                            if (_importResult!.warnings.isNotEmpty) ...[
                              Text(
                                'Warnings:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_importResult!.warnings.map((warning) => Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning, size: 16, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        warning,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))),
                              const SizedBox(height: 16),
                            ],
                            
                            // Import Button
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _confirmImport,
                                    icon: const Icon(Icons.download),
                                    label: Text(
                                      'Import ${_importResult!.teams.length} Teams & ${_importResult!.resources.length} Resources',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Import Summary
          if (_importSummary != null) ...[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Import Complete',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Successfully imported ${_importSummary!.totalCreated} items:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_importSummary!.teamsCreated > 0)
                      Text('• ${_importSummary!.teamsCreated} teams'),
                    if (_importSummary!.resourcesCreated > 0)
                      Text('• ${_importSummary!.resourcesCreated} resources'),
                    
                    if (_importSummary!.hasSkippedItems) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Skipped ${_importSummary!.totalSkipped} items:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                      if (_importSummary!.teamsSkipped > 0)
                        Text('• ${_importSummary!.teamsSkipped} teams'),
                      if (_importSummary!.resourcesSkipped > 0)
                        Text('• ${_importSummary!.resourcesSkipped} resources'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Future<void> _performExport() async {
    setState(() => _isExporting = true);
    
    try {
      final exportResult = await _service.exportTournamentData(widget.tournamentId);
      setState(() {
        _exportResult = exportResult;
        _isExporting = false;
      });
      
      // Auto copy to clipboard
      await _copyToClipboard();
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_exportResult != null) {
      await Clipboard.setData(ClipboardData(text: _exportResult!.jsonData));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export data copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveToFile() async {
    if (_exportResult != null) {
      try {
        final fileName = 'tournament_data_${widget.tournamentName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
        final path = await _service.saveExportToDevice(_exportResult!.jsonData, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved: $path'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImportFile() async {
    setState(() => _isImporting = true);
    
    try {
      final result = await _service.pickAndParseImportFile();
      setState(() {
        _importResult = result;
        _importSummary = null;
        _isImporting = false;
      });
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmImport() async {
    if (_importResult == null) return;
    
    setState(() => _isImporting = true);
    
    try {
      final summary = await _service.importTournamentData(
        widget.tournamentId,
        _importResult!,
        widget.format,
      );
      
      setState(() {
        _importSummary = summary;
        _importResult = null;
        _isImporting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${summary.totalCreated} items'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 