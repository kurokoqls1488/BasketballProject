import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import 'dart:async';

class ProgramExercisePage extends StatefulWidget {
  final int userProgramId;
  final int dayNumber;
  final int programId;
  final int workoutId;
  final int startIndex;

  const ProgramExercisePage({
    super.key,
    required this.userProgramId,
    required this.dayNumber,
    required this.programId,
    required this.workoutId,
    this.startIndex = 0,
  });

  @override
  State<ProgramExercisePage> createState() => _ProgramExercisePageState();
}

class _ProgramExercisePageState extends State<ProgramExercisePage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _exercises = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isTimerRunning = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showTimerComplete = false;
  Timer? _longPressTimer;

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    try {
      await _authService.initializeDayExercises(
        widget.userProgramId,
        widget.dayNumber,
        widget.workoutId,
      );
    } catch (e) {
      debugPrint('Error initializing day exercises: $e');
    }
    await _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final exercises = await _authService.fetchDayExercises(
        widget.userProgramId,
        widget.dayNumber,
      );
      if (mounted) {
        setState(() {
          _exercises = List<Map<String, dynamic>>.from(exercises);
          _isLoading = false;
          if (_exercises.isNotEmpty) {
            _currentIndex = widget.startIndex.clamp(0, _exercises.length - 1);
            _startTimerForCurrentExercise();
            final currentExercise = _exercises[_currentIndex];
            final exercise =
                currentExercise['exercise'] as Map<String, dynamic>?;
            final videoUrl = exercise?['video'] as String?;
            _initializeVideo(videoUrl);
          }
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

  void _startTimerForCurrentExercise() {
    _timer?.cancel();
    final currentExercise = _exercises[_currentIndex];
    final durationSeconds =
        currentExercise['exercise']['recommendedDurationSeconds'] as int?;
    if (durationSeconds == null || durationSeconds <= 0) {
      setState(() {
        _remainingSeconds = 0;
        _isTimerRunning = false;
        _showTimerComplete = false;
      });
      return;
    }
    setState(() {
      _remainingSeconds = durationSeconds;
      _isTimerRunning = true;
      _showTimerComplete = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      bool timerFinished = false;
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else if (_remainingSeconds == 1) {
          _remainingSeconds = 0;
          _isTimerRunning = false;
          _showTimerComplete = true;
          timerFinished = true;
        }
      });
      if (timerFinished) {
        timer.cancel();
        SettingsService.vibrate();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resumeTimer() {
    if (_remainingSeconds > 0 && !_isTimerRunning) {
      setState(() {
        _isTimerRunning = true;
        _showTimerComplete = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        bool timerFinished = false;
        setState(() {
          if (_remainingSeconds > 1) {
            _remainingSeconds--;
          } else if (_remainingSeconds == 1) {
            _remainingSeconds = 0;
            _isTimerRunning = false;
            _showTimerComplete = true;
            timerFinished = true;
          }
        });
        if (timerFinished) {
          timer.cancel();
          SettingsService.vibrate();
        }
      });
    }
  }

  void _toggleTimer() {
    SettingsService.vibrate();
    if (_remainingSeconds <= 0) return;
    setState(() {
      if (_isTimerRunning) {
        _pauseTimer();
      } else {
        _resumeTimer();
      }
    });
  }

  void _startAddTimeLongPress() {
    _longPressTimer?.cancel();
    int increment = 30;
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _remainingSeconds += increment;
        _showTimerComplete = false;
        increment += 5;
      });
    });
    _addTime(30);
  }

  void _startSubtractTimeLongPress() {
    _longPressTimer?.cancel();
    int decrement = 30;
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _remainingSeconds =
            (_remainingSeconds - decrement).clamp(0, 23 * 3600 + 59 * 60 + 59);
        _showTimerComplete = false;
        decrement += 5;
      });
    });
    _subtractTime(30);
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
      _showTimerComplete = false;
    });
  }

  void _subtractTime(int seconds) {
    setState(() {
      _remainingSeconds =
          (_remainingSeconds - seconds).clamp(0, 23 * 3600 + 59 * 60 + 59);
      _showTimerComplete = false;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSetTimerDialog() {
    int tempMinutes = _remainingSeconds ~/ 60;
    int tempSeconds = _remainingSeconds % 60;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(_t('Установить время'),
              style: const TextStyle(color: Color(0xFFFFA500))),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: _t('мин'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  onChanged: (value) {
                    tempMinutes = int.tryParse(value) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: _t('сек'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  onChanged: (value) {
                    tempSeconds = int.tryParse(value) ?? 0;
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('Отмена'),
                  style: const TextStyle(color: Color(0xFFFFA500))),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _remainingSeconds = tempMinutes * 60 + tempSeconds;
                  _showTimerComplete = false;
                });
                Navigator.pop(context);
              },
              child: Text(_t('ОК'),
                  style: const TextStyle(color: Color(0xFFFFA500))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFA500), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA500).withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showSetTimerDialog,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.width * 0.02,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(Duration(seconds: _remainingSeconds)),
                style: TextStyle(
                  color: _showTimerComplete
                      ? Colors.green
                      : const Color(0xFFFFA500),
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _subtractTime(30),
                onLongPress: _startSubtractTimeLongPress,
                onLongPressEnd: (_) => _stopLongPress(),
                child: const Icon(Icons.remove,
                    color: Color(0xFFFFA500), size: 20),
              ),
              IconButton(
                onPressed: _toggleTimer,
                icon: Icon(
                  _isTimerRunning ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFFFFA500),
                  size: 24,
                ),
                padding: const EdgeInsets.all(4),
              ),
              GestureDetector(
                onTap: () => _addTime(30),
                onLongPress: _startAddTimeLongPress,
                onLongPressEnd: (_) => _stopLongPress(),
                child:
                    const Icon(Icons.add, color: Color(0xFFFFA500), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleComplete() async {
    final currentExercise = _exercises[_currentIndex];
    final progressId = currentExercise['progressId'] as int;
    final isCompleted = currentExercise['completed'] as bool;
    try {
      if (isCompleted) {
        await _authService.markExerciseIncomplete(progressId);
        setState(() {
          _exercises[_currentIndex]['completed'] = false;
        });
      } else {
        await _authService.markExerciseCompleted(progressId);
        setState(() {
          _exercises[_currentIndex]['completed'] = true;
        });
      }
    } catch (e) {
      debugPrint('Error toggling completion: $e');
      _loadExercises();
    }
  }

  Future<void> _initializeVideo(String? videoPath) async {
    await _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    if (videoPath == null || videoPath.isEmpty) {
      return;
    }

    try {
      String path;
      if (videoPath.startsWith('videos/')) {
        path = videoPath;
      } else {
        path = 'videos/$videoPath';
      }

      _videoController = VideoPlayerController.asset(path);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setPlaybackSpeed(0.5);
      _videoController!.addListener(_onVideoUpdate);
      await _videoController!.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading video: $e');
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _pauseTimer();
      } else {
        _videoController!.play();
        _resumeTimer();
      }
    });
  }

  bool _isVideoPlaying() {
    return _videoController != null && _videoController!.value.isPlaying;
  }

  Future<void> _goToNext() async {
    if (_currentIndex < _exercises.length - 1) {
      _timer?.cancel();
      setState(() {
        _currentIndex++;
      });
      _startTimerForCurrentExercise();
      final currentExercise = _exercises[_currentIndex];
      final exercise = currentExercise['exercise'] as Map<String, dynamic>?;
      final videoUrl = exercise?['video'] as String?;
      _initializeVideo(videoUrl);
    } else {
      await _completeDay();
      _timer?.cancel();
      setState(() {
        _isTimerRunning = false;
      });
    }
  }

  Future<void> _goToPrevious() async {
    if (_currentIndex > 0) {
      _timer?.cancel();
      setState(() {
        _currentIndex--;
      });
      _startTimerForCurrentExercise();
      final currentExercise = _exercises[_currentIndex];
      final exercise = currentExercise['exercise'] as Map<String, dynamic>?;
      final videoUrl = exercise?['video'] as String?;
      _initializeVideo(videoUrl);
    }
  }

  Future<void> _completeDay() async {
    try {
      await _authService.completeDay(widget.userProgramId, widget.dayNumber);
      if (mounted) {
        _showDayCompleteDialog();
      }
    } catch (e) {
      debugPrint('Error completing day: $e');
    }
  }

  void _showDayCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFFFA500), size: 30),
            const SizedBox(width: 10),
            Text(
              _t('День завершен!'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          _t('Вы завершили все упражнения на сегодня. Отлично работа!'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: Text(
              _t('Готово'),
              style: const TextStyle(color: Color(0xFFFFA500)),
            ),
          ),
        ],
      ),
    );
  }

  double get _dayProgress {
    if (_exercises.isEmpty) return 0.0;
    final completedCount =
        _exercises.where((e) => e['completed'] as bool).length;
    return completedCount / _exercises.length;
  }

  Widget _buildMediaContent() {
    final currentExercise = _exercises[_currentIndex];
    final exercise = currentExercise['exercise'] as Map<String, dynamic>?;
    final videoUrl = exercise?['video'] as String?;
    final image = exercise?['image'] as String? ?? '';

    if (videoUrl != null &&
        videoUrl.isNotEmpty &&
        _isVideoInitialized &&
        _videoController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _VideoPlayerControls(
              _videoController!,
              onToggle: _togglePlayPause,
            ),
          ),
        ],
      );
    }

    if (image.startsWith('http')) {
      return Image.network(
        _authService.getImageUrl(image),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'images/pustoe_photo.png',
          fit: BoxFit.cover,
        ),
      );
    }
    if (image.isNotEmpty) {
      final assetPath = image.startsWith('images/') ? image : 'images/$image';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'images/pustoe_photo.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset('images/pustoe_photo.png', fit: BoxFit.cover);
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
            foregroundColor: const Color(0xFFFFA500),
            title: Text('${_t('День')} ${widget.dayNumber}'),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  value: _dayProgress,
                  backgroundColor: Colors.grey[800],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFFA500)),
                  minHeight: 4,
                ),
              ),
            ),
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
                          Text(
                            '${_t('Ошибка:')} $_error',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadExercises,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                            ),
                            child: Text(_t('Повторить')),
                          ),
                        ],
                      ),
                    )
                  : _exercises.isEmpty
                      ? Center(
                          child: Text(
                            _t('Упражнения не найдены'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : _buildExerciseView(),
        ),
      ],
    );
  }

  Widget _buildExerciseView() {
    final currentExercise = _exercises[_currentIndex];
    final exercise = currentExercise['exercise'] as Map<String, dynamic>;
    final rawName = (exercise['name'] as String?)?.isNotEmpty == true
        ? exercise['name'] as String
        : null;
    final nameExercise = rawName != null
        ? LocaleService.translateDbData(rawName)
        : _t('Exercise');
    final description = exercise['description'] as String? ?? '';
    final isCompleted = currentExercise['completed'] as bool;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _dayProgress,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFA500)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_exercises.where((e) => e['completed'] as bool).length}/${_exercises.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: const Color(0xFFFFA500), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _buildMediaContent(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameExercise,
                        style: const TextStyle(
                          color: Color(0xFFFF4500),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFA500),
                              const Color(0xFFDC143C).withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _t('Описание'),
                        style: const TextStyle(
                          color: Color(0xFFFFA500),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        LocaleService.translateDbData(description).isNotEmpty
                            ? LocaleService.translateDbData(description)
                            : _t('Описание упражнения пока недоступно'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: _buildTimerBar(),
        ),
        // Bottom navigation buttons
        Positioned(
          bottom: 110,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          SettingsService.vibrate();
                          _goToPrevious();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      Text(_t('Назад')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    SettingsService.vibrate();
                    final currentCompleted = isCompleted;
                    if (!currentCompleted) {
                      await _toggleComplete();
                    }
                    await _goToNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentIndex < _exercises.length - 1
                            ? _t('Далее')
                            : _t('Завершить день'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_currentIndex < _exercises.length - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ],
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

class _VideoPlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onToggle;

  const _VideoPlayerControls(this.controller, {required this.onToggle});

  @override
  State<_VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<_VideoPlayerControls> {
  Timer? _progressTimer;
  bool _wasPlayingBeforeDrag = false;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final duration = controller.value.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: widget.onToggle,
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Slider(
              value: controller.value.position.inMilliseconds.toDouble(),
              min: 0,
              max: duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1,
              onChangeStart: (value) {
                _wasPlayingBeforeDrag = controller.value.isPlaying;
                controller.pause();
              },
              onChanged: (value) {
                controller.seekTo(Duration(milliseconds: value.round()));
              },
              onChangeEnd: (value) {
                if (_wasPlayingBeforeDrag) {
                  controller.play();
                }
              },
              activeColor: const Color(0xFFFFA500),
              inactiveColor: Colors.white54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatDuration(Duration(milliseconds: (controller.value.position.inMilliseconds * 2).round()))} / ${_formatDuration(Duration(milliseconds: (duration.inMilliseconds * 2).round()))}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
