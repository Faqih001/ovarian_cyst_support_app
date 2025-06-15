import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/symptom_prediction.dart';
import 'package:ovarian_cyst_support_app/services/ai_service.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:ovarian_cyst_support_app/services/database_service_factory.dart';

class SymptomPredictionScreen extends StatefulWidget {
  const SymptomPredictionScreen({super.key});

  @override
  State<SymptomPredictionScreen> createState() =>
      _SymptomPredictionScreenState();
}

class _SymptomPredictionScreenState extends State<SymptomPredictionScreen> {
  bool _isLoading = true;
  List<SymptomEntry> _recentSymptoms = [];
  SymptomPrediction? _currentPrediction;
  List<SymptomPrediction> _predictionHistory = [];
  String _errorMessage = '';
  bool _isGeneratingPrediction = false;

  final AIService _aiService = AIService();
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _databaseService = await DatabaseServiceFactory.getDatabaseService();
      _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize services: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load recent symptom entries
      final symptoms = await _databaseService.getSymptomEntries();

      // Sort by date descending
      symptoms.sort((a, b) => b.date.compareTo(a.date));

      // Get the most recent entries (up to 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentSymptoms =
          symptoms.where((s) => s.date.isAfter(thirtyDaysAgo)).toList();

      // Load prediction history
      final predictions = await _databaseService.getSymptomPredictions();

      // Get the latest prediction
      SymptomPrediction? latestPrediction;
      if (predictions.isNotEmpty) {
        latestPrediction = predictions.first;
      }

      setState(() {
        _recentSymptoms = recentSymptoms;
        _predictionHistory = predictions;
        _currentPrediction = latestPrediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePrediction() async {
    if (_recentSymptoms.isEmpty) {
      _showMessage(
        'Cannot generate prediction without symptom data. Please log some symptoms first.',
      );
      return;
    }

    setState(() {
      _isGeneratingPrediction = true;
      _errorMessage = '';
    });

    try {
      final prediction = await _aiService.predictSymptomSeverity(
        _recentSymptoms,
      );

      if (prediction != null) {
        // Convert SymptomPrediction to Map before saving to database
        final predictionMap = prediction.toMap();
        await _databaseService.saveSymptomPrediction(predictionMap);

        // Reload data to include the new prediction
        await _loadData();

        _showMessage('Prediction generated successfully.');
      } else {
        setState(() {
          _errorMessage = 'Could not generate prediction.';
          _isGeneratingPrediction = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating prediction: ${e.toString()}';
        _isGeneratingPrediction = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Symptom Prediction'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGeneratingPrediction ? null : _generatePrediction,
        tooltip: 'Generate Prediction',
        child: _isGeneratingPrediction
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_graph),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentPrediction(),
            const SizedBox(height: 24),
            _buildSeverityTrend(),
            const SizedBox(height: 24),
            _buildSymptomDistribution(),
            const SizedBox(height: 24),
            _buildPredictionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPrediction() {
    if (_currentPrediction == null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No prediction available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate a prediction to see insights about your symptoms',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isGeneratingPrediction ? null : _generatePrediction,
                child: _isGeneratingPrediction
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Generate Prediction'),
              ),
            ],
          ),
        ),
      );
    }

    // Define color based on risk level
    Color riskColor;
    switch (_currentPrediction!.riskLevel) {
      case 'Low':
        riskColor = Colors.green;
        break;
      case 'Medium':
        riskColor = Colors.orange;
        break;
      case 'High':
        riskColor = Colors.red;
        break;
      default:
        riskColor = Colors.blue;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Prediction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat(
                    'MMM d, yyyy',
                  ).format(_currentPrediction!.predictionDate),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSeverityGauge(
                  _currentPrediction!.severityScore,
                  riskColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _currentPrediction!.riskLevel,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                          const Text(
                            ' Risk',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: ${_currentPrediction!.severityScore.toStringAsFixed(1)}/10',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Potential Issues:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _currentPrediction!.potentialIssues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(issue)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Recommendation:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(_currentPrediction!.recommendation),
            const SizedBox(height: 16),
            if (_currentPrediction!.requiresMedicalAttention)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please consider seeking medical attention soon.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
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
  }

  Widget _buildSeverityGauge(double severity, Color color) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: severity / 10,
                strokeWidth: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          Center(
            child: Text(
              severity.toStringAsFixed(1),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityTrend() {
    if (_predictionHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit to last 7 predictions and reverse to show chronological order
    final displayHistory = _predictionHistory.length > 7
        ? _predictionHistory.sublist(0, 7).reversed.toList()
        : _predictionHistory.reversed.toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Severity Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: true),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < displayHistory.length) {
                            final date =
                                displayHistory[value.toInt()].predictionDate;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 == 0 && value >= 0 && value <= 10) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xff37434d),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: displayHistory.length - 1.0,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(displayHistory.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          displayHistory[index].severityScore,
                        );
                      }),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final severity = displayHistory[index].severityScore;
                          Color color;
                          if (severity < 3) {
                            color = Colors.green;
                          } else if (severity < 7) {
                            color = Colors.orange;
                          } else {
                            color = Colors.red;
                          }
                          return FlDotCirclePainter(
                            radius: 6,
                            color: color,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).primaryColor.withAlpha((0.15 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomDistribution() {
    if (_recentSymptoms.isEmpty) {
      return const SizedBox.shrink();
    }

    // Count symptom occurrences
    final Map<String, int> symptomCounts = {};
    for (var entry in _recentSymptoms) {
      for (var symptom in entry.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
    }

    // Sort symptoms by frequency
    final sortedSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 symptoms
    final topSymptoms = sortedSymptoms.take(5).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Frequent Symptoms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topSymptoms.map((entry) {
              final percent = (entry.value / _recentSymptoms.length) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: entry.value / _recentSymptoms.length,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${percent.toStringAsFixed(0)}%',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionHistory() {
    if (_predictionHistory.length <= 1) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prediction History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  _predictionHistory.length > 5 ? 5 : _predictionHistory.length,
              itemBuilder: (context, index) {
                final prediction = _predictionHistory[index];
                final isLatest = index == 0;
                final isFirst = index == _predictionHistory.length - 1;

                // Set color based on risk level
                Color riskColor;
                switch (prediction.riskLevel) {
                  case 'Low':
                    riskColor = Colors.green;
                    break;
                  case 'Medium':
                    riskColor = Colors.orange;
                    break;
                  case 'High':
                    riskColor = Colors.red;
                    break;
                  default:
                    riskColor = Colors.blue;
                }

                return TimelineTile(
                  alignment: TimelineAlign.manual,
                  lineXY: 0.2,
                  isFirst: isFirst,
                  isLast: isLatest,
                  indicatorStyle: IndicatorStyle(
                    width: 20,
                    height: 20,
                    indicator: Container(
                      decoration: BoxDecoration(
                        color: riskColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                  beforeLineStyle: LineStyle(color: Colors.grey.shade300),
                  endChild: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(prediction.predictionDate),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isLatest ? Colors.black : Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: riskColor.withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                prediction.riskLevel,
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Severity: ${prediction.severityScore.toStringAsFixed(1)}/10',
                          style: TextStyle(
                            color: isLatest ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        if (isLatest)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              prediction.recommendation,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_predictionHistory.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 48),
                child: TextButton(
                  onPressed: () {
                    // Would navigate to full history screen
                    _showMessage('Full history view not implemented yet.');
                  },
                  child: const Text('View Complete History'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
