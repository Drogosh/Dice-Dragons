import 'package:flutter/material.dart';
import '../services/firebase_realtime_database_service.dart';
import '../services/migration_service.dart';

class DataMigrationScreen extends StatefulWidget {
  final FirebaseRealtimeDatabaseService rtdbService;
  final MigrationService migrationService;

  const DataMigrationScreen({
    super.key,
    required this.rtdbService,
    required this.migrationService,
  });

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  bool _isMigrating = false;
  MigrationResult? _migrationResult;
  MigrationStatus? _migrationStatus;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkMigrationStatus();
  }

  Future<void> _checkMigrationStatus() async {
    try {
      final status = await widget.migrationService.checkMigrationStatus();
      setState(() {
        _migrationStatus = status;
        _statusMessage = status.isMigrated
            ? '✅ Данные уже мигрированы'
            : '⚠️ Требуется миграция данных';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка: $e';
      });
    }
  }

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
      _statusMessage = '🔄 Начало миграции...';
    });

    try {
      final result = await widget.migrationService.migrateAllSessions();
      setState(() {
        _migrationResult = result;
        _statusMessage = '✅ Миграция завершена!\n$result';
        _isMigrating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Успешно мигрировано: ${result.successCount} сессий'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка при миграции: $e';
        _isMigrating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Миграция данных'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информационный блок
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Миграция данных',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Эта операция переместит все ваши сессии из Firestore '
                        'в Firebase Real-time Database для лучшей производительности '
                        'и синхронизации в реальном времени.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Статус миграции
              if (_migrationStatus != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📈 Статус',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Firestore сессий:',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _migrationStatus!.firestoreCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.grey.shade400,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RTDB сессий:',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _migrationStatus!.rtdbCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _migrationStatus!.isMigrated
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            border: Border.all(
                              color: _migrationStatus!.isMigrated
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _migrationStatus!.isMigrated
                                ? '✅ Данные полностью мигрированы'
                                : '⚠️ Требуется миграция ${_migrationStatus!.firestoreCount} сессий',
                            style: TextStyle(
                              color: _migrationStatus!.isMigrated
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Результат миграции
              if (_migrationResult != null) ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ Результат миграции',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildResultRow(
                          '✅ Успешно мигрировано:',
                          '${_migrationResult!.successCount} сессий',
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        if (_migrationResult!.errorCount > 0)
                          _buildResultRow(
                            '❌ Ошибок:',
                            '${_migrationResult!.errorCount} сессий',
                            Colors.red,
                          ),
                        const SizedBox(height: 8),
                        _buildResultRow(
                          '📊 Успешность:',
                          '${_migrationResult!.successPercentage.toStringAsFixed(1)}%',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Статус сообщение
              if (_statusMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusMessage.startsWith('✅')
                        ? Colors.green.shade50
                        : _statusMessage.startsWith('🔄')
                            ? Colors.blue.shade50
                            : Colors.red.shade50,
                    border: Border.all(
                      color: _statusMessage.startsWith('✅')
                          ? Colors.green
                          : _statusMessage.startsWith('🔄')
                              ? Colors.blue
                              : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith('✅')
                          ? Colors.green
                          : _statusMessage.startsWith('🔄')
                              ? Colors.blue
                              : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isMigrating ? null : _startMigration,
                      icon: _isMigrating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        _isMigrating
                            ? 'Миграция в процессе...'
                            : 'Начать миграцию',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isMigrating ? null : _checkMigrationStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Информационное окно
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Информация',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Firebase Real-time Database обеспечивает синхронизацию в реальном времени\n'
                        '• Все пользователи видят обновления мгновенно\n'
                        '• Работает офлайн с автоматической синхронизацией\n'
                        '• Запросы выполняются быстрее благодаря кэшированию',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

