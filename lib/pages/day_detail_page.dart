import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import 'program_exercise_page.dart';
import 'exercise_detail.dart';

class DayDetailPage extends StatefulWidget {
  final int programId;
  final String programName;
  final int dayNumber;
  final int? workoutId;
  final bool isCompleted;

  const DayDetailPage({
    super.key,
    required this.programId,
    required this.programName,
    required this.dayNumber,
    this.workoutId,
    required this.isCompleted,
  });

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  final AuthService _authService = AuthService();
  List<dynamic> _exercises = [];
  bool _isLoading = true;
  String? _error;

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userProgram =
          await _authService.getOrCreateUserProgram(widget.programId);
      if (userProgram == null) {
        if (mounted) {
          setState(() {
            _error = _t('Unable to start program');
            _isLoading = false;
          });
        }
        return;
      }

      final exercises =
          await _authService.fetchDayExercises(userProgram, widget.dayNumber);

      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startTraining() async {
    final userProgram =
        await _authService.getOrCreateUserProgram(widget.programId);
    if (userProgram == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Unable to start program')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!mounted) return;

    if (_exercises.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('No exercises found for this day')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramExercisePage(
          userProgramId: userProgram,
          dayNumber: widget.dayNumber,
          programId: widget.programId,
          workoutId: widget.workoutId ?? 0,
          startIndex: 0,
        ),
      ),
    ).then((_) {
      // Refresh data when returning from ProgramExercisePage
      _loadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        _exercises.where((e) => e['completed'] == true).length;
    final totalCount = _exercises.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('images/basketball_fon.jpg', fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withOpacity(0.3)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFFA500)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${_t('Day')} ${widget.dayNumber}',
              style: const TextStyle(color: Color(0xFFFFA500), fontSize: 20),
            ),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF4500)),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              '${_t('Error')}: $_error',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadExercises,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                            ),
                            child: Text(_t('Retry')),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Progress header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[800],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFFA500),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  color: Color(0xFFFFA500),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Exercises list or empty state
                        if (_exercises.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fitness_center,
                                      color: Colors.white54, size: 80),
                                  const SizedBox(height: 20),
                                  Text(
                                    _t('No exercises found'),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              itemCount: _exercises.length,
                              itemBuilder: (context, index) {
                                final ex = _exercises[index];
                                final exercise =
                                    ex['exercise'] as Map<String, dynamic>?;
                                final isCompleted =
                                    ex['completed'] as bool? ?? false;
                                final order =
                                    ex['exerciseOrder'] as int? ?? index + 1;

                                final rawName = (exercise?['name'] as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? exercise!['name'] as String
                                    : null;
                                final displayName = rawName != null
                                    ? LocaleService.translateDbData(rawName)
                                    : _t('Exercise');
                                final description =
                                    exercise?['description'] as String? ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: isCompleted
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF4CAF50),
                                              Color(0xFF2E7D32)
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey[800]!,
                                              Colors.grey[900]!
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        SettingsService.vibrate();
                                        final exerciseId =
                                            exercise?['id'] as int?;
                                        if (exerciseId != null) {
                                          final imageUrl =
                                              exercise?['image'] as String? ??
                                                  '';
                                          final displayImage =
                                              imageUrl.startsWith('images/')
                                                  ? imageUrl
                                                  : _authService
                                                      .getImageUrl(imageUrl);
                                          final rawName =
                                              (exercise?['name'] as String?)
                                                          ?.isNotEmpty ==
                                                      true
                                                  ? exercise!['name'] as String
                                                  : null;
                                          final description =
                                              exercise?['description']
                                                      as String? ??
                                                  '';
                                          final videoUrl =
                                              exercise?['video'] as String?;

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ExerciseDetailPage(
                                                exerciseId: exerciseId,
                                                nameExercise: rawName ?? '',
                                                image: displayImage,
                                                video: videoUrl,
                                                description: description,
                                                recommendedDurationSeconds:
                                                    exercise?[
                                                            'recommended_duration_seconds']
                                                        as int?,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: ListTile(
                                        leading: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCompleted
                                                ? const Color(0xFF4CAF50)
                                                : Colors.grey[700],
                                          ),
                                          child: Center(
                                            child: isCompleted
                                                ? const Icon(Icons.check,
                                                    color: Colors.white,
                                                    size: 18)
                                                : Text(
                                                    '$order',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        title: Text(
                                          displayName,
                                          style: TextStyle(
                                            color: isCompleted
                                                ? Colors.white
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          description.isNotEmpty
                                              ? LocaleService.translateDbData(
                                                  description)
                                              : '',
                                          style: TextStyle(
                                            color: isCompleted
                                                ? Colors.white70
                                                : Colors.white54,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: isCompleted
                                            ? const Icon(Icons.check_circle,
                                                color: Colors.white, size: 20)
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Start training button
                        if (_exercises.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: ElevatedButton(
                              onPressed: _startTraining,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA500),
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                widget.isCompleted
                                    ? _t('Review')
                                    : _t('Start Training'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}
