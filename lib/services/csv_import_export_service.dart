import '../models/restaurant.dart';
import '../models/visit.dart';
import 'database_service.dart';

class CsvImportReport {
  final int restaurantsImported;
  final int visitsImported;
  final int skippedRows;
  final List<String> warnings;
  final List<String> errors;

  CsvImportReport({
    required this.restaurantsImported,
    required this.visitsImported,
    required this.skippedRows,
    required this.warnings,
    required this.errors,
  });
}

class CsvImportExportService {
  final DatabaseService _dbService = DatabaseService();

  static final Map<String, int> _monthMap = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  /// Parses date strings such as "22 Dec'24", "20 April'25", "03 Sept'25", "2025-10-12", "12/10/2025"
  DateTime? parseCustomDate(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return null;

    // ISO 8601: "2024-12-22"
    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    // Regex for: 22 Dec'24, 20 April'25, 03 Sept 2025, 14 Aug 25
    final match = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)[\x27\s]*(\d{2,4})$').firstMatch(clean);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final monStr = match.group(2)!.toLowerCase();
      final month = _monthMap[monStr];
      var year = int.tryParse(match.group(3)!);

      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    }

    // Common slash/dash format: DD/MM/YYYY or MM/DD/YYYY
    final slashParts = clean.split(RegExp(r'[/.-]'));
    if (slashParts.length == 3) {
      final p1 = int.tryParse(slashParts[0]);
      final p2 = int.tryParse(slashParts[1]);
      var p3 = int.tryParse(slashParts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        if (p3 < 100) p3 += 2000;
        // Assume Day/Month/Year if p1 > 12
        if (p1 > 12 && p2 <= 12) {
          return DateTime(p3, p2, p1);
        } else if (p2 <= 12 && p1 <= 31) {
          return DateTime(p3, p2, p1);
        }
      }
    }

    return null;
  }

  /// Parses CSV with proper quote, multiline-cell, and comma handling
  List<List<String>> parseCsv(String input) {
    final List<List<String>> rows = [];
    List<String> currentRow = [];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    final chars = input.runes.map((r) => String.fromCharCode(r)).toList();

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (char == '"') {
        if (inQuotes && i + 1 < chars.length && chars[i + 1] == '"') {
          currentCell.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString());
        currentCell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < chars.length && chars[i + 1] == '\n') {
          i++;
        }
        currentRow.add(currentCell.toString());
        currentCell.clear();
        if (currentRow.any((c) => c.trim().isNotEmpty)) {
          rows.add(currentRow);
        }
        currentRow = [];
      } else {
        currentCell.write(char);
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      if (currentRow.any((c) => c.trim().isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  /// Import restaurants and visits from CSV
  Future<CsvImportReport> importFromCsv(String csvContent) async {
    int rCount = 0;
    int vCount = 0;
    int skipped = 0;
    final List<String> warnings = [];
    final List<String> errors = [];

    try {
      final rows = parseCsv(csvContent);
      if (rows.isEmpty) {
        return CsvImportReport(
          restaurantsImported: 0,
          visitsImported: 0,
          skippedRows: 0,
          warnings: ['The CSV content is empty.'],
          errors: [],
        );
      }

      // Check header row
      final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
      int nameIdx = header.indexWhere((h) => h.contains('restaurant') || h.contains('name') || h == 'place');
      int dateIdx = header.indexWhere((h) => h.contains('date') || h.contains('visit'));
      int timesIdx = header.indexWhere((h) => h.contains('times') || h.contains('count') || h.contains('xtimes') || h.contains('total'));
      int locationIdx = header.indexWhere((h) => h.contains('location') || h.contains('area') || h.contains('city') || h.contains('branch'));
      int cuisineIdx = header.indexWhere((h) => h.contains('cuisine') || h.contains('food') || h.contains('type'));

      if (nameIdx == -1) nameIdx = 0;
      if (dateIdx == -1 && header.length > 1) dateIdx = 1;
      if (timesIdx == -1 && header.length > 2) timesIdx = 2;

      final dataRows = rows.skip(1).toList();
      final Map<String, Restaurant> batchRestaurants = {};

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        if (row.isEmpty || row.every((c) => c.trim().isEmpty)) {
          skipped++;
          continue;
        }

        final rawName = nameIdx < row.length ? row[nameIdx].trim() : '';
        if (rawName.isEmpty) {
          skipped++;
          warnings.add('Row ${i + 2}: Skipped because restaurant name was empty.');
          continue;
        }

        // Handle names that have locations in parentheses, e.g. "Dalki (Zindabazar)"
        String name = rawName;
        String? extractedLocation;
        final parenMatch = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(rawName);
        if (parenMatch != null) {
          name = parenMatch.group(1)!.trim();
          extractedLocation = parenMatch.group(2)!.trim();
        }

        final explicitLocation = (locationIdx != -1 && locationIdx < row.length) ? row[locationIdx].trim() : null;
        final finalLocation = explicitLocation?.isNotEmpty == true ? explicitLocation : extractedLocation;
        final cuisine = (cuisineIdx != -1 && cuisineIdx < row.length) ? row[cuisineIdx].trim() : null;

        // Check if restaurant already exists or was created in this batch
        final normName = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        Restaurant? targetRestaurant = batchRestaurants[normName];
        targetRestaurant ??= await _dbService.findSimilarRestaurant(name, location: finalLocation);

        if (targetRestaurant == null) {
          targetRestaurant = Restaurant(
            name: name,
            location: finalLocation,
            cuisine: cuisine?.isNotEmpty == true ? cuisine : null,
          );
          await _dbService.insertRestaurant(targetRestaurant);
          batchRestaurants[normName] = targetRestaurant;
          rCount++;
        }

        // Extract dates (can be multiple lines in a single cell)
        final rawDatesCell = (dateIdx != -1 && dateIdx < row.length) ? row[dateIdx] : '';
        final dateLines = rawDatesCell
            .split(RegExp(r'[\r\n]+'))
            .map((d) => d.trim())
            .where((d) => d.isNotEmpty)
            .toList();

        // Extract explicit count from xTimes column (e.g. "x4", "3", "4 times")
        final rawTimesCell = (timesIdx != -1 && timesIdx < row.length) ? row[timesIdx].trim() : '';
        int explicitCount = 0;
        if (rawTimesCell.isNotEmpty) {
          final countMatch = RegExp(r'\d+').firstMatch(rawTimesCell);
          if (countMatch != null) {
            explicitCount = int.tryParse(countMatch.group(0)!) ?? 0;
          }
        }

        // Create visits for all parsed dates
        final List<DateTime> validDates = [];
        for (final dateStr in dateLines) {
          final parsed = parseCustomDate(dateStr);
          if (parsed != null) {
            validDates.add(parsed);
          } else {
            warnings.add('Row ${i + 2} ("$name"): Could not parse date "$dateStr". Recorded as approximate.');
          }
        }

        // Insert visits with specific dates
        for (final date in validDates) {
          final visit = Visit(
            restaurantId: targetRestaurant.id,
            visitDate: date,
            isApproximateDate: false,
          );
          await _dbService.insertVisit(visit);
          vCount++;
        }

        // If explicit count is higher than parsed dates (e.g., x4 but only 2 dates listed),
        // add the remaining historical visits so total visit count matches your sheet!
        final remainingCount = explicitCount - validDates.length;
        if (remainingCount > 0) {
          for (int c = 0; c < remainingCount; c++) {
            final visit = Visit(
              restaurantId: targetRestaurant.id,
              visitDate: null,
              isApproximateDate: true,
              notes: 'Historical visit from sheet count ($rawTimesCell)',
            );
            await _dbService.insertVisit(visit);
            vCount++;
          }
        } else if (validDates.isEmpty && dateLines.isNotEmpty) {
          // If dates couldn't be parsed at all, still record one visit with the text note
          final visit = Visit(
            restaurantId: targetRestaurant.id,
            visitDate: null,
            isApproximateDate: true,
            notes: 'Date from sheet: ${dateLines.join(", ")}',
          );
          await _dbService.insertVisit(visit);
          vCount++;
        } else if (validDates.isEmpty && dateLines.isEmpty) {
          // No dates and no count, record 1 visit default
          final visit = Visit(
            restaurantId: targetRestaurant.id,
            visitDate: null,
            isApproximateDate: true,
          );
          await _dbService.insertVisit(visit);
          vCount++;
        }
      }
    } catch (e) {
      errors.add('Failed to parse CSV file: $e');
    }

    return CsvImportReport(
      restaurantsImported: rCount,
      visitsImported: vCount,
      skippedRows: skipped,
      warnings: warnings,
      errors: errors,
    );
  }
}
