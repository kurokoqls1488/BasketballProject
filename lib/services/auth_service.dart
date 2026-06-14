import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final Map<int, List<dynamic>> _workoutsCache = {};
  static final Map<int, List<dynamic>> _exercisesCache = {};
  static final Map<int, bool> _favoritesCache = {};
  static final Map<int, bool> _exerciseFavoritesCache = {};
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
    _exerciseFavoritesCache.clear();
    _programsProgressCache = null;
    _programsProgressCacheTime = null;
    _programDaysCache.clear();
    _userProgramCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_workouts');
    await prefs.remove('cached_exercises');
    await prefs.remove('cached_complexes');
    await prefs.remove('cached_favorites');
    await prefs.remove('cached_exercise_favorites');
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
    final response = await supabaseClient
        .from('complexes')
        .select()
        .order('id', ascending: true);
    final data = response.toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_complexes', jsonEncode(data));
    return data;
  }

  Future<List<dynamic>> fetchWorkoutsWithImages(int complexId) async {
    await initCache();
    if (_workoutsCache.containsKey(complexId)) return List<dynamic>.from(_workoutsCache[complexId]!);

    final response = await supabaseClient
        .from('workouts')
        .select()
        .eq('id_complex', complexId);
    final workouts = response.toList();
    _workoutsCache[complexId] = workouts;
    await _saveWorkoutsCache();

    final workoutIds = workouts.map((w) => w['id'] as int).toList();
    if (workoutIds.isEmpty) return workouts;

    final linksResponse = await supabaseClient
        .from('workouts_exercises')
        .select('id_workout, id_exercise')
        .inFilter('id_workout', workoutIds)
        .order('id', ascending: true);
    final links = linksResponse.toList();

    final exerciseIds = links.map((l) => l['id_exercise'] as int).toSet().toList();
    final exercisesMap = <int, Map<String, dynamic>>{};
    if (exerciseIds.isNotEmpty) {
      final exercisesResponse = await supabaseClient.from('exercises').select().inFilter('id', exerciseIds);
      for (final ex in exercisesResponse) {
        exercisesMap[ex['id'] as int] = ex;
      }
    }

    final firstExercisePerWorkout = <int, Map<String, dynamic>>{};
    for (final link in links) {
      final wid = link['id_workout'] as int;
      final eid = link['id_exercise'] as int;
      if (!firstExercisePerWorkout.containsKey(wid) && exercisesMap.containsKey(eid)) {
        firstExercisePerWorkout[wid] = exercisesMap[eid]!;
      }
    }

    return workouts.map((w) {
      final wid = w['id'] as int;
      final firstEx = firstExercisePerWorkout[wid];
      final result = Map<String, dynamic>.from(w);
      if (firstEx != null) {
        result['image'] = firstEx['image'] ?? '';
      }
      return result;
    }).toList();
  }

  Future<List<dynamic>> fetchWorkouts(int complexId) async {
    final data = await fetchWorkoutsWithImages(complexId);
    return data;
  }

  Future<List<dynamic>> fetchExercises(int workoutId) async {
    await initCache();
    if (_exercisesCache.containsKey(workoutId)) {
      return _exercisesCache[workoutId]!;
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

  Future<Set<int>> fetchFavoriteWorkoutIds() async {
    final userId = getCurrentUserId();
    if (userId == null) return {};
    try {
      final response = await supabaseClient.from('favorites_workouts').select('id_workout').eq('id_user', userId).gt('id_workout', 0);
      return response
          .toList()
          .map((item) => item['id_workout'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toSet();
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
    await initCache();
    if (_programDaysCache.containsKey(programId)) {
      return List<dynamic>.from(_programDaysCache[programId]!);
    }

    try {
      final response = await supabaseClient.from('program_days').select().eq('id_program', programId).order('day_number', ascending: true);
      final data = response.toList();
      _programDaysCache[programId] = data;
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
          .select()
          .inFilter('id_program', programIds)
          .order('id_program', ascending: true);
      return response.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchWorkoutsByIds(List<int> workoutIds) async {
    if (workoutIds.isEmpty) return [];

    try {
      final response = await supabaseClient
          .from('workouts')
          .select('id, name_workout, duration')
          .inFilter('id', workoutIds);
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

  // ==================== USER PROGRAMS ====================
  Future<int?> startProgram(int programId) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    try {
      final response = await supabaseClient.from('user_programs').insert({'id_user': userId, 'id_program': programId, 'current_day': 1, 'is_active': true}).select('id').maybeSingle();
      _invalidateProgramProgressCache();
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

  Future<List<dynamic>> fetchDayExercises(int userProgramId, int dayNumber, {int? workoutId}) async {
    await initCache();
    try {
      final progressResponse = await supabaseClient.from('user_program_exercise_progress').select().eq('id_user_program', userProgramId).eq('day_number', dayNumber).order('exercise_order', ascending: true);
      var progressData = progressResponse.toList();

      if (progressData.isEmpty && workoutId != null && workoutId > 0) {
        await initializeDayExercises(userProgramId, dayNumber, workoutId);
        final retryResponse = await supabaseClient.from('user_program_exercise_progress').select().eq('id_user_program', userProgramId).eq('day_number', dayNumber).order('exercise_order', ascending: true);
        progressData = retryResponse.toList();
      }

      if (progressData.isEmpty) return [];

      final exerciseIds = progressData.map((row) => row['exercise_id']).where((id) => id != null && id != -1).toList();

      final exercisesMap = <int, Map<String, dynamic>>{};
      if (exerciseIds.isNotEmpty) {
        final exercisesResponse = await supabaseClient.from('exercises').select().inFilter('id', exerciseIds);
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
      return result;
    } catch (e) {
      return [];
    }
  }

  Future<void> markExerciseCompleted(int progressId) async {
    try {
      await supabaseClient.from('user_program_exercise_progress').update({'completed': true, 'completed_at': DateTime.now().toIso8601String()}).eq('id', progressId);
      _invalidateProgramProgressCache();
    } catch (e) {
      debugPrint('Error marking exercise completed: $e');
    }
  }

  Future<void> markExerciseIncomplete(int progressId) async {
    try {
      await supabaseClient.from('user_program_exercise_progress').update({'completed': false, 'completed_at': null}).eq('id', progressId);
      _invalidateProgramProgressCache();
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
