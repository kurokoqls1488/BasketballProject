import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import 'exercise_detail.dart';
import 'exercises_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _favoriteWorkouts = [];
  List<Map<String, dynamic>> _favoriteExercises = [];
  Set<int> _favoriteWorkoutIds = {};
  bool _isLoading = true;
  late TabController _tabController;

  String _t(String key) => LocaleService.translate(key);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

    Future<void> _loadFavorites() async {
      setState(() => _isLoading = true);
      final workouts = await _authService.fetchFavoriteWorkouts();
      final exercises = await _authService.fetchFavoriteExercises();
      if (mounted) {
        // Enrich workouts with first exercise image (like in workouts_page.dart)
        final enrichedWorkouts = <Map<String, dynamic>>[];
        for (final workout in workouts) {
          final workoutMap = Map<String, dynamic>.from(workout);
          // If workout doesn't have an image or it's empty, try to get it from first exercise
          final workoutImage = workoutMap['image'];
          final hasImage = workoutImage != null && workoutImage.toString().isNotEmpty;
          if (!hasImage &&
              workoutMap['id'] != null) {
            // Fetch exercises for this workout to get the first image
            try {
              final workoutExercises = await _authService.fetchExercises(workoutMap['id'] as int);
              if (workoutExercises.isNotEmpty) {
                final firstExercise = workoutExercises.first;
                final exerciseImage = firstExercise['image'] as String?;
                if (exerciseImage != null && exerciseImage.isNotEmpty) {
                  workoutMap['image'] = exerciseImage;
                }
              }
            } catch (e) {
              debugPrint('Error fetching exercises for workout ${workoutMap['id']}: $e');
            }
          }
          enrichedWorkouts.add(workoutMap);
        }
        setState(() {
          _favoriteWorkouts = enrichedWorkouts;
          _favoriteExercises = List<Map<String, dynamic>>.from(exercises);
          _favoriteWorkoutIds = _favoriteWorkouts.map((w) => w['id'] as int).toSet();
          _isLoading = false;
        });
      }
    }

   Future<void> _toggleFavoriteWorkout(int workoutId) async {
     final isFavorite = _favoriteWorkoutIds.contains(workoutId);
     if (isFavorite) {
       await _authService.removeWorkoutFromFavorites(workoutId);
     } else {
       await _authService.addWorkoutToFavorites(workoutId);
     }
     await _loadFavorites();
   }

    Widget _buildWorkoutCard(Map<String, dynamic> workout) {
      final workoutId = workout['id'] as int;
      final rawWorkoutName = workout['name_workout'] ?? workout['name'] ?? 'Тренировка';
      final workoutName = LocaleService.translateDbData(rawWorkoutName);
      final duration = workout['duration'] as int? ?? 0;
      final image = workout['image'] ?? '';

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
                  builder: (context) => ExercisesPage(
                    workoutId: workoutId,
                    workoutName: workoutName,
                  ),
                ),
              );
            },
            child: SizedBox(
              height: 130,
              child: Row(
                children: [
Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                workoutName,
                                style: const TextStyle(
                                  color: Color(0xFFFF4500),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${duration} мин",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                   const Spacer(),
                                   if (_authService.isLoggedIn)
                                    IconButton(
                                      icon: Icon(
                                        _favoriteWorkoutIds.contains(workoutId)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _toggleFavoriteWorkout(workoutId),
                                    ),
                                ],
                              ),
                            ],
                          ),
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
                      child: image.isNotEmpty
                          ? (image.startsWith('http')
                              ? Image.network(
                                  image,
                                  fit: BoxFit.fitHeight,
                                  errorBuilder: (c, e, s) => Image.asset(
                                    'images/pustoe_photo.png',
                                    fit: BoxFit.fitHeight,
                                  ),
                                )
                              : Image.asset(
                                  image.startsWith('images/')
                                      ? image
                                      : 'images/$image',
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

    Widget _buildExerciseCard(Map<String, dynamic> exercise) {
     final exerciseId = exercise['id'] as int;
     final rawName = (exercise['name_exercise'] as String?)?.isNotEmpty == true
         ? exercise['name_exercise'] as String
         : 'Exercise';
      final exerciseName = LocaleService.translateDbData(rawName);
      final image = exercise['image'] ?? '';

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
                     builder: (context) => ExerciseDetailPage(
                       exerciseId: exerciseId,
                       nameExercise: rawName,
                       image: image,
                       video: exercise['video'] as String?,
                       description: exercise['description'] ?? '',
                       recommendedDurationSeconds: exercise['recommended_duration_seconds'] as int?,
                     ),
               ),
             );
           },
            child: SizedBox(
              height: 120,
              child: Row(
                children: [
Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                exerciseName,
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
                    ),
                  if (_authService.isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () async {
    SettingsService.vibrate();
                          await _authService.removeExerciseFromFavorites(exerciseId);
                          _loadFavorites();
                        },
                      ),
                    ),
                   Expanded(
                     flex: 0,
                     child: ClipRRect(
                       borderRadius: const BorderRadius.only(
                         topLeft: Radius.circular(15),
                         bottomLeft: Radius.circular(15),
                       ),
                       child: image.isNotEmpty
                           ? (image.startsWith('http')
                               ? Image.network(
                                   image,
                                   fit: BoxFit.fitHeight,
                                   errorBuilder: (c, e, s) => Image.asset(
                                     'images/pustoe_photo.png',
                                     fit: BoxFit.fitHeight,
                                   ),
                                 )
                               : Image.asset(
                                   image.startsWith('images/')
                                       ? image
                                       : 'images/$image',
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
        if (!SettingsService.backgroundEnabled)
          Positioned.fill(
            child: Image.asset('images/basketball_fon.jpg', fit: BoxFit.cover),
          ),
        Container(
          color: !SettingsService.backgroundEnabled ? Colors.black.withOpacity(0.3) : const Color(0xFF121212),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(_t('Избранное')),
              backgroundColor: !SettingsService.backgroundEnabled ? Colors.transparent : const Color(0xFF1A1A1A),
              foregroundColor: const Color(0xFFFFA500),
              centerTitle: true,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF4500),
                labelColor: const Color(0xFFFFA500),
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: _t('Тренировки')),
                  Tab(text: _t('Упражнения')),
                ],
              ),
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF4500)),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Вкладка тренировок
                      _favoriteWorkouts.isEmpty
                          ? Center(
                              child: Text(
                                _t('Нет избранных тренировок'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFavorites,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 10, bottom: 20),
                                itemCount: _favoriteWorkouts.length,
                                itemBuilder: (context, index) {
                                  return _buildWorkoutCard(_favoriteWorkouts[index]);
                                },
                              ),
                            ),
                      // Вкладка упражнений
                      _favoriteExercises.isEmpty
                          ? Center(
                              child: Text(
                                _t('Нет избранных упражнений'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFavorites,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 10, bottom: 20),
                                itemCount: _favoriteExercises.length,
                                itemBuilder: (context, index) {
                                  return _buildExerciseCard(_favoriteExercises[index]);
                                },
                              ),
                            ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
