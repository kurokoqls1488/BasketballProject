import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class AuthService {
  static final Map<int, List<dynamic>> _workoutsCache = {};
  static final Map<int, List<dynamic>> _exercisesCache = {};
  static final Map<int, bool> _favoritesCache = {};
  static final Map<int, bool> _exerciseFavoritesCache = {};
  static Set<int> _favoriteWorkoutIdsCache = {};
  static bool _favoriteWorkoutIdsLoaded = false;
  static final Map<String, List<dynamic>> _dayExercisesCache = {};
  static List<dynamic>? _complexesCache;
  static List<dynamic>? _programsCache;
  static List<Map<String, dynamic>>? _programsProgressCache;
  static DateTime? _programsProgressCacheTime;
  static final Map<int, List<dynamic>> _programDaysCache = {};
  static final Map<int, Map<String, dynamic>?> _userProgramCache = {};
  static bool _cacheInitialized = false;

  static Future<void> initCache() async {
    if (_cacheInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getString('cached_workouts');
    final exercisesJson = prefs.getString('cached_exercises');
    if (workoutsJson != null) {
      try {
        final workoutsMap = jsonDecode(workoutsJson) as Map<String, dynamic>;
        for (final entry in workoutsMap.entries) {
          _workoutsCache[int.parse(entry.key)] = entry.value as List<dynamic>;
        }
      } catch (e) {
        debugPrint('Error loading workouts cache: $e');
      }
    }
    if (exercisesJson != null) {
      try {
        final exercisesMap = jsonDecode(exercisesJson) as Map<String, dynamic>;
        for (final entry in exercisesMap.entries) {
          _exercisesCache[int.parse(entry.key)] = entry.value as List<dynamic>;
        }
      } catch (e) {
        debugPrint('Error loading exercises cache: $e');
      }
    }
    final complexesJson = prefs.getString('cached_complexes');
    if (complexesJson != null) {
      try {
        _complexesCache = jsonDecode(complexesJson) as List<dynamic>;
      } catch (e) {
        debugPrint('Error loading complexes cache: $e');
      }
    }
    final programsJson = prefs.getString('cached_programs');
    if (programsJson != null) {
      try {
        _programsCache = jsonDecode(programsJson) as List<dynamic>;
      } catch (e) {
        debugPrint('Error loading programs cache: $e');
      }
    }
    final programDaysJson = prefs.getString('cached_program_days');
    if (programDaysJson != null) {
      try {
        final programDaysMap = jsonDecode(programDaysJson) as Map<String, dynamic>;
        for (final entry in programDaysMap.entries) {
          _programDaysCache[int.parse(entry.key)] = entry.value as List<dynamic>;
        }
      } catch (e) {
        debugPrint('Error loading program days cache: $e');
      }
    }
    final favoriteWorkoutIdsJson = prefs.getString('cached_favorite_workout_ids');
    if (favoriteWorkoutIdsJson != null) {
      try {
        final ids = (jsonDecode(favoriteWorkoutIdsJson) as List<dynamic>)
            .whereType<num>()
            .map((id) => id.toInt())
            .toSet();
        _favoriteWorkoutIdsCache = ids;
        _favoriteWorkoutIdsLoaded = true;
      } catch (e) {
        debugPrint('Error loading favorite workout ids cache: $e');
      }
    }
    final favoritesJson = prefs.getString('cached_favorites');
    if (favoritesJson != null) {
      try {
        final favoritesMap = jsonDecode(favoritesJson) as Map<String, dynamic>;
        for (final entry in favoritesMap.entries) {
          _favoritesCache[int.parse(entry.key)] = entry.value as bool;
        }
      } catch (e) {
        debugPrint('Error loading favorites cache: $e');
      }
    }
    final exerciseFavoritesJson = prefs.getString('cached_exercise_favorites');
    if (exerciseFavoritesJson != null) {
      try {
        final exerciseFavoritesMap = jsonDecode(exerciseFavoritesJson) as Map<String, dynamic>;
        for (final entry in exerciseFavoritesMap.entries) {
          _exerciseFavoritesCache[int.parse(entry.key)] = entry.value as bool;
        }
      } catch (e) {
        debugPrint('Error loading exercise favorites cache: $e');
      }
    }
    _cacheInitialized = true;
    debugPrint('Cache initialized from storage');
  }

  static Future<void> _saveWorkoutsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsMap = <String, dynamic>{};
    for (final entry in _workoutsCache.entries) {
      workoutsMap[entry.key.toString()] = entry.value;
    }
    await prefs.setString('cached_workouts', jsonEncode(workoutsMap));
  }

  static Future<void> _saveExercisesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesMap = <String, dynamic>{};
    for (final entry in _exercisesCache.entries) {
      exercisesMap[entry.key.toString()] = entry.value;
    }
    await prefs.setString('cached_exercises', jsonEncode(exercisesMap));
  }

  static Future<void> _saveComplexesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_complexes', jsonEncode(_complexesCache ?? []));
  }

  static Future<void> _saveProgramsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_programs', jsonEncode(_programsCache ?? []));
  }

  static Future<void> _saveProgramDaysCache() async {
    final prefs = await SharedPreferences.getInstance();
    final programDaysMap = <String, dynamic>{};
    for (final entry in _programDaysCache.entries) {
      programDaysMap[entry.key.toString()] = entry.value;
    }
    await prefs.setString('cached_program_days', jsonEncode(programDaysMap));
  }

  static Future<void> _saveFavoriteWorkoutIdsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_favorite_workout_ids', jsonEncode(_favoriteWorkoutIdsCache.toList()));
  }

  static Future<void> _saveFavoritesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesMap = <String, dynamic>{};
    for (final entry in _favoritesCache.entries) {
      favoritesMap[entry.key.toString()] = entry.value;
    }
    await prefs.setString('cached_favorites', jsonEncode(favoritesMap));
  }

  static Future<void> _saveExerciseFavoritesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final exerciseFavoritesMap = <String, dynamic>{};
    for (final entry in _exerciseFavoritesCache.entries) {
      exerciseFavoritesMap[entry.key.toString()] = entry.value;
    }
    await prefs.setString('cached_exercise_favorites', jsonEncode(exerciseFavoritesMap));
  }

  static void updateExerciseFavoriteCache(int exerciseId, bool isFavorite) {
    _exerciseFavoritesCache[exerciseId] = isFavorite;
    _saveExerciseFavoritesCache();
  }

  static void updateWorkoutFavoriteCache(int workoutId, bool isFavorite) {
    if (isFavorite) {
      _favoriteWorkoutIdsCache.add(workoutId);
    } else {
      _favoriteWorkoutIdsCache.remove(workoutId);
    }
    _favoriteWorkoutIdsLoaded = true;
    _saveFavoriteWorkoutIdsCache();
  }

  static Future<void> clearUserCaches() async {
    _favoritesCache.clear();
    _exerciseFavoritesCache.clear();
    _favoriteWorkoutIdsCache.clear();
    _favoriteWorkoutIdsLoaded = false;
    _dayExercisesCache.clear();
    _programsProgressCache = null;
    _programsProgressCacheTime = null;
    _userProgramCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_favorites');
    await prefs.remove('cached_exercise_favorites');
    await prefs.remove('cached_favorite_workout_ids');
    debugPrint('AuthService user caches cleared');
  }

  static Future<void> clearCaches() async {
    _workoutsCache.clear();
    _exercisesCache.clear();
    _favoritesCache.clear();
    _exerciseFavoritesCache.clear();
    _favoriteWorkoutIdsCache.clear();
    _favoriteWorkoutIdsLoaded = false;
    _dayExercisesCache.clear();
    _complexesCache = null;
    _programsCache = null;
    _programsProgressCache = null;
    _programsProgressCacheTime = null;
    _programDaysCache.clear();
    _userProgramCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_workouts');
    await prefs.remove('cached_exercises');
    await prefs.remove('cached_complexes');
    await prefs.remove('cached_programs');
    await prefs.remove('cached_program_days');
    await prefs.remove('cached_favorites');
    await prefs.remove('cached_exercise_favorites');
    await prefs.remove('cached_favorite_workout_ids');
    _cacheInitialized = false;
    debugPrint('AuthService caches cleared');
  }

  SupabaseClient get supabaseClient => Supabase.instance.client;

  String? getCurrentUserId() {
    return supabaseClient.auth.currentUser?.id;
  }

  bool get isLoggedIn {
    return supabaseClient.auth.currentUser != null;
  }

  Future<bool> verifyPassword(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));
      await supabaseClient.auth.signOut().timeout(const Duration(seconds: 10));
      return response.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendOTP(String email, {required bool isRegistration}) async {
    try {
      if (isRegistration) {
        await supabaseClient.auth.signInWithOtp(
          email: email,
          shouldCreateUser: true,
        ).timeout(const Duration(seconds: 30));
      } else {
        await supabaseClient.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        ).timeout(const Duration(seconds: 30));
      }
      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginWithOTP(String email, String otp) async {
    try {
      final response = await supabaseClient.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      ).timeout(const Duration(seconds: 30));
      final user = response.user;
      if (user != null) {
        final userDataResponse = await supabaseClient
            .from('users')
            .select('id,nickname')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        return userDataResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying OTP (login): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerWithOTP(String nickname, String email, String otp) async {
    try {
      final response = await supabaseClient.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.signup,
      ).timeout(const Duration(seconds: 30));
      final user = response.user;
      if (user != null) {
        await supabaseClient.auth.updateUser(
          UserAttributes(data: {'nickname': nickname}),
        ).timeout(const Duration(seconds: 15));
        final userDataResponse = await supabaseClient
            .from('users')
            .select('id,nickname')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        return userDataResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying OTP (registration): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));
      final user = response.user;
      if (user != null) {
        final userDataResponse = await supabaseClient
            .from('users')
            .select('id,nickname')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        return userDataResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка входа: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerUser(String nickname, String email, String password) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'nickname': nickname},
      ).timeout(const Duration(seconds: 30));
      final user = response.user;
      if (user != null) {
        final userDataResponse = await supabaseClient
            .from('users')
            .select('id,nickname')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        return userDataResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка регистрации: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchComplexes() async {
    await initCache();
    if (_complexesCache != null) {
      return List<dynamic>.from(_complexesCache!);
    }

    debugPrint('=== fetchComplexes START ===');
    try {
      final response = await supabaseClient
          .from('complexes')
          .select('id,name')
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 15));
      final data = response.toList();
      _complexesCache = data;
      await _saveComplexesCache();
      debugPrint('=== fetchComplexes END ${data.length} ===');
      return data;
    } catch (e) {
      debugPrint('Error fetchComplexes: $e');
      return _complexesCache ?? [];
    }
  }

  bool _workoutsNeedImageRefresh() {
    if (_workoutsCache.isEmpty) return true;
    for (final workouts in _workoutsCache.values) {
      for (final workout in workouts) {
        final image = workout['image'] as String?;
        if (image == null || image.isEmpty) return true;
      }
    }
    return false;
  }

  Future<List<dynamic>> fetchAllWorkoutsWithImages({bool forceRefresh = false}) async {
    await initCache();
    if (forceRefresh) {
      _workoutsCache.clear();
    }
    if (!forceRefresh && _workoutsCache.isNotEmpty && !_workoutsNeedImageRefresh()) {
      return _workoutsCache.values.expand((workouts) => workouts).toList();
    }

    debugPrint('=== fetchAllWorkoutsWithImages START ===');
    final workoutsResponse = await supabaseClient
        .from('workouts')
        .select('id,id_complex,name')
        .order('id', ascending: true)
        .timeout(const Duration(seconds: 30));
    final workouts = workoutsResponse.toList();
    final workoutIds = workouts.map((w) => w['id'] as int).toList();

    final exercisesByWorkout = <int, List<Map<String, dynamic>>>{};
    if (workoutIds.isNotEmpty) {
      final linksResponse = await supabaseClient
          .from('workouts_exercises')
          .select('id, id_workout, id_exercise')
          .inFilter('id_workout', workoutIds)
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 30));
      final links = linksResponse.toList();
      final exerciseIds = links.map((l) => l['id_exercise'] as int).toSet().toList();

      final exercisesMap = <int, Map<String, dynamic>>{};
      if (exerciseIds.isNotEmpty) {
        final exercisesResponse = await supabaseClient.from('exercises').select('id,image').inFilter('id', exerciseIds).timeout(const Duration(seconds: 15));
        for (final ex in exercisesResponse) {
          exercisesMap[ex['id'] as int] = ex;
        }
      }

      for (final link in links) {
        final workoutId = link['id_workout'] as int;
        final exerciseId = link['id_exercise'] as int;
        final exercise = exercisesMap[exerciseId];
        if (exercise != null) {
          exercisesByWorkout.putIfAbsent(workoutId, () => []).add(exercise);
        }
      }

      for (final entry in exercisesByWorkout.entries) {
        _exercisesCache[entry.key] = List<Map<String, dynamic>>.from(entry.value);
      }
      if (exercisesByWorkout.isNotEmpty) {
        await _saveExercisesCache();
      }
    }

    for (final workout in workouts) {
      final workoutId = workout['id'] as int;
      final complexId = workout['id_complex'] as int;
      final result = Map<String, dynamic>.from(workout);
      final firstExercise = exercisesByWorkout[workoutId]?.isNotEmpty == true
          ? exercisesByWorkout[workoutId]!.first
          : null;
      if (firstExercise != null) {
        result['image'] = firstExercise['image'] ?? '';
      } else {
        result['image'] = '';
      }
      _workoutsCache.putIfAbsent(complexId, () => []).add(result);
    }

    await _saveWorkoutsCache();
    debugPrint('=== fetchAllWorkoutsWithImages END ${workouts.length} ===');
    return workouts;
  }

  Future<List<dynamic>> fetchWorkoutsWithImages(int complexId) async {
    await initCache();
    if (_workoutsCache.containsKey(complexId) && !_workoutsNeedImageRefresh()) {
      return List<dynamic>.from(_workoutsCache[complexId]!);
    }

    await fetchAllWorkoutsWithImages(forceRefresh: !_workoutsCache.containsKey(complexId));
    return List<dynamic>.from(_workoutsCache[complexId] ?? []);
  }

  Future<List<dynamic>> fetchWorkouts(int complexId) async {
    final data = await fetchWorkoutsWithImages(complexId);
    return data;
  }

  Future<List<dynamic>> fetchExercises(int workoutId) async {
    await initCache();
    if (_exercisesCache.containsKey(workoutId)) {
      return List<dynamic>.from(_exercisesCache[workoutId]!);
    }

    await fetchAllWorkoutsWithImages();
    if (_exercisesCache.containsKey(workoutId)) {
      return List<dynamic>.from(_exercisesCache[workoutId]!);
    }

    final workoutExercisesResponse = await supabaseClient
        .from('workouts_exercises')
        .select('id_exercise')
        .eq('id_workout', workoutId);
    final exerciseLinks = workoutExercisesResponse.toList();
    if (exerciseLinks.isNotEmpty) {
      final exerciseIds = exerciseLinks.map((item) => item['id_exercise']).toList();
      final response = await supabaseClient.from('exercises').select().inFilter('id', exerciseIds);
      final data = response.toList();
      _exercisesCache[workoutId] = data;
      await _saveExercisesCache();
      return data;
    }
    return [];
  }

  bool _isStoragePath(String path) {
    final trimmed = path.trim();
    return RegExp(r'^[A-Za-z0-9_./-]+\.(jpg|jpeg|png|gif|webp|mp4|mov|webm)$', caseSensitive: false).hasMatch(trimmed);
  }

  String? getValidImagePath(String? imagePath, {String? fallbackImagePath}) {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) return fallbackImagePath;
    if (path.startsWith('http')) return path;
    if (path.startsWith('images/')) return path;
    if (!_isStoragePath(path)) return fallbackImagePath;
    return getImageUrl(path);
  }

  String? resolveVideoPath(String? videoPath) {
    final path = videoPath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (!_isStoragePath(path)) return null;
    if (path.startsWith('videos/')) return path;
    return 'videos/$path';
  }

  String getImageUrl(String imagePath) {
    if (imagePath.startsWith('images/')) return imagePath;
    if (imagePath.startsWith('http')) return imagePath;
    if (!_isStoragePath(imagePath)) return imagePath;
    final encodedPath = imagePath
        .split('/')
        .map((part) => Uri.encodeComponent(part))
        .join('/');
    return 'https://urtwjptaraefxhmwqoqr.supabase.co/storage/v1/object/public/$encodedPath';
  }

  // ==================== FAVORITES ====================
  Future<bool> isWorkoutFavorite(int workoutId) async {
    await initCache();
    if (_favoritesCache.containsKey(workoutId)) return _favoritesCache[workoutId]!;
    final userId = getCurrentUserId();
    if (userId == null) return false;
    try {
      final response = await supabaseClient.from('favorites_workouts').select().eq('id_user', userId).eq('id_workout', workoutId).maybeSingle();
      final isFavorite = response != null;
      _favoritesCache[workoutId] = isFavorite;
      updateWorkoutFavoriteCache(workoutId, isFavorite);
      return isFavorite;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addWorkoutToFavorites(int workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    try {
      await supabaseClient.from('favorites_workouts').insert({'id_user': userId, 'id_workout': workoutId});
      _favoritesCache[workoutId] = true;
      updateWorkoutFavoriteCache(workoutId, true);
      await _saveFavoritesCache();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeWorkoutFromFavorites(int workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    try {
      await supabaseClient.from('favorites_workouts').delete().eq('id_user', userId).eq('id_workout', workoutId);
      _favoritesCache[workoutId] = false;
      updateWorkoutFavoriteCache(workoutId, false);
      await _saveFavoritesCache();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> fetchFavoriteWorkouts() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    try {
      final favoriteIds = await fetchFavoriteWorkoutIds();
      if (favoriteIds.isEmpty) return [];
      await fetchAllWorkoutsWithImages();
      final allWorkouts = <int, Map<String, dynamic>>{};
      for (final workouts in _workoutsCache.values) {
        for (final workout in workouts) {
          final id = workout['id'] as int?;
          if (id != null) {
            allWorkouts[id] = workout;
          }
        }
      }
      return favoriteIds.map((id) => allWorkouts[id]).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<Set<int>> fetchFavoriteWorkoutIds() async {
    await initCache();
    if (_favoriteWorkoutIdsLoaded) return Set<int>.from(_favoriteWorkoutIdsCache);
    final userId = getCurrentUserId();
    if (userId == null) {
      _favoriteWorkoutIdsLoaded = true;
      return {};
    }
    try {
      final response = await supabaseClient.from('favorites_workouts').select('id_workout').eq('id_user', userId).gt('id_workout', 0);
      final ids = response
          .toList()
          .map((item) => item['id_workout'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toSet();
      _favoriteWorkoutIdsCache = ids;
      _favoriteWorkoutIdsLoaded = true;
      await _saveFavoriteWorkoutIdsCache();
      return Set<int>.from(ids);
    } catch (e) {
      return {};
    }
  }

  Future<bool> isExerciseFavorite(int exerciseId) async {
    await initCache();
    if (_exerciseFavoritesCache.containsKey(exerciseId)) return _exerciseFavoritesCache[exerciseId]!;
    final userId = getCurrentUserId();
    if (userId == null) return false;
    try {
      final response = await supabaseClient.from('favorites_exercises').select().eq('id_user', userId).eq('id_exercise', exerciseId).maybeSingle();
      final isFavorite = response != null;
      _exerciseFavoritesCache[exerciseId] = isFavorite;
      return isFavorite;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addExerciseToFavorites(int exerciseId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    try {
      final existing = await supabaseClient.from('favorites_exercises').select('id').eq('id_user', userId).eq('id_exercise', exerciseId).maybeSingle();
      if (existing != null) {
        _exerciseFavoritesCache[exerciseId] = true;
        await _saveExerciseFavoritesCache();
        return true;
      }
      await supabaseClient.from('favorites_exercises').insert({'id_user': userId, 'id_exercise': exerciseId});
      _exerciseFavoritesCache[exerciseId] = true;
      await _saveExerciseFavoritesCache();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeExerciseFromFavorites(int exerciseId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    try {
      await supabaseClient.from('favorites_exercises').delete().eq('id_user', userId).eq('id_exercise', exerciseId);
      _exerciseFavoritesCache[exerciseId] = false;
      await _saveExerciseFavoritesCache();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Set<int>> fetchFavoriteExerciseIds() async {
    await initCache();
    if (_exerciseFavoritesCache.isNotEmpty) {
      return _exerciseFavoritesCache.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toSet();
    }
    final userId = getCurrentUserId();
    if (userId == null) return {};
    try {
      final response = await supabaseClient.from('favorites_exercises').select('id_exercise').eq('id_user', userId).gt('id_exercise', 0);
      final ids = response
          .toList()
          .map((item) => item['id_exercise'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toSet();
      for (final id in ids) {
        _exerciseFavoritesCache[id] = true;
      }
      await _saveExerciseFavoritesCache();
      return ids;
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>> fetchFavoriteExercises() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    try {
      final favoriteIds = await fetchFavoriteExerciseIds();
      if (favoriteIds.isEmpty) return [];
      return await fetchExercisesByIds(favoriteIds.toList());
    } catch (e) {
      return [];
    }
  }

  // ==================== PROGRAMS ====================
  Future<List<dynamic>> fetchPrograms() async {
    await initCache();
    if (_programsCache != null) {
      return List<dynamic>.from(_programsCache!);
    }

    try {
      final response = await supabaseClient.from('programs').select();
      final data = response.toList();
      _programsCache = data;
      await _saveProgramsCache();
      return data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchProgramDays(int programId) async {
    await initCache();
    if (_programDaysCache.containsKey(programId)) {
      return List<dynamic>.from(_programDaysCache[programId]!);
    }

    try {
      final response = await supabaseClient.from('program_days').select('id,id_program,day_number,id_workout').eq('id_program', programId).order('day_number', ascending: true).timeout(const Duration(seconds: 15));
      final data = response.toList();
      _programDaysCache[programId] = data;
      await _saveProgramDaysCache();
      return data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchProgramDaysForPrograms(List<int> programIds) async {
    if (programIds.isEmpty) return [];

    try {
      final response = await supabaseClient
          .from('program_days')
          .select('id,id_program,day_number,id_workout')
          .inFilter('id_program', programIds)
          .order('id_program', ascending: true)
          .timeout(const Duration(seconds: 15));
      final data = response.toList();
      final grouped = <int, List<dynamic>>{};
      for (final day in data) {
        final programId = day['id_program'] as int?;
        if (programId != null) {
          grouped.putIfAbsent(programId, () => []).add(day);
        }
      }
      for (final entry in grouped.entries) {
        _programDaysCache[entry.key] = entry.value;
      }
      if (grouped.isNotEmpty) {
        await _saveProgramDaysCache();
      }
      return data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchWorkoutsByIds(List<int> workoutIds) async {
    if (workoutIds.isEmpty) return [];

    try {
      final response = await supabaseClient
          .from('workouts')
          .select('id, id_complex, name_workout, duration')
          .inFilter('id', workoutIds)
          .timeout(const Duration(seconds: 15));
      final workouts = response.toList();
      final linksResponse = await supabaseClient
          .from('workouts_exercises')
          .select('id_workout, id_exercise')
          .inFilter('id_workout', workoutIds)
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 15));
      final links = linksResponse.toList();
      final firstExerciseByWorkout = <int, Map<String, dynamic>>{};
      final exerciseIds = links
          .map((link) => link['id_exercise'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toList();
      if (exerciseIds.isNotEmpty) {
        final exercisesResponse = await supabaseClient
            .from('exercises')
            .select('id, image')
            .inFilter('id', exerciseIds)
            .timeout(const Duration(seconds: 15));
        final exercisesById = <int, Map<String, dynamic>>{};
        for (final exercise in exercisesResponse) {
          exercisesById[exercise['id'] as int] = exercise;
        }
        for (final link in links) {
          final workoutId = link['id_workout'] as int?;
          final exerciseId = link['id_exercise'] as int?;
          if (workoutId == null || exerciseId == null || firstExerciseByWorkout.containsKey(workoutId)) continue;
          final exercise = exercisesById[exerciseId];
          if (exercise != null) {
            firstExerciseByWorkout[workoutId] = exercise;
          }
        }
      }

      for (final workout in workouts) {
        final workoutId = workout['id'] as int?;
        final complexId = workout['id_complex'] as int?;
        if (workoutId == null) continue;
        final firstExercise = firstExerciseByWorkout[workoutId];
        if (firstExercise != null) {
          workout['image'] = firstExercise['image'] ?? '';
        } else {
          workout['image'] = '';
        }
        if (complexId != null) {
          _workoutsCache.putIfAbsent(complexId, () => []);
          final index = _workoutsCache[complexId]!.indexWhere((item) => (item['id'] as int?) == workoutId);
          if (index >= 0) {
            _workoutsCache[complexId]![index] = workout;
          } else {
            _workoutsCache[complexId]!.add(workout);
          }
        }
      }
      if (workouts.isNotEmpty) {
        await _saveWorkoutsCache();
      }
      return workouts;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchExercisesByIds(List<int> exerciseIds) async {
    if (exerciseIds.isEmpty) return [];

    try {
      final response = await supabaseClient
          .from('exercises')
          .select('id,name_exercise,image,video,description,recommended_duration_seconds')
          .inFilter('id', exerciseIds)
          .timeout(const Duration(seconds: 15));
      return response.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProgramDaysWithWorkouts(int programId) async {
    final days = await fetchProgramDays(programId);
    final workoutIds = days
        .map((day) => day['id_workout'] as int?)
        .where((id) => id != null)
        .cast<int>()
        .where((id) => id > 0)
        .toList();

    if (workoutIds.isEmpty) {
      return days.map((day) => Map<String, dynamic>.from(day)).toList();
    }

    final workouts = await fetchWorkoutsByIds(workoutIds);
    final workoutsById = <int, Map<String, dynamic>>{};
    for (final workout in workouts) {
      final workoutId = workout['id'] as int?;
      if (workoutId != null) {
        workoutsById[workoutId] = workout;
      }
    }

    return days.map((day) {
      final result = Map<String, dynamic>.from(day);
      final workoutId = result['id_workout'] as int?;
      final workout = workoutId != null ? workoutsById[workoutId] : null;
      result['workout_name'] = workout?['name_workout'] ?? 'Workout';
      result['workout_duration'] = workout?['duration'];
      return result;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchUserProgramsForPrograms(List<int> programIds) async {
    final userId = getCurrentUserId();
    if (userId == null || programIds.isEmpty) return [];

    try {
      final response = await supabaseClient
          .from('user_programs')
          .select('id, id_program, current_day, progress_percent, is_completed, day_progress')
          .eq('id_user', userId)
          .eq('is_active', true)
          .inFilter('id_program', programIds);
      return response.toList().cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching user programs: $e');
      return [];
    }
  }

  void _invalidateProgramProgressCache({int? userProgramId}) {
    _programsProgressCache = null;
    _programsProgressCacheTime = null;
    _programDaysCache.clear();
    _dayExercisesCache.clear();
    if (userProgramId != null) {
      _userProgramCache.remove(userProgramId);
    } else {
      _userProgramCache.clear();
    }
  }

  Future<List<Map<String, dynamic>>> fetchProgramsWithProgress({bool forceRefresh = false}) async {
    await initCache();
    final now = DateTime.now();
    if (!forceRefresh &&
        _programsProgressCache != null &&
        _programsProgressCacheTime != null &&
        now.difference(_programsProgressCacheTime!) < const Duration(minutes: 5)) {
      return _programsProgressCache!.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    final programs = await fetchPrograms();
    final programIds = programs
        .map((program) => program['id'] as int?)
        .where((id) => id != null)
        .cast<int>()
        .where((id) => id > 0)
        .toList();

    if (programIds.isEmpty) return [];

    final userPrograms = await fetchUserProgramsForPrograms(programIds);
    final userProgramByProgramId = <int, Map<String, dynamic>>{};
    for (final userProgram in userPrograms) {
      final programId = userProgram['id_program'] as int?;
      if (programId != null) {
        userProgramByProgramId[programId] = userProgram;
      }
    }

    for (final programId in programIds) {
      if (!userProgramByProgramId.containsKey(programId)) {
        final createdUserProgramId = await startProgram(programId);
        if (createdUserProgramId != null) {
          final createdUserProgram = await getUserProgram(createdUserProgramId);
          if (createdUserProgram != null) {
            createdUserProgram['id'] = createdUserProgramId;
            userProgramByProgramId[programId] = createdUserProgram;
          }
        }
      }
    }

    final daysByProgramId = <int, List<dynamic>>{};
    final allDays = await fetchProgramDaysForPrograms(programIds);
    for (final day in allDays) {
      final programId = day['id_program'] as int?;
      if (programId != null) {
        daysByProgramId.putIfAbsent(programId, () => []).add(day);
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final program in programs) {
      final programId = program['id'] as int? ?? 0;
      if (programId <= 0) continue;

      final userProgram = userProgramByProgramId[programId];
      final progressPercent = userProgram?['progress_percent'] as int? ?? 0;
      final programCopy = Map<String, dynamic>.from(program);
      programCopy['user_program_id'] = userProgram?['id'] as int?;
      programCopy['current_day'] = userProgram?['current_day'] as int? ?? 1;
      programCopy['progress_percent'] = progressPercent;
      programCopy['progress'] = (progressPercent.clamp(0, 100) / 100.0).toDouble();
      programCopy['is_completed'] = userProgram?['is_completed'] as bool? ?? false;
      programCopy['day_progress'] = userProgram?['day_progress'];
      programCopy['days'] = daysByProgramId[programId] ?? [];
      result.add(programCopy);
    }

    _programsProgressCache = result.map((item) => Map<String, dynamic>.from(item)).toList();
    _programsProgressCacheTime = now;
    return result;
  }

  Future<void> prefetchPublicData({bool forceRefresh = false}) async {
    await initCache();
    final needComplexes = forceRefresh || _complexesCache == null;
    final needWorkouts = forceRefresh || _workoutsCache.isEmpty;
    final needPrograms = forceRefresh || _programsCache == null;
    final needProgramDays = forceRefresh || _programDaysCache.isEmpty;

    if (!needComplexes && !needWorkouts && !needPrograms && !needProgramDays) {
      return;
    }

    try {
      if (needComplexes) {
        _complexesCache = await fetchComplexes();
      }
      if (needWorkouts) {
        await fetchAllWorkoutsWithImages();
      }
      if (needPrograms) {
        _programsCache = await fetchPrograms();
      }
      if (needProgramDays) {
        final programs = _programsCache ?? await fetchPrograms();
        final programIds = programs
            .map((program) => program['id'] as int?)
            .where((id) => id != null)
            .cast<int>()
            .toList();
        await fetchProgramDaysForPrograms(programIds);
      }
    } catch (e) {
      debugPrint('Error prefetching public data: $e');
    }
  }

// ==================== USER PROGRAMS ====================
  Future<int?> startProgram(int programId) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    try {
      final response = await supabaseClient.from('user_programs').insert({'id_user': userId, 'id_program': programId, 'current_day': 1, 'is_active': true}).select('id').maybeSingle().timeout(const Duration(seconds: 15));
      _invalidateProgramProgressCache();
      return response?['id'] as int?;
    } catch (e) {
     try {
        final active = await supabaseClient.from('user_programs').select('id').eq('id_user', userId).eq('id_program', programId).eq('is_active', true).maybeSingle().timeout(const Duration(seconds: 10));
        return active?['id'] as int?;
      } catch (e) {
        debugPrint('Error getOrCreateUserProgram: $e');
        return null;
      }
    }
  }

  Future<int?> getOrCreateUserProgram(int programId) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    try {
      final active = await supabaseClient.from('user_programs').select('id').eq('id_user', userId).eq('id_program', programId).eq('is_active', true).maybeSingle().timeout(const Duration(seconds: 10));
      if (active != null) return active['id'] as int?;
    } catch (e) {
      debugPrint('Error getOrCreateUserProgram: $e');
    }
    return await startProgram(programId);
  }

  Future<int?> getCurrentDay(int userProgramId) async {
    try {
      final response = await supabaseClient.from('user_programs').select('current_day').eq('id', userProgramId).single().timeout(const Duration(seconds: 10));
      return response['current_day'] as int?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> setCurrentDay(int userProgramId, int day) async {
    try {
      await supabaseClient.from('user_programs').update({'current_day': day}).eq('id', userProgramId).timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getActiveProgram() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    try {
      return await supabaseClient.from('user_programs').select('id,id_user,id_program,current_day,progress_percent,is_completed,day_progress').eq('id_user', userId).eq('is_active', true).maybeSingle().timeout(const Duration(seconds: 15));
    } catch (e) {
      return null;
    }
  }

  Future<int> getProgramProgressPercent(int userProgramId) async {
    final userProg = await getUserProgram(userProgramId);
    return userProg?['progress_percent'] as int? ?? 0;
  }

  // Получение записи программы с кэшированными полями
  Future<Map<String, dynamic>?> getUserProgram(int userProgramId) async {
    await initCache();
    if (_userProgramCache.containsKey(userProgramId)) {
      return _userProgramCache[userProgramId];
    }

    try {
      final response = await supabaseClient
          .from('user_programs')
          .select('progress_percent, is_completed, day_progress')
          .eq('id', userProgramId)
          .maybeSingle();
      _userProgramCache[userProgramId] = response;
      return response;
    } catch (e) {
      _userProgramCache[userProgramId] = null;
      return null;
    }
  }

  // Статус выполнения дней из кэшированного JSON в user_programs
  Future<Map<int, bool>> fetchDayCompletionStatuses(int userProgramId) async {
    final userProg = await getUserProgram(userProgramId);
    final dayProgress = userProg?['day_progress'] as Map<String, dynamic>? ?? {};
    final result = <int, bool>{};
    dayProgress.forEach((key, value) {
      final parsedKey = int.tryParse(key);
      if (parsedKey == null || value is! Map) return;
      result[parsedKey] = value['is_completed'] as bool? ?? false;
    });
    return result;
  }

  // ==================== DAY EXERCISES PROGRESS ====================
  Future<void> initializeDayExercises(int userProgramId, int dayNumber, int workoutId) async {
    await initCache();
    try {
      final existing = await supabaseClient.from('user_program_exercise_progress').select('id').eq('id_user_program', userProgramId).eq('day_number', dayNumber).limit(1);
      if (existing.isNotEmpty) return;
      final workoutExercisesResponse = await supabaseClient.from('workouts_exercises').select('id_exercise').eq('id_workout', workoutId).order('id', ascending: true);
      final links = workoutExercisesResponse.toList();
      if (links.isEmpty) {
        await supabaseClient.from('user_program_exercise_progress').insert({'id_user_program': userProgramId, 'day_number': dayNumber, 'exercise_id': -1, 'exercise_order': 1, 'completed': false, 'started_at': null, 'completed_at': null});
        return;
      }
      final entries = <Map<String, dynamic>>[];
      int order = 1;
      for (final link in links) {
        entries.add({'id_user_program': userProgramId, 'day_number': dayNumber, 'exercise_id': link['id_exercise'], 'exercise_order': order, 'completed': false, 'started_at': null, 'completed_at': null});
        order++;
      }
      await supabaseClient.from('user_program_exercise_progress').insert(entries);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // Инициализация всех дней программы одним пакетным запросом
  Future<void> initializeAllProgramDays(int userProgramId, List<dynamic> allDays) async {
    await initCache();
    try {
      final validDays = <Map<String, dynamic>>[];
      for (final day in allDays) {
        final dayNumber = day['day_number'] as int? ?? 0;
        final workoutId = day['id_workout'] as int?;
        if (dayNumber > 0 && workoutId != null) {
          validDays.add({'dayNumber': dayNumber, 'workoutId': workoutId});
        }
      }
      if (validDays.isEmpty) return;

      final existingResponse = await supabaseClient
          .from('user_program_exercise_progress')
          .select('day_number')
          .eq('id_user_program', userProgramId)
          .inFilter('day_number', validDays.map((day) => day['dayNumber'] as int).toList());
      final existingDays = existingResponse
          .toList()
          .map((row) => row['day_number'] as int?)
          .where((day) => day != null)
          .cast<int>()
          .toSet();

      final missingDays = validDays.where((day) => !existingDays.contains(day['dayNumber'] as int)).toList();
      if (missingDays.isEmpty) return;

      final missingWorkoutIds = missingDays.map((day) => day['workoutId'] as int).toSet().toList();
      final linksResponse = await supabaseClient
          .from('workouts_exercises')
          .select('id, id_workout, id_exercise')
          .inFilter('id_workout', missingWorkoutIds)
          .order('id', ascending: true);
      final linksByWorkout = <int, List<Map<String, dynamic>>>{};
      for (final link in linksResponse) {
        linksByWorkout.putIfAbsent(link['id_workout'] as int, () => []).add(link);
      }

      final entries = <Map<String, dynamic>>[];
      for (final day in missingDays) {
        final dayNumber = day['dayNumber'] as int;
        final workoutId = day['workoutId'] as int;
        final links = linksByWorkout[workoutId] ?? [];
        if (links.isEmpty) {
          entries.add({'id_user_program': userProgramId, 'day_number': dayNumber, 'exercise_id': -1, 'exercise_order': 1, 'completed': false, 'started_at': null, 'completed_at': null});
          continue;
        }
        int order = 1;
        for (final link in links) {
          entries.add({'id_user_program': userProgramId, 'day_number': dayNumber, 'exercise_id': link['id_exercise'], 'exercise_order': order, 'completed': false, 'started_at': null, 'completed_at': null});
          order++;
        }
      }

      if (entries.isNotEmpty) {
        await supabaseClient.from('user_program_exercise_progress').insert(entries);
      }
      debugPrint('Initialized ${missingDays.length} program days');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<List<dynamic>> fetchDayExercises(int userProgramId, int dayNumber, {int? workoutId}) async {
    await initCache();
    final cacheKey = '$userProgramId:$dayNumber';
    if (_dayExercisesCache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_dayExercisesCache[cacheKey]!);
    }

    try {
      var progressResponse = await supabaseClient.from('user_program_exercise_progress').select('id,id_user_program,day_number,exercise_id,exercise_order,completed,completed_at,started_at').eq('id_user_program', userProgramId).eq('day_number', dayNumber).order('exercise_order', ascending: true).timeout(const Duration(seconds: 15));
      var progressData = progressResponse.toList();

      if (progressData.isEmpty && workoutId != null && workoutId > 0) {
        await initializeDayExercises(userProgramId, dayNumber, workoutId);
        final retryResponse = await supabaseClient.from('user_program_exercise_progress').select('id,id_user_program,day_number,exercise_id,exercise_order,completed,completed_at,started_at').eq('id_user_program', userProgramId).eq('day_number', dayNumber).order('exercise_order', ascending: true).timeout(const Duration(seconds: 15));
        progressData = retryResponse.toList();
      }

      if (progressData.isEmpty) return [];

      final exerciseIds = progressData.map((row) => row['exercise_id']).where((id) => id != null && id != -1).toList();

      final exercisesMap = <int, Map<String, dynamic>>{};
      if (exerciseIds.isNotEmpty) {
        final exercisesResponse = await supabaseClient.from('exercises').select('id,name_exercise,image,video,description,recommended_duration_seconds').inFilter('id', exerciseIds).timeout(const Duration(seconds: 15));
        for (final ex in exercisesResponse) {
          exercisesMap[ex['id'] as int] = ex;
        }
      }

      final List<dynamic> result = [];
      for (final row in progressData) {
        final exerciseId = row['exercise_id'];
        if (exerciseId == -1 || exerciseId == null) {
          result.add({'progressId': row['id'], 'exerciseOrder': row['exercise_order'], 'completed': row['completed'] ?? false, 'completedAt': row['completed_at'], 'startedAt': row['started_at'], 'exercise': {'id': -1, 'name': 'Нет упражнения', 'image': '', 'description': 'Не добавлено', 'recommendedDurationSeconds': 60}});
        } else {
          final exercise = exercisesMap[exerciseId];
          result.add({'progressId': row['id'], 'exerciseOrder': row['exercise_order'], 'completed': row['completed'] ?? false, 'completedAt': row['completed_at'], 'startedAt': row['started_at'], 'exercise': {'id': exercise?['id'] ?? exerciseId, 'name': exercise?['name_exercise'] ?? '', 'image': exercise?['image'] ?? '', 'video': exercise?['video'], 'description': exercise?['description'] ?? '', 'recommendedDurationSeconds': exercise?['recommended_duration_seconds'] ?? 60}});
        }
      }
      _dayExercisesCache[cacheKey] = List<Map<String, dynamic>>.from(result);
      return result;
    } catch (e) {
      return [];
    }
  }

  Future<void> markExerciseCompleted(int progressId) async {
    try {
      await supabaseClient.from('user_program_exercise_progress').update({'completed': true, 'completed_at': DateTime.now().toIso8601String()}).eq('id', progressId).timeout(const Duration(seconds: 10));
      _dayExercisesCache.clear();
      _invalidateProgramProgressCache();
    } catch (e) {
      debugPrint('Error marking exercise completed: $e');
    }
  }

  Future<void> markExerciseIncomplete(int progressId) async {
    try {
      await supabaseClient.from('user_program_exercise_progress').update({'completed': false, 'completed_at': null}).eq('id', progressId).timeout(const Duration(seconds: 10));
      _dayExercisesCache.clear();
      _invalidateProgramProgressCache();
    } catch (e) {
      debugPrint('Error marking exercise incomplete: $e');
    }
  }

  Future<int?> getNextIncompleteExerciseOrder(int userProgramId, int dayNumber) async {
    try {
      final response = await supabaseClient.from('user_program_exercise_progress').select('exercise_order').eq('id_user_program', userProgramId).eq('day_number', dayNumber).eq('completed', false).order('exercise_order', ascending: true).limit(1).timeout(const Duration(seconds: 10));
      final data = response.toList();
      return data.isNotEmpty ? data.first['exercise_order'] as int : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isDayCompleted(int userProgramId, int dayNumber) async {
    final statuses = await fetchDayCompletionStatuses(userProgramId);
    return statuses[dayNumber] ?? false;
  }

  Future<bool> completeDay(int userProgramId, int dayNumber) async {
    try {
      if (!await isDayCompleted(userProgramId, dayNumber)) return false;
      final currentRecord = await supabaseClient.from('user_programs').select('current_day').eq('id', userProgramId).single().timeout(const Duration(seconds: 10));
      final currentDay = currentRecord['current_day'] as int? ?? 1;
      final newCurrentDay = dayNumber + 1 > currentDay ? dayNumber + 1 : currentDay;
      await supabaseClient.from('user_programs').update({'current_day': newCurrentDay}).eq('id', userProgramId).timeout(const Duration(seconds: 10));
      _invalidateProgramProgressCache(userProgramId: userProgramId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Процент выполнения дня (использует кэшированные данные day_progress)
  Future<double> getDayProgressPercent(int userProgramId, int dayNumber) async {
    final userProg = await getUserProgram(userProgramId);
    final dayProgress = userProg?['day_progress'] as Map<String, dynamic>? ?? {};
    final dayStats = dayProgress[dayNumber.toString()] as Map<String, dynamic>?;
    return ((dayStats?['percent'] as num?)?.toDouble() ?? 0.0) / 100.0;
  }
}
