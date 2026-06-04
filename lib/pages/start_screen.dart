import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/locale_service.dart';
import 'training.dart';
import 'profile.dart';
import 'entrance.dart';
import 'workouts_page.dart' show WorkoutsPage, Complex;
import 'coach_page.dart';
import 'program_days_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _t(String key) => LocaleService.translate(key);

  // Навигация на LoginPage при отсутствии авторизации
  void _onItemTapped(int index) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Проверяем, если пытаемся перейти на 'Тренировки' (1) или 'Профиль' (2)
    // И пользователь НЕ авторизован
    if ((index == 1 || index == 2 || index == 3) && !auth.isAuthenticated) {
      // Если не авторизован - перенаправляем на страницу ВХОДА
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      // Прерываем выполнение, чтобы _selectedIndex остался 0
      return;
    }

    // Если авторизован ИЛИ это главная страница (index 0)
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomeContent(),
        const TrainingPage(),
        const CoachPage(),
        const ProfilePage(),
      ],
    );
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
            body: _buildBody(),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Colors.black,
              selectedItemColor: Color(0xFFFFA500),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: TextStyle(color: Color(0xFFFFA500)),
              unselectedLabelStyle: TextStyle(color: Colors.grey),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                    child: Image.asset('icons/ball.png', width: 40, height: 40),
                  ),
                  activeIcon: Image.asset(
                    'icons/ball.png',
                    width: 40,
                    height: 40,
                  ),
                  label: _t('Главная'),
                ),
                BottomNavigationBarItem(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                    child: Image.asset('icons/man.png', width: 40, height: 40),
                  ),
                  activeIcon: Image.asset(
                    'icons/man.png',
                    width: 40,
                    height: 40,
                  ),
                  label: _t('Программы'),
                ),
                BottomNavigationBarItem(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                    child: Image.asset(
                      'icons/coach.png',
                      width: 50,
                      height: 50,
                    ),
                  ),
                  activeIcon: Image.asset(
                    'icons/coach.png',
                    width: 50,
                    height: 50,
                  ),
                  label: _t('Тренер'),
                ),
                BottomNavigationBarItem(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                    child: Image.asset(
                      'icons/person.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  activeIcon: Image.asset(
                    'icons/person.png',
                    width: 40,
                    height: 40,
                  ),
                  label: _t('Профиль'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// HomeContent - Отображение комплексов
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final AuthService _authService = AuthService();
  late Future<List<Complex>> _complexesFuture;
  Map<String, dynamic>? _nearbyProgram;

  @override
  void initState() {
    super.initState();
    _complexesFuture = _fetchComplexes();
    _loadNearbyProgram();
    LocaleService.addListener(_onLanguageChanged);
  }

  Future<void> _loadNearbyProgram() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    try {
      await AuthService.initCache();
      final programs = await _authService.fetchPrograms();
      Map<String, dynamic>? closestProgram;
      double maxProgress = 0.0;

      for (final program in programs) {
        final programId = program['id'] as int? ?? 0;
        if (programId <= 0) continue;

        final userProg = await _authService.getOrCreateUserProgram(programId);
        if (userProg == null) continue;

        final days = await _authService.fetchProgramDays(programId);
        await _authService.initializeAllProgramDays(userProg, days);

        final userProgData = await _authService.getUserProgram(userProg);
        final progress =
            (userProgData?['progress_percent'] as int? ?? 0) / 100.0;
        final isCompleted = userProgData?['is_completed'] as bool? ?? false;

        if (!isCompleted && progress > maxProgress) {
          maxProgress = progress;
          closestProgram = program;
        }
      }

      if (mounted) {
        setState(() {
          _nearbyProgram = closestProgram;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onLanguageChanged() async {
    debugPrint('Language changed in start_screen');
    await AuthService.clearCaches();
    if (mounted) {
      _complexesFuture = _fetchComplexes();
      setState(() {});
    }
  }

  @override
  void dispose() {
    LocaleService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<List<Complex>> _fetchComplexes() async {
    debugPrint('*** _fetchComplexes called ***');
    try {
      await AuthService.initCache();
      final response = await _authService.fetchComplexes();
      debugPrint('*** fetchComplexes returned ${response.length} items ***');
      if (response.isNotEmpty) {
        debugPrint('First raw complex: ${response.first}');
        debugPrint(
          'First complex keys: ${(response.first as Map).keys.toList()}',
        );
      }
      final complexes = response.map((json) => Complex.fromJson(json)).toList();
      debugPrint('*** Mapped ${complexes.length} Complex objects ***');
      if (complexes.isNotEmpty) {
        debugPrint(
          'First Complex object: id=${complexes.first.id}, name=${complexes.first.nameComplex}',
        );
      }
      return complexes;
    } catch (e, stack) {
      debugPrint('*** ERROR in _fetchComplexes: $e ***');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Шапка с серым фоном
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(255, 0, 0, 0), // Темно-серый сверху
                const Color.fromARGB(255, 39, 39, 39), // Светло-серый снизу
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Иконка баскетбольного мяча
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF4500).withOpacity(0.3),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'images/basketball_ico.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Текст заголовка
                Expanded(
                  child: Text(
                    LocaleService.translate('Тренировочные комплексы'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFA500), // Светло-оранжевый
                      fontFamily: 'Arial',
                      shadows: [
                        Shadow(
                          blurRadius: 15.0,
                          color: Color(0xFFFF4500).withOpacity(0.8),
                          offset: Offset(0, 0),
                        ),
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Основной контент
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: FutureBuilder<List<Complex>>(
                    future: _complexesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Ошибка загрузки: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'Нет данных',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      } else {
                        final complexes = snapshot.data!;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: complexes.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.9,
                              ),
                          itemBuilder: (context, index) {
                            final complex = complexes[index];
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                SettingsService.vibrate();
                                SettingsService.playClickSound();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WorkoutsPage(complex: complex),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenWidth = MediaQuery.of(
                                      context,
                                    ).size.width;
                                    final cardWidth = constraints.maxWidth;
                                    final fontSize = (cardWidth * 0.08).clamp(
                                      14.0,
                                      200.0,
                                    );
                                    final iconSize = (screenWidth * 0.08).clamp(
                                      25.0,
                                      200.0,
                                    );

                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(
                                                  0xFFFFA500,
                                                ), // Оранжевый 0xFFFFA500
                                                Color(
                                                  0xFFDC143C,
                                                ), // Красный 0xFFDC143C
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(
                                                  0xFFFFA500,
                                                ).withOpacity(0.5),
                                                blurRadius: 15,
                                                spreadRadius: 5,
                                              ),
                                              BoxShadow(
                                                color: Color(
                                                  0xFFDC143C,
                                                ).withOpacity(0.4),
                                                blurRadius: 20,
                                                spreadRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            margin: EdgeInsets.all(
                                              3,
                                            ), // Толщина градиентной рамки
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              color: Colors
                                                  .black, // Цвет фона внутри рамки
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              child: Hero(
                                                tag:
                                                    'complex-image-${complex.id}',
                                                child:
                                                    _authService
                                                        .getImageUrl(
                                                          complex.image ?? '',
                                                        )
                                                        .startsWith('images/')
                                                    ? Image.asset(
                                                        complex.image ?? '',
                                                        fit: BoxFit.cover,
                                                      ) // Для локальных изображений
                                                    : Image.network(
                                                        // Для изображений из Supabase Storage
                                                        _authService
                                                            .getImageUrl(
                                                              complex.image ??
                                                                  '',
                                                            ),
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              debugPrint(
                                                                '--- ОШИБКА ЗАГРУЗКИ ИЗОБРАЖЕНИЯ:',
                                                              );
                                                              debugPrint(
                                                                'URL: ${_authService.getImageUrl(complex.image ?? '')}',
                                                              );
                                                              debugPrint(
                                                                'Ошибка: $error',
                                                              );

                                                              return Container(
                                                                color:
                                                                    Colors.grey,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 40,
                                                                ),
                                                              );
                                                            },
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 8,
                                          bottom: 8,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              complex.translatedName.replaceAll(
                                                ' ',
                                                '\n',
                                              ),
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: fontSize,
                                                color: Colors.white,
                                                fontFamily: 'Arial',
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 8,
                                          bottom: 8,
                                          child: Image.asset(
                                            'icons/ball.png',
                                            width: iconSize,
                                            height: iconSize,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                ..._nearbyProgram != null
                    ? [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              LocaleService.translate('Близко к завершению'),
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Color(0xFFFFA500),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildNearbyProgramCard(),
                      ]
                    : [],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyProgramCard() {
    final programName = LocaleService.translateDbData(
      _nearbyProgram!['name_program'] ?? _nearbyProgram!['name'] ?? '',
    );
    final description = _nearbyProgram!['description'] ?? '';
    final programId = _nearbyProgram!['id'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
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
                builder: (context) => ProgramDaysPage(
                  programId: programId,
                  programName: programName,
                  programDescription: description,
                  programImage: null,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  programName,
                  style: const TextStyle(
                    color: Color(0xFFFF4500),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    LocaleService.translateDbData(description),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                FutureBuilder<double>(
                  future: _getProgramProgress(),
                  builder: (context, snapshot) {
                    final progress = snapshot.data ?? 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFA500),
                          ),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: Color(0xFFFFA500),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<double> _getProgramProgress() async {
    final programId = _nearbyProgram!['id'] as int? ?? 0;
    if (programId <= 0) return 0.0;

    try {
      final userProg = await _authService.getOrCreateUserProgram(programId);
      if (userProg == null) return 0.0;

      final userProgData = await _authService.getUserProgram(userProg);
      return (userProgData?['progress_percent'] as int? ?? 0) / 100.0;
    } catch (e) {
      return 0.0;
    }
  }
}
