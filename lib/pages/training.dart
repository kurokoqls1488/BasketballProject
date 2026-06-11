import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../pages/program_exercise_page.dart';
import '../pages/program_days_page.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final AuthService _authService = AuthService();
  List<dynamic> _programs = [];
  Map<int, double> _programProgressCache = {};
  bool _isLoading = true;
  String? _error;
  final Map<int, bool> _expandedPrograms = {};
  Map<int, List<dynamic>> _programDaysCache = {};
  Map<int, bool> _daysCompletedCache = {};

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _loadData();
    LocaleService.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      await _loadData();
    }
  }

  @override
  void dispose() {
    LocaleService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await AuthService.initCache();
      final programs = await _authService.fetchPrograms();

      final futures = programs.map((program) async {
        final programId = program['id'] as int? ?? 0;
        if (programId <= 0) return null;

        final userProg = await _authService.getOrCreateUserProgram(programId);
        final days = await _authService.fetchProgramDays(programId);
        Map<int, double> progressMap = {};
        Map<int, bool> completedMap = {};

        if (userProg != null) {
          await _authService.initializeAllProgramDays(userProg, days);
          final userProgData = await _authService.getUserProgram(userProg);
          progressMap[programId] = (userProgData?['progress_percent'] as int? ?? 0) / 100.0;
          completedMap[programId] = userProgData?['is_completed'] as bool? ?? false;
        } else {
          progressMap[programId] = 0.0;
          completedMap[programId] = false;
        }

        return {'program': program, 'days': days, 'progress': progressMap[programId], 'completed': completedMap[programId]};
      }).toList();

      final results = await Future.wait(futures);
      final filtered = results.where((r) => r != null).toList();

      final allPrograms = filtered.map((r) => (r as Map<String, dynamic>)['program'] as Map<String, dynamic>).toList();
      final allProgress = <int, double>{};
      final allDays = <int, List<dynamic>>{};
      final allCompleted = <int, bool>{};

      for (final r in filtered) {
        final map = r as Map<String, dynamic>;
        final pid = (map['program'] as Map<String, dynamic>)['id'] as int;
        allProgress[pid] = map['progress'] as double;
        allDays[pid] = map['days'] as List<dynamic>;
        allCompleted[pid] = map['completed'] as bool;
      }

      if (mounted) {
        setState(() {
          _programs = allPrograms;
          _programProgressCache = allProgress;
          _programDaysCache = allDays;
          _daysCompletedCache = allCompleted;
          _isLoading = false;
          _error = null;
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


  Future<void> _startProgram(int programId) async {
    SettingsService.vibrate();
    final userProgramId = await _authService.getOrCreateUserProgram(programId);
    if (userProgramId == null) {
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

    final currentDay = await _authService.getCurrentDay(userProgramId);
    final days = _programDaysCache[programId] ?? [];

    if (days.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Program has no days')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final dayNum = (currentDay ?? 1).clamp(1, days.length);
    final dayData = days.firstWhere((d) => (d['day_number'] as int? ?? 0) == dayNum, orElse: () => days[0]);
    final workoutId = dayData['id_workout'] as int?;

    if (workoutId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Day not linked to workout')),
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
           userProgramId: userProgramId,
           dayNumber: dayNum,
           programId: programId,
           workoutId: workoutId,
           startIndex: 0,
         ),
       ),
     ).then((_) {
       // Refresh data when returning from ProgramExercisePage
       _loadData();
     });
  }

  Future<void> _continueProgram(int programId) async {
    final userProgram = await _authService.getActiveProgram();
    if (userProgram == null || !mounted) return;
    final progId = userProgram['id'] as int?;
    final curDay = userProgram['current_day'] as int? ?? 1;
    final progProgramId = userProgram['id_program'] as int?;

    if (progId == null || progProgramId == null) return;

    final days = _programDaysCache[progProgramId] ?? await _authService.fetchProgramDays(progProgramId);
    if (days.isEmpty || !mounted) return;

    final dayNumClamped = curDay.clamp(1, days.length);
    final dayData = days.firstWhere((d) => (d['day_number'] as int? ?? 0) == dayNumClamped, orElse: () => days[0]);
    final workoutId = dayData['id_workout'] as int?;

    if (workoutId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Day not linked to workout')),
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
           userProgramId: progId,
           dayNumber: dayNumClamped,
           programId: progProgramId,
           workoutId: workoutId,
           startIndex: 0,
         ),
       ),
     ).then((_) {
       // Refresh data when returning from ProgramExercisePage
       _loadData();
     });
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final programId = program['id'] as int? ?? 0;
    final programName = program['name_program'] ?? program['name'] ?? '';
    final description = program['description'] ?? '';
    final image = program['image'] ?? '';
    final progress = (_programProgressCache[programId] ?? 0.0).clamp(0.0, 1.0);
    final days = _programDaysCache[programId] ?? [];
    final daysCount = days.length;
    final isExpanded = _expandedPrograms[programId] ?? false;
    final isAllCompleted = _daysCompletedCache[programId] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA500), Color(0xFFDC143C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.all(3),
        color: const Color(0xFF3A3A3A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            SettingsService.vibrate();
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => ProgramDaysPage(
                   programId: programId,
                   programName: programName,
                   programDescription: description,
                   programImage: image.isNotEmpty ? image : null,
                 ),
               ),
             ).then((_) {
               // Refresh data when returning from ProgramDaysPage
               _loadData();
             });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocaleService.translateDbData(programName),
                              style: const TextStyle(
                                color: Color(0xFFFF4500),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            description.isNotEmpty
                                ? Text(
                                    LocaleService.translateDbData(description),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                    maxLines: isExpanded ? null : 2,
                                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                                  )
                                : const SizedBox(),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_t('Day')} $daysCount',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  isAllCompleted ? Icons.check_circle : Icons.update,
                                  color: isAllCompleted ? const Color(0xFF4CAF50) : Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAllCompleted ? _t('Completed') : _t('In progress'),
                                  style: TextStyle(
                                    color: isAllCompleted ? const Color(0xFF4CAF50) : Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[800],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA500)),
                              minHeight: 6,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(
                                    color: Color(0xFFFFA500),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (image.isNotEmpty && image.startsWith('images/'))
                      Expanded(
                        flex: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(9),
                            bottomRight: Radius.circular(9),
                          ),
                          child: Image.asset(
                            image,
                            fit: BoxFit.cover,
                            width: 90,
                            height: 120,
                          ),
                        ),
                      ),
                    if (image.isNotEmpty && !image.startsWith('images/'))
                      Expanded(
                        flex: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(9),
                            bottomRight: Radius.circular(9),
                          ),
                          child: Image.network(
                            _authService.getImageUrl(image),
                            fit: BoxFit.cover,
                            width: 90,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'images/pustoe_photo.png',
                              fit: BoxFit.cover,
                              width: 90,
                              height: 120,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isExpanded && days.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                  child: Column(
                    children: [
                      const Divider(color: Colors.white30, height: 1),
                      const SizedBox(height: 8),
                      Text(
                        _t('Program Days'),
                        style: const TextStyle(
                          color: Color(0xFFFFA500),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                       ...days.map((day) {
                         final dayNum = day['day_number'] as int? ?? 0;
                         final workoutName = _t("Workout");
                         return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFA500).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_t("Day")} $dayNum',
                                  style: const TextStyle(
                                    color: Color(0xFFFFA500),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  workoutName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                         );
                       }),
                       const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _startProgram(programId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA500),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _t('Start'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          if (progress > 0) const SizedBox(width: 10),
                          if (progress > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _continueProgram(programId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFA500),
                                  side: const BorderSide(color: Color(0xFFFFA500)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _t('Continue'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!SettingsService.backgroundEnabled)
          Positioned.fill(
            child: Image.asset('images/basketball_fon.jpg', fit: BoxFit.cover),
          ),
        Container(color: !SettingsService.backgroundEnabled ? Colors.black.withOpacity(0.3) : const Color(0xFF121212)),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false, // Убираем автоматическую стрелку назад
              title: Text(
                _t('Программы'),
                style: const TextStyle(color: Color(0xFFFFA500), fontSize: 22),
              ),
              centerTitle: true,
            ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF4500)),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              '${_t('Error')}: $_error',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                              foregroundColor: Colors.black,
                            ),
                            child: Text(_t('Retry')),
                          ),
                        ],
                      ),
                    )
                  : _programs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fitness_center, color: Colors.white54, size: 80),
                              const SizedBox(height: 20),
                              Text(
                                _t('No programs found'),
                                style: const TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _t('Please try again later'),
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFFFFA500),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 10, bottom: 80),
                            itemCount: _programs.length,
                            itemBuilder: (context, index) {
                              final program = _programs[index] as Map<String, dynamic>;
                              return _buildProgramCard(program);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
