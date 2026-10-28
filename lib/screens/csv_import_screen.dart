import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/restaurant_provider.dart';
import '../services/csv_import_export_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final TextEditingController _csvTextController = TextEditingController();
  final CsvImportExportService _importService = CsvImportExportService();

  bool _isImporting = false;
  CsvImportReport? _report;

  Future<void> _pasteFromClipboard() async {
    AppHaptics.lightImpact(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _csvTextController.text = data.text!;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasted CSV content from clipboard!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty or does not contain text.')),
        );
      }
    }
  }

  Future<void> _runImport() async {
    final text = _csvTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste your CSV content first.')),
      );
      return;
    }

    AppHaptics.mediumImpact(context);
    setState(() {
      _isImporting = true;
      _report = null;
    });

    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    final report = await _importService.importFromCsv(text);
    await provider.loadData();

    if (mounted) {
      setState(() {
        _isImporting = false;
        _report = report;
      });
      AppHaptics.heavyImpact(context);
    }
  }

  @override
  void dispose() {
    _csvTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Google Sheet / CSV', style: TextStyle(fontFamily: 'Serif')),
      ),
      body: _isImporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.champagneGold),
                  SizedBox(height: 16),
                  Text('Importing restaurants and creating visit memories...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Banner
                Card(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.champagneGold.withAlpha(50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.table_chart_rounded, color: AppColors.champagneGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'How to import your Sheet',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Serif'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. In Google Sheets, click File → Download → Comma-separated values (.csv)\n'
                          '2. Open the downloaded file, select all & copy (or paste below directly).\n'
                          '3. Multiline dates (e.g. 22 Dec\'24, 12 Feb\'25) & xTimes (x4) will automatically create restaurant entries and chronological timeline visits!',
                          style: TextStyle(fontSize: 13, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Paste action bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CSV Content',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    TextButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.paste_rounded, size: 18),
                      label: const Text('Paste from Clipboard'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Text field
                TextFormField(
                  controller: _csvTextController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '"Restaurant Name","Date","xTimes"\n"Cafe arko","22 Dec\'24\n12 Feb\'25\n12 Oct\'25\n28 Mar\'26","x4"\n"Magician","20 April\'25",""',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: OutlineInputBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
                  ),
                ),
                const SizedBox(height: 20),

                // Import Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.champagneGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
                  ),
                  onPressed: _runImport,
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: const Text(
                    'Import & Build Collection',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                // Report Card
                if (_report != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _report!.errors.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded,
                                color: _report!.errors.isEmpty ? AppColors.success : AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              const Text('Import Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(height: 20),
                          Text('• Restaurants Created: ${_report!.restaurantsImported}'),
                          const SizedBox(height: 4),
                          Text('• Visit Memories Created: ${_report!.visitsImported}'),
                          const SizedBox(height: 4),
                          Text('• Empty/Skipped Rows: ${_report!.skippedRows}'),
                          if (_report!.warnings.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Notes & Warnings:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                            ..._report!.warnings.map((w) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('  $w', style: const TextStyle(fontSize: 12)),
                                )),
                          ],
                          if (_report!.errors.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                            ..._report!.errors.map((e) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('  $e', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                                )),
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
}
