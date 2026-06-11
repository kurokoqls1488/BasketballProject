import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/locale_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'ru';

  String _t(String key) => LocaleService.translate(key);

  void _onLanguageChanged() {
    if (mounted) {
      _loadSettings();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    LocaleService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LocaleService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _vibrationEnabled = SettingsService.vibrationEnabled;
      _selectedLanguage = LocaleService.currentLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFF121212)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _t('Настройки'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Язык'),
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildDropdownTile(
                  title: _t('Выберите язык'),
                  value: _selectedLanguage == 'ru' ? 'Русский' : 'English',
                  items: const ['Русский', 'English'],
                  onChanged: (value) async {
                    final newLang = value == 'Русский' ? 'ru' : 'en';
                    await SettingsService.setLanguage(newLang);
                    setState(() {
                      _selectedLanguage = newLang;
                    });
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  _t('Вибрация'),
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildSwitchTile(
                  title: _t('Вибрация'),
                  subtitle: _t('Вибрация при нажатиях'),
                  value: _vibrationEnabled,
                  onChanged: (value) async {
                    await SettingsService.setVibrationEnabled(value);
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  _t('Данные'),
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildActionTile(
                  title: _t('Очистка кэша'),
                  icon: Icons.delete_outline,
                   onTap: () async {
                     final confirm = await showDialog<bool>(
                       context: context,
                       builder: (context) => AlertDialog(
                         backgroundColor: const Color(0xFF1A1A1A),
                         title: Text(
                           _t('Очистка кэша'),
                           style: const TextStyle(color: Colors.white),
                         ),
                         content: Text(
                           LocaleService.translate('Вы уверены?'),
                           style: const TextStyle(color: Colors.white70),
                         ),
                         actions: [
                           TextButton(
                             onPressed: () => Navigator.pop(context, false),
                             child: Text(
                               _t('Отмена'),
                               style: const TextStyle(color: Colors.white54),
                             ),
                           ),
                           TextButton(
                             onPressed: () => Navigator.pop(context, true),
                             child: Text(
                               _t('Очистить'),
                               style: const TextStyle(color: Color(0xFFFFA500)),
                             ),
                           ),
                         ],
                       ),
                     );
                     if (confirm != true) return;
                     await SettingsService.clearCache();
                     if (!mounted) return;
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text(
                           LocaleService.translate('Кэш очищен'),
                           style: const TextStyle(color: Colors.white),
                         ),
                         backgroundColor: const Color(0xFF1A1A1A),
                       ),
                     );
                   },
                ),
                const SizedBox(height: 30),
                Text(
                  _t('Обратная связь'),
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildActionTile(
                  title: _t('Связаться с нами'),
                  icon: Icons.email_outlined,
                  onTap: () {},
                ),
                _buildActionTile(
                  title: _t('Оценить приложение'),
                  icon: Icons.star_outline,
                  onTap: () {},
                ),
                _buildActionTile(
                  title: _t('Поделиться приложением'),
                  icon: Icons.share_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 30),
                Text(
                  _t('О приложении'),
                  style: const TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildInfoTile(title: _t('Версия приложения'), value: '1.0.0'),
                _buildInfoTile(
                  title: _t('Разработчик'),
                  value: 'Basketball Training Team',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFA500).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFA500).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFFFFA500),
            size: 28,
          ),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
              .toList(),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          item == 'Русский' ? Icons.language : Icons.public,
                          color: const Color(0xFFFFA500),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item,
                          style: TextStyle(
                            color: value == item
                                ? const Color(0xFFFFA500)
                                : Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFA500).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFA500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFA500).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFFA500), size: 24),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFA500),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
