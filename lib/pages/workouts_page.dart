import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../pages/exercises_page.dart';

class Workout {
  final int id;
  final String name;
  final int? duration;
  final int? complexId;
  final String? image;

  Workout({
    required this.id,
    required this.name,
    this.duration,
    this.complexId,
    this.image,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] ?? 0,
      name: json['name_workout'] ?? json['name'] ?? '',
      duration: json['duration'],
      complexId: json['id_complex'] ?? json['complex_id'],
      image: json['image'], // image — это поле из БД (Supabase)
    );
  }

  String get translatedName => LocaleService.translateDbData(name);
}


class Complex {
  final String _nameComplex;
  final int id;
  final String? image;

  Complex({required this.id, required String nameComplex, this.image})
    : _nameComplex = nameComplex;

  factory Complex.fromJson(Map<String, dynamic> json) {
    debugPrint('Complex.fromJson received: $json');
    final id = json['id'] ?? 0;
    final nameComplex = json['name_complex'] ?? json['name'] ?? '';
    final image = json['image'];
    debugPrint('Complex.fromJson parsed: id=$id, name="$nameComplex", image=$image');
    return Complex(
      id: id,
      nameComplex: nameComplex,
      image: image,
    );
  }

  String get nameComplex => _nameComplex;

  String get translatedName => LocaleService.translateDbData(_nameComplex);
}

class WorkoutsPage extends StatefulWidget {
  final Complex complex;

  const WorkoutsPage({super.key, required this.complex});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final AuthService _authService = AuthService();
  List<Workout>? _cachedWorkouts;
  Set<int> _favoriteWorkoutIds = {};
  bool _isLoading = true;
  String? _error;

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    LocaleService.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() async {
    await AuthService.clearCaches();
    if (mounted) {
      _loadWorkouts();
    }
  }

  @override
  void dispose() {
    LocaleService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    try {
      final response = await _authService.fetchWorkouts(widget.complex.id);
      _favoriteWorkoutIds = {};
      for (final json in response) {
        final workoutId = json['id'] as int;
        if (await _authService.isWorkoutFavorite(workoutId)) {
          _favoriteWorkoutIds.add(workoutId);
        }
      }

      // Загружаем первое упражнение для каждой тренировки
      final List<Workout> workoutsWithImages = [];
      for (final json in response) {
        final workoutId = json['id'] as int;
        // Получаем упражнения этой тренировки
        final exercises = await _authService.fetchExercises(workoutId);
        String? firstImage;
        if (exercises.isNotEmpty) {
          firstImage = exercises.first['image'] as String?;
        }
        workoutsWithImages.add(Workout(
          id: workoutId,
          name: json['name_workout'] ?? json['name'] ?? '',
          duration: json['duration'],
          complexId: json['id_complex'] ?? json['complex_id'],
          image: firstImage,
        ));
      }

      if (mounted) {
        setState(() {
          _cachedWorkouts = workoutsWithImages;
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

  Future<void> _toggleFavorite(Workout workout) async {
    final isFavorite = _favoriteWorkoutIds.contains(workout.id);
    if (isFavorite) {
      await _authService.removeWorkoutFromFavorites(workout.id);
      _favoriteWorkoutIds.remove(workout.id);
    } else {
      await _authService.addWorkoutToFavorites(workout.id);
      _favoriteWorkoutIds.add(workout.id);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildWorkoutCard(Workout workout) {
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
            SettingsService.playClickSound();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExercisesPage(
                  workoutId: workout.id,
                  workoutName: workout.translatedName.isNotEmpty
                      ? workout.translatedName
                      : 'Тренировка',
                ),
              ),
            );
          },
          child: SizedBox(
            height: 130,
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
                          workout.translatedName.isNotEmpty
                              ? workout.translatedName
                              : 'Тренировка',
                          style: const TextStyle(
                            color: Color(0xFFFF4500),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Row(
                             children: [
                               const Icon(
                                 Icons.timer_outlined,
                                 color: Colors.white70,
                                 size: 18,
                               ),
                               const SizedBox(width: 6),
                               Text(
                                 "${workout.duration ?? 0} ${_t('мин.')}",
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontSize: 16,
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                                const Spacer(),
                                if (_authService.isLoggedIn)
                                  IconButton(
                                    icon: Icon(
                                      _favoriteWorkoutIds.contains(workout.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleFavorite(workout),
                                  ),
                             ],
                           ),
                      ],
                    ),
                  ),
                ),
                 Expanded(
                   flex: 0,
                   child: ClipRRect(
                     borderRadius: const BorderRadius.only(
                       topLeft: Radius.circular(15),
                       bottomLeft: Radius.circular(15),
                     ),
                     child: workout.image != null && workout.image!.isNotEmpty
                         ? (workout.image!.startsWith('http')
                             ? Image.network(
                                 workout.image!,
                                 fit: BoxFit.fitHeight,
                                 errorBuilder: (c, e, s) => Image.asset(
                                   'images/pustoe_photo.png',
                                   fit: BoxFit.fitHeight,
                                 ),
                               )
                             : Image.asset(
                                 workout.image!.startsWith('images/')
                                     ? workout.image!
                                     : 'images/${workout.image!}',
                                 fit: BoxFit.fitHeight,
                                 errorBuilder: (c, e, s) => Image.asset(
                                   'images/pustoe_photo.png',
                                   fit: BoxFit.fitHeight,
                                 ),
                               ))
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
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              widget.complex.translatedName,
              style: const TextStyle(color: Color(0xFFFFA500), fontSize: 20),
            ),
          ),
          body: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFA500)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _t('Ошибка загрузки'),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadWorkouts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
              ),
              child: Text(_t('Повторить')),
            ),
          ],
        ),
      );
    }

    if (_cachedWorkouts == null || _cachedWorkouts!.isEmpty) {
      return Center(
        child: Text(
          _t('Нет тренировок'),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: _cachedWorkouts!.length,
      itemBuilder: (context, index) {
        return _buildWorkoutCard(_cachedWorkouts![index]);
      },
    );
  }
}
