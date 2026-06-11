import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import 'exercise_detail.dart';

class Exercise {
  final int id;
  final String _nameExercise;
  final String image;
  final String _description;
  final String? video;
  final int? recommendedDurationSeconds;

  Exercise({
    required this.id,
    required String nameExercise,
    required this.image,
    required String description,
    this.video,
    this.recommendedDurationSeconds,
  })  : _nameExercise = nameExercise,
        _description = description;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? 0,
      nameExercise: json['name_exercise'] ?? json['name'] ?? 'Без названия',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      video: json['video'] as String?,
      recommendedDurationSeconds: json['recommended_duration_seconds'] as int?,
    );
  }

  String get nameExercise => LocaleService.translateDbData(_nameExercise);
  String get description => LocaleService.translateDbData(_description);
}

class ExercisesPage extends StatefulWidget {
  final int workoutId;
  final String workoutName;

  const ExercisesPage({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final AuthService _authService = AuthService();
  List<Exercise>? _cachedExercises;
  Set<int> _favoriteExerciseIds = {};
  bool _isLoading = true;
  String? _error;

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _loadFavoriteExercises();
    LocaleService.addListener(_onLanguageChanged);
  }

  Future<void> _loadFavoriteExercises() async {
    try {
      final response = await _authService.fetchFavoriteExercises();
      final Set<int> favoriteIds = {};
      for (final json in response) {
        final exerciseId = json['id'] as int?;
        if (exerciseId != null) {
          favoriteIds.add(exerciseId);
          AuthService.updateExerciseFavoriteCache(exerciseId, true);
        }
      }
      if (mounted) {
        setState(() {
          _favoriteExerciseIds = favoriteIds;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorite exercises: $e');
    }
  }

  Future<void> _toggleFavoriteExercise(Exercise exercise) async {
    final isFavorite = _favoriteExerciseIds.contains(exercise.id);
    if (isFavorite) {
      await _authService.removeExerciseFromFavorites(exercise.id);
      _favoriteExerciseIds.remove(exercise.id);
    } else {
      await _authService.addExerciseToFavorites(exercise.id);
      _favoriteExerciseIds.add(exercise.id);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onLanguageChanged() async {
    await AuthService.clearCaches();
    if (mounted) {
      _loadExercises();
    }
  }

  @override
  void dispose() {
    LocaleService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final response = await _authService.fetchExercises(widget.workoutId);
      if (mounted) {
        setState(() {
          _cachedExercises =
              response.map((json) => Exercise.fromJson(json)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('images/basketball_fon.jpg', fit: BoxFit.cover),
        ),
        Container(
          color: Colors.black.withOpacity(0.3),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(widget.workoutName),
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: const Color(0xFFFFA500),
              centerTitle: true,
            ),
            body: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4500)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            '${_t('Ошибка:')} $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final exercises = _cachedExercises ?? [];

    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _t('Упражнения не найдены'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                SettingsService.vibrate();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseDetailPage(
                      exerciseId: ex.id,
                      nameExercise: ex.nameExercise,
                      image: ex.image,
                      video: ex.video,
                      description: ex.description,
                      recommendedDurationSeconds: ex.recommendedDurationSeconds,
                    ),
                  ),
                );
              },
              child: SizedBox(
                height: 120,
                child: Row(
                  children: [
                    // Текст упражнения (слева, растягивается)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ex.nameExercise,
                              style: const TextStyle(
                                color: Color(0xFFFF4500),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Сердечко (слева от фото)
                    if (_authService.isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: IconButton(
                          icon: Icon(
                            _favoriteExerciseIds.contains(ex.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _toggleFavoriteExercise(ex),
                        ),
                      ),
                    // Фото (справа, фиксированная ширина, закругления слева because it's on the right edge)
                    Expanded(
                      flex: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                        child: ex.image.isNotEmpty
                            ? ex.image.startsWith('http')
                                ? Image.network(
                                    ex.image,
                                    fit: BoxFit.fitHeight,
                                    errorBuilder: (c, e, s) => Image.asset(
                                      'images/pustoe_photo.png',
                                      fit: BoxFit.fitHeight,
                                    ),
                                  )
                                : Image.asset(
                                    ex.image.startsWith('images/')
                                        ? ex.image
                                        : 'images/${ex.image}',
                                    fit: BoxFit.fitHeight,
                                    errorBuilder: (c, e, s) => Image.asset(
                                      'images/pustoe_photo.png',
                                      fit: BoxFit.fitHeight,
                                    ),
                                  )
                            : Image.asset(
                                'images/pustoe_photo.png',
                                fit: BoxFit.fitHeight,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
