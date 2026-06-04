import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final Map<int, List<dynamic>> _workoutsCache = {};
  static final Map<int, List<dynamic>> _exercisesCache = {};
  static final Map<int, bool> _favoritesCache = {};
  static final Map<int, bool> _exerciseFavoritesCache = {};
  static List<dynamic>? _complexesCache;
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
  }

  static Future<void> clearCaches() async {
    _workoutsCache.clear();
    _exercisesCache.clear();
    _favoritesCache.clear();
    _complexesCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_workouts');
    await prefs.remove('cached_exercises');
    await prefs.remove('cached_complexes');
    await prefs.remove('cached_favorites');
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
      );
      // Если вход успешен - выходим, чтобы не создавать сессию
      await supabaseClient.auth.signOut();
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
        );
      } else {
        await supabaseClient.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
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
      );
      final user = response.user;
      if (user != null) {
        final userDataResponse = await supabaseClient
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
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
      );
      final user = response.user;
      if (user != null) {
        await supabaseClient.auth.updateUser(
          UserAttributes(data: {'nickname': nickname}),
        );
        final userDataResponse = await supabaseClient
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
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
      );
      final user = response.user;
      if (user != null) {
        final userDataResponse = await supabaseClient
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
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
      );
      final user = response.user;
      if (user != null) {
        final userDataResponse = await supabaseClient
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        return userDataResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка регистрации: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchComplexes() async {
    debugPrint('=== fetchComplexes START ===');
    try {
      debugPrint('Fetching from network...');
      final response = await supabaseClient
          .from('complexes')
          .select()
          .order('id', ascending: true);
      final data = response.toList();
      if (data.isEmpty) {
        final response2 = await supabaseClient.from('complexes').select();
        final data2 = response2.toList();
        if (data2.isNotEmpty) {
          _complexesCache = data2;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_complexes', jsonEncode(data2));
          return data2;
        }
      }
      _complexesCache = data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_complexes', jsonEncode(data));
      return data;
    } catch (e, stack) {
      debugPrint('ERROR fetchComplexes: $e');
      debugPrint('Stack trace: $stack');
      if (_complexesCache != null) return _complexesCache!;
      return [];
    }
  }

  Future<List<dynamic>> fetchWorkouts(int complexId) async {
    await initCache();
    if (_workoutsCache.containsKey(complexId)) {
      return _workoutsCache[complexId]!;
    }
    try {
      final response = await supabaseClient
          .from('workouts')
          .select()
          .eq('id_complex', complexId);
      final data = response.toList();
      _workoutsCache[complexId] = data;
      await _saveWorkoutsCache();
      return data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchExercises(int workoutId) async {
    await initCache();
    if (_exercisesCache.containsKey(workoutId)) {
      return _exercisesCache[workoutId]!;
    }
    try {
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
    } catch (e) {
      return [];
    }
  }

  String getImageUrl(String imagePath) {
    if (imagePath.startsWith('images/')) return imagePath;
    return 'https://urtwjptaraefxhmwqoqr.supabase.co/storage/v1/object/public/$imagePath';
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
      final response = await supabaseClient.from('favorites_workouts').select('id_workout').eq('id_user', userId).gt('id_workout', 0);
      final data = response.toList();
      if (data.isNotEmpty) {
        final workoutIds = data.map((item) => item['id_workout']).toList();
        final workoutsResponse = await supabaseClient.from('workouts').select().inFilter('id', workoutIds);
        return workoutsResponse.toList();
      }
      return [];
    } catch (e) {
      return [];
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

  Future<List<dynamic>> fetchFavoriteExercises() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    try {
      final response = await supabaseClient.from('favorites_exercises').select('id_exercise').eq('id_user', userId).gt('id_exercise', 0);
      final data = response.toList();
      if (data.isNotEmpty) {
        final exerciseIds = data.map((item) => item['id_exercise']).toList();
        final exercisesResponse = await supabaseClient.from('exercises').select().inFilter('id', exerciseIds);
        return exercisesResponse.toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== PROGRAMS ====================
  Future<List<dynamic>> fetchPrograms() async {
    try {
      final response = await supabaseClient.from('programs').select();
      return response.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchProgramDays(int programId) async {
    try {
      final response = await supabaseClient.from('program_days').select().eq('id_program', programId).order('day_number', ascending: true);
      return response.toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== USER PROGRAMS ====================
  Future<int?> startProgram(int programId) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    try {
      final response = await supabaseClient.from('user_programs').insert({'id_user': userId, 'id_program': programId, 'current_day': 1, 'is_active': true}).select('id').maybeSingle();
      return response?['id'] as int?;
    } catch (e) {
    try {
      final active = await supabaseClient.from('user_programs').select('id').eq('id_user', userId).eq('id_program', programId).eq('is_active', true).maybeSingle();
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
      final active = await supabaseClient.from('user_programs').select('id').eq('id_user', userId).eq('id_program', programId).eq('is_active', true).maybeSingle();
      if (active != null) return active['id'] as int?;
    } catch (e) {
      debugPrint('Error getOrCreateUserProgram: $e');
    }
    return await startProgram(programId);
  }

  Future<int?> getCurrentDay(int userProgramId) async {
    try {
      final response = await supabaseClient.from('user_programs').select('current_day').eq('id', userProgramId).single();
      return response['current_day'] as int?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> setCurrentDay(int userProgramId, int day) async {
    try {
      await supabaseClient.from('user_programs').update({'current_day': day}).eq('id', userProgramId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getActiveProgram() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    try {
      return await supabaseClient.from('user_programs').select().eq('id_user', userId).eq('is_active', true).maybeSingle();
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
    try {
      final response = await supabaseClient
          .from('user_programs')
          .select('progress_percent, is_completed, day_progress')
          .eq('id', userProgramId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Статус выполнения дней из кэшированного JSON в user_programs
  Future<Map<int, bool>> fetchDayCompletionStatuses(int userProgramId) async {
    final userProg = await getUserProgram(userProgramId);
    final dayProgress = userProg?['day_progress'] as Map<String, dynamic>? ?? {};
    return dayProgress.map((key, value) => 
        MapEntry(int.parse(key), value['is_completed'] as bool));
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

  // Инициализация всех дней программы - PARALLEL (быстро)
  Future<void> initializeAllProgramDays(int userProgramId, List<dynamic> allDays) async {
    await initCache();
    try {
      final futures = <Future>[];
      int validDays = 0;
      for (final day in allDays) {
        final dayNumber = day['day_number'] as int? ?? 0;
        final workoutId = day['id_workout'] as int?;
        if (dayNumber > 0 && workoutId != null) {
          futures.add(initializeDayExercises(userProgramId, dayNumber, workoutId));
          validDays++;
        }
      }
      if (futures.isNotEmpty) await Future.wait(futures);
      debugPrint('Initialized $validDays days');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<List<dynamic>> fetchDayExercises(int userProgramId, int dayNumber) async {
    await initCache();
    try {
      final progressResponse = await supabaseClient.from('user_program_exercise_progress').select().eq('id_user_program', userProgramId).eq('day_number', dayNumber).order('exercise_order', ascending: true);
      final progressData = progressResponse.toList();
      final List<dynamic> result = [];
      for (final row in progressData) {
        final exerciseId = row['exercise_id'];
        if (exerciseId == -1 || exerciseId == null) {
          result.add({'progressId': row['id'], 'exerciseOrder': row['exercise_order'], 'completed': row['completed'] ?? false, 'completedAt': row['completed_at'], 'startedAt': row['started_at'], 'exercise': {'id': -1, 'name': 'Нет упражнения', 'image': '', 'description': 'Не добавлено', 'recommendedDurationSeconds': 60}});
        } else {
          final exerciseResponse = await supabaseClient.from('exercises').select().eq('id', exerciseId).maybeSingle();
          result.add({'progressId': row['id'], 'exerciseOrder': row['exercise_order'], 'completed': row['completed'] ?? false, 'completedAt': row['completed_at'], 'startedAt': row['started_at'], 'exercise': {'id': exerciseResponse?['id'] ?? exerciseId, 'name': exerciseResponse?['name_exercise'] ?? '', 'image': exerciseResponse?['image'] ?? '', 'video': exerciseResponse?['video'], 'description': exerciseResponse?['description'] ?? '', 'recommendedDurationSeconds': exerciseResponse?['recommended_duration_seconds'] ?? 60}});
        }
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  Future<void> markExerciseCompleted(int progressId) async {
    try {
      await supabaseClient.from('user_program_exercise_progress').update({'completed': true, 'completed_at': DateTime.now().toIso8601String()}).eq('id', progressId);
    } catch (e) {
      debugPrint('Error marking exercise completed: $e');
    }
  }

  Future<void> markExerciseIncomplete(int progressId) async {
    try {
      await supabaseClient.from('user_program_exercise_progress').update({'completed': false, 'completed_at': null}).eq('id', progressId);
    } catch (e) {
      debugPrint('Error marking exercise incomplete: $e');
    }
  }

  Future<int?> getNextIncompleteExerciseOrder(int userProgramId, int dayNumber) async {
    try {
      final response = await supabaseClient.from('user_program_exercise_progress').select('exercise_order').eq('id_user_program', userProgramId).eq('day_number', dayNumber).eq('completed', false).order('exercise_order', ascending: true).limit(1);
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
      final currentRecord = await supabaseClient.from('user_programs').select('current_day').eq('id', userProgramId).single();
      final currentDay = currentRecord['current_day'] as int? ?? 1;
      final newCurrentDay = dayNumber + 1 > currentDay ? dayNumber + 1 : currentDay;
      await supabaseClient.from('user_programs').update({'current_day': newCurrentDay}).eq('id', userProgramId);
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
    return (dayStats?['percent'] as num?)?.toDouble() ?? 0.0;
  }
}
