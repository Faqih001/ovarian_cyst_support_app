import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/services/database_migration_service.dart';

class DatabaseMigrationScreen extends StatefulWidget {
  const DatabaseMigrationScreen({super.key});

  @override
  State<DatabaseMigrationScreen> createState() =>
      _DatabaseMigrationScreenState();
}

class _DatabaseMigrationScreenState extends State<DatabaseMigrationScreen> {
  final _totalTasks = 5; // Total number of migration tasks
  final _logger = Logger();
  final _migrationService = DatabaseMigrationService();

  int _completedTasks = 0;
  String _currentTask = 'Preparing for migration...';
  bool _isMigrating = false;
  String? _errorMessage;

  double get _progress => _completedTasks / _totalTasks;

  @override
  void initState() {
    super.initState();
    _startMigration();
  }

  Future<void> _startMigration() async {
    if (!mounted) return;

    setState(() {
      _isMigrating = true;
      _errorMessage = null;
      _completedTasks = 0;
    });

    try {
      // Migrate symptom entries
      setState(() {
        _currentTask = 'Migrating symptom entries...';
      });

      await _migrationService.migrateSymptomEntries([]);
      _incrementProgress();

      // Check mounted after each significant async operation
      if (!mounted) return;

      // Migrate appointments
      setState(() {
        _currentTask = 'Migrating appointments...';
      });

      await _migrationService.migrateAppointments([]);
      _incrementProgress();

      if (!mounted) return;

      // Migrate treatments
      setState(() {
        _currentTask = 'Migrating treatments...';
      });

      await _migrationService.migrateTreatmentItems([]);
      _incrementProgress();

      if (!mounted) return;

      // Migrate medications
      setState(() {
        _currentTask = 'Migrating medications...';
      });

      await _migrationService.migrateMedications([]);
      _incrementProgress();

      if (!mounted) return;

      // Migrate community posts
      setState(() {
        _currentTask = 'Migrating community posts...';
      });

      await _migrationService.migrateCommunityPosts([]);
      _incrementProgress();
    } catch (e) {
      _logger.e('Error during migration: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to complete migration: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMigrating = false;
        });
      }
    }
  }

  void _incrementProgress() {
    setState(() {
      _completedTasks++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isMigrating) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _currentTask,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(
                'Progress: ${(_progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else if (_errorMessage != null) ...[
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Migration Failed',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startMigration,
                child: const Text('Retry Migration'),
              ),
            ] else ...[
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Migration Complete',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
