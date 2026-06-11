import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';

class ExerciseDetailPage extends StatefulWidget {
  final int exerciseId;
  final String nameExercise;
  final String image;
  final String? video;
  final String description;
  final int? recommendedDurationSeconds;

  const ExerciseDetailPage({
    super.key,
    required this.exerciseId,
    required this.nameExercise,
    required this.image,
    this.video,
    required this.description,
    this.recommendedDurationSeconds,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _showTimerComplete = false;

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.recommendedDurationSeconds ?? 0;
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _timer?.cancel();
    _longPressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.video == null || widget.video!.isEmpty) {
      return;
    }

    try {
      String videoPath;
      if (widget.video!.startsWith('videos/')) {
        videoPath = widget.video!;
      } else {
        videoPath = 'videos/${widget.video}';
      }

      _videoController = VideoPlayerController.asset(videoPath)
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          _videoController!.setPlaybackSpeed(0.5);
          _videoController!.play();
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
        });
    } catch (e, stack) {
      debugPrint('Error loading video: $e\n$stack');
    }
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

  void _startTimer() {
    if (_isTimerRunning || _remainingSeconds <= 0) return;

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

    _isTimerRunning = true;
  }

  void _pauseTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
      _showTimerComplete = false;
    });
  }

  Timer? _longPressTimer;

  void _startAddTimeLongPress() {
    _longPressTimer?.cancel();
    int increment = 30; // Начальный прирост
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _remainingSeconds += increment;
        _showTimerComplete = false;
        increment += 5; // Увеличиваем прирост каждый тик
      });
    });
    _addTime(30); // Начальное добавление
  }

  void _startSubtractTimeLongPress() {
    _longPressTimer?.cancel();
    int decrement = 30;
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _remainingSeconds = (_remainingSeconds - decrement).clamp(0, 23 * 3600 + 59 * 60 + 59);
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

  void _subtractTime(int seconds) {
    setState(() {
      _remainingSeconds = (_remainingSeconds - seconds).clamp(0, 23 * 3600 + 59 * 60 + 59);
      _showTimerComplete = false;
    });
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final translatedName = LocaleService.translateDbData(widget.nameExercise);
    final translatedDesc = LocaleService.translateDbData(widget.description);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(translatedName),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFFFA500),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('images/basketball_fon.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: const Color(0xFFFFA500), width: 2),
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _buildMediaContent(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translatedName,
                          style: const TextStyle(
                            color: Color(0xFFFF4500),
                            fontSize: 28,
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
                          LocaleService.translate('Описание'),
                          style: const TextStyle(
                            color: Color(0xFFFFA500),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          translatedDesc.isNotEmpty
                              ? translatedDesc
                              : LocaleService.translate(
                                  'Описание упражнения пока недоступно',
                                ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 100),
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
        ],
      ),
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
          // Timer display
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
                  color: _showTimerComplete ? Colors.green : const Color(0xFFFFA500),
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
// Controls row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _subtractTime(30),
                onLongPress: _startSubtractTimeLongPress,
                onLongPressEnd: (_) => _stopLongPress(),
                child: const Icon(Icons.remove, color: Color(0xFFFFA500), size: 20),
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
                child: const Icon(Icons.add, color: Color(0xFFFFA500), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSetTimerDialog() {
    int tempMinutes = _remainingSeconds ~/ 60;
    int tempSeconds = _remainingSeconds % 60;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(_t('Установить время'), style: const TextStyle(color: Color(0xFFFFA500))),
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
              child: Text(_t('Отмена'), style: const TextStyle(color: Color(0xFFFFA500))),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _remainingSeconds = tempMinutes * 60 + tempSeconds;
                  _showTimerComplete = false;
                });
                Navigator.pop(context);
              },
              child: Text(_t('ОК'), style: const TextStyle(color: Color(0xFFFFA500))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaContent() {
    if (widget.video != null && widget.video!.isNotEmpty && _isVideoInitialized && _videoController != null) {
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
            bottom: 0, left: 0, right: 0,
            child: _VideoPlayerControls(
              _videoController!,
              onToggle: _togglePlayPause,
            ),
          ),
        ],
      );
    }

    if (widget.image.startsWith('http')) {
      return Image.network(
        widget.image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'images/pustoe_photo.png', fit: BoxFit.cover,
        ),
      );
    }
    if (widget.image.isNotEmpty) {
      final assetPath = widget.image.startsWith('images/')
          ? widget.image
          : 'images/${widget.image}';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'images/pustoe_photo.png', fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset('images/pustoe_photo.png', fit: BoxFit.cover);
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
              max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
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