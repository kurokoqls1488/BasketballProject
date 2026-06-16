import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../models/program_day.dart';
import '../pages/day_detail_page.dart';

class ProgramDaysPage extends StatefulWidget {
  final int programId;
  final String programName;
  final String programDescription;
  final String? programImage;

  const ProgramDaysPage({
    super.key,
    required this.programId,
    required this.programName,
    required this.programDescription,
    this.programImage,
  });

  @override
  State<ProgramDaysPage> createState() => _ProgramDaysPageState();
}

class _ProgramDaysPageState extends State<ProgramDaysPage> {
  final AuthService _authService = AuthService();
  List<DayWithWorkout> _days = [];
  Map<int, bool> _dayCompletionStatus = {};
  Map<int, double> _dayProgressCache = {};
  bool _isLoading = true;
  String? _error;

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  Future<void> _loadDays() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final days = await _authService.fetchProgramDays(widget.programId);
      final userProgramId = await _authService.getOrCreateUserProgram(widget.programId);

      List<DayWithWorkout> dayList = [];
      for (final day in days) {
        final workoutId = day['id_workout'] as int?;
        dayList.add(DayWithWorkout(
          programDay: ProgramDay.fromJson(day),
          workoutId: workoutId,
          workoutName: _t('Workout'),
        ));
      }

      Map<int, bool> completionMap = {};
      Map<int, double> progressMap = {};
      if (userProgramId != null) {
        final userProg = await _authService.getUserProgram(userProgramId);
        completionMap = await _authService.fetchDayCompletionStatuses(userProgramId);
        final dayProgress = userProg?['day_progress'] as Map<String, dynamic>? ?? {};
        for (final day in days) {
          final dayNum = day['day_number'] as int? ?? 0;
          if (dayNum > 0) {
            final dayStats = dayProgress[dayNum.toString()] as Map<String, dynamic>?;
            progressMap[dayNum] = ((dayStats?['percent'] as num?)?.toDouble() ?? 0.0) / 100.0;
          }
        }
      }

      if (mounted) {
        setState(() {
          _days = dayList;
          _dayCompletionStatus = completionMap;
          _dayProgressCache = progressMap;
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

  bool _isDayUnlocked(int dayNumber) {
    if (dayNumber <= 1) return true;
    return _dayCompletionStatus[dayNumber - 1] ?? false;
  }

  Widget _buildDayCard(DayWithWorkout day, bool isCompleted) {
    final bool unlocked = _isDayUnlocked(day.programDay.dayNumber);
    final double progress = _dayProgressCache[day.programDay.dayNumber] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: isCompleted
            ? const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : unlocked
                ? const LinearGradient(
                    colors: [Color(0xFFFFA500), Color(0xFFDC143C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.grey, Colors.grey],
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
        child: unlocked
            ? InkWell(
                onTap: () {
                  SettingsService.vibrate();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DayDetailPage(
                        programId: widget.programId,
                        programName: widget.programName,
                        dayNumber: day.programDay.dayNumber,
                        workoutId: day.workoutId,
                        isCompleted: isCompleted,
                      ),
                    ),
                  ).then((_) {
                    // Refresh data when returning from DayDetailPage
                    _loadDays();
                  });
                },
                child: SizedBox(
                  height: 140,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_t('Day')} ${day.programDay.dayNumber}',
                                style: const TextStyle(
                                  color: Color(0xFFFF4500),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                day.workoutName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA500)),
                                minHeight: 6,
                              ),
                              const SizedBox(height: 6),
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
                                  const SizedBox(width: 12),
                                  Icon(
                                    isCompleted ? Icons.check_circle : Icons.update,
                                    color: isCompleted ? const Color(0xFF4CAF50) : (progress > 0 ? Color(0xFFFFA500) : Colors.white54),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isCompleted ? _t('Completed') : (progress > 0 ? _t('In progress') : _t('Not started')),
                                    style: TextStyle(
                                      color: isCompleted ? const Color(0xFF4CAF50) : (progress > 0 ? Colors.white70 : Colors.white54),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(right: 15),
                          child: Icon(Icons.arrow_forward, color: Color(0xFFFFA500), size: 24),
                        ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_t('Day')} ${day.programDay.dayNumber}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              day.workoutName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Icon(Icons.lock_outline, color: Colors.grey, size: 24),
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
              LocaleService.translateDbData(widget.programName),
              style: const TextStyle(color: Color(0xFFFFA500), fontSize: 20),
              overflow: TextOverflow.ellipsis,
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
                            onPressed: _loadDays,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                            ),
                            child: Text(_t('Retry')),
                          ),
                        ],
                      ),
                    )
                  : _days.isEmpty
                      ? Center(
                          child: Text(
                            _t('No days found'),
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 10, bottom: 80),
                          itemCount: _days.length,
                          itemBuilder: (context, index) {
                            final day = _days[index];
                            final isCompleted = _dayCompletionStatus[day.programDay.dayNumber] ?? false;
                            return _buildDayCard(day, isCompleted);
                          },
                        ),
        ),
      ],
    );
  }
}
