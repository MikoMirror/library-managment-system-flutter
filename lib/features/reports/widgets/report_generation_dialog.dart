import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../services/report_service.dart';
import 'package:intl/intl.dart';

class ReportGenerationDialog extends StatefulWidget {
  const ReportGenerationDialog({super.key});

  @override
  State<ReportGenerationDialog> createState() => _ReportGenerationDialogState();
}

class _ReportGenerationDialogState extends State<ReportGenerationDialog> {
  final ReportService _reportService = ReportService();
  DateTimeRange? _selectedDateRange;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  Future<void> _generateReport() async {
    if (_selectedDateRange == null) return;

    setState(() => _isGenerating = true);
    try {
      final file = await _reportService.generateReport(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      
      // Only try to open the file if it's not null (native platforms)
      if (file?.path != null) {
        await OpenFile.open(file!.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Select Date Range'),
            subtitle: Text(
              '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - '
              '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
            ),
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
              );
              if (picked != null) {
                setState(() => _selectedDateRange = picked);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generateReport,
          child: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
} 