import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/locale_service.dart';
import 'start_screen.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final bool isRegistration;
  final String? nickname;

  const OTPVerificationPage({
    super.key,
    required this.email,
    this.isRegistration = false,
    this.nickname,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;
  int _resendCooldown = 0;

  String _t(String key) => LocaleService.translate(key);

  String? _validateOTP(String? val) {
    if (val == null || val.isEmpty) return _t('Введите код подтверждения');
    if (val.length != 8) return _t('Код должен состоять из 8 цифр');
    if (!RegExp(r'^\d{8}$').hasMatch(val)) return _t('Код должен содержать только цифры');
    return null;
  }

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final otp = _otpController.text.trim();

    bool success;

    if (widget.isRegistration) {
      success = await authProvider.registerWithOTP(
        widget.nickname!,
        widget.email,
        otp,
      );
    } else {
      success = await authProvider.loginWithOTP(widget.email, otp);
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Неверный код или код истек. Попробуйте снова.')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOTP(widget.email, isRegistration: widget.isRegistration);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Код отправлен повторно')),
            backgroundColor: Colors.green,
          ),
        );
        _startResendCooldown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('Не удалось отправить код. Попробуйте позже.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF121212),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.isRegistration ? _t('Подтверждение email') : _t('Вход'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: Colors.orange[400],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _t('Введите код подтверждения'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _t('Код отправлен на вашу почту'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFFFA500).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        controller: _otpController,
                        validator: _validateOTP,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: false,
                          hintText: '--------',
                          hintStyle: const TextStyle(
                            color: Colors.white30,
                            fontSize: 24,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA500), Color(0xFFDC143C)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4500).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: _isSubmitting ? null : _verifyOTP,
                          child: Center(
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _t('Подтвердить'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _resendCooldown > 0 ? null : _resendCode,
                      child: Text(
                        _resendCooldown > 0
                            ? '${_t('Отправить повторно')} ($_resendCooldown)'
                            : _t('Отправить код повторно'),
                        style: TextStyle(
                          color: _resendCooldown > 0 ? Colors.grey : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
