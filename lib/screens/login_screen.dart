import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/store_api.dart';
import '../core/theme.dart';

/// تسجيل الدخول برقم الجوال ورمز التحقق — بالكامل داخل التطبيق.
/// يُرجع true عند نجاح الدخول.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static Future<bool> open(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const LoginScreen()),
    );
    return ok ?? false;
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { phone, code, name }

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();

  _Step _step = _Step.phone;
  String _phone = '';
  bool _busy = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _run(Future<void> Function() job) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await job();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendCode() => _run(() async {
        final p = StoreApi.normalizePhone(_phoneCtrl.text);
        if (!StoreApi.isValidPhone(p)) {
          throw 'اكتب رقم جوال سعودي صحيح يبدأ بـ 5';
        }
        await StoreApi.sendCode(p);
        _phone = p;
        _codeCtrl.clear();
        setState(() => _step = _Step.code);
        _startCountdown();
      });

  Future<void> _resend() => _run(() async {
        await StoreApi.resendCode(_phone);
        _startCountdown();
      });

  Future<void> _verify() => _run(() async {
        final code = _codeCtrl.text.trim();
        if (code.length < 4) throw 'اكتب رمز التحقق كاملًا';
        final r = await StoreApi.verifyCode(_phone, code);
        if (r == VerifyResult.newCustomer) {
          setState(() => _step = _Step.name);
        } else if (mounted) {
          Navigator.of(context).pop(true);
        }
      });

  Future<void> _register() => _run(() async {
        final first = _firstCtrl.text.trim();
        final last = _lastCtrl.text.trim();
        if (first.isEmpty || last.isEmpty) throw 'اكتب الاسم الأول والأخير';
        await StoreApi.register(
          phone: _phone,
          code: _codeCtrl.text.trim(),
          firstName: first,
          lastName: last,
        );
        if (mounted) Navigator.of(context).pop(true);
      });

  void _back() {
    if (_step == _Step.phone) {
      Navigator.of(context).pop(false);
    } else {
      setState(() {
        _step = _Step.phone;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_step == _Step.phone ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _busy ? null : _back,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Text(
              'BRONZ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8),
            ),
            const SizedBox(height: 36),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  _Step.phone => _phoneStep(t),
                  _Step.code => _codeStep(t),
                  _Step.name => _nameStep(t),
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEDEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFB3261E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFB3261E)))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _title(TextTheme t, String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(sub, style: t.bodyMedium?.copyWith(color: BronzColors.muted, height: 1.5)),
          const SizedBox(height: 24),
        ],
      );

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E0D7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E0D7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BronzColors.ink, width: 1.4),
        ),
      );

  Widget _button(String label, VoidCallback onTap) => FilledButton(
        onPressed: _busy ? null : onTap,
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );

  Widget _phoneStep(TextTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(t, 'تسجيل الدخول', 'اكتب رقم جوالك ونرسل لك رمز تحقق. تسجّل مرة وحدة وتبقى داخل.'),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _phoneCtrl,
              autofocus: true,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [LengthLimitingTextInputFormatter(14)],
              style: const TextStyle(fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.w600),
              decoration: _field('5XXXXXXXX').copyWith(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    child: Text('🇸🇦  +966', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              onSubmitted: (_) => _sendCode(),
            ),
          ),
          const SizedBox(height: 20),
          _button('إرسال الرمز', _sendCode),
        ],
      );

  Widget _codeStep(TextTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(t, 'رمز التحقق', 'أرسلنا رمزًا إلى الرقم +966 $_phone'),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _codeCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(fontSize: 28, letterSpacing: 14, fontWeight: FontWeight.w800),
              decoration: _field('• • • •'),
              onChanged: (v) {
                if (v.length == 4 && !_busy) _verify();
              },
              onSubmitted: (_) => _verify(),
            ),
          ),
          const SizedBox(height: 20),
          _button('تأكيد', _verify),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _busy ? null : _back,
                child: const Text('تغيير الرقم'),
              ),
              const Text('·', style: TextStyle(color: BronzColors.muted)),
              TextButton(
                onPressed: (_busy || _resendIn > 0) ? null : _resend,
                child: Text(_resendIn > 0 ? 'إعادة الإرسال بعد $_resendIn ث' : 'إعادة إرسال الرمز'),
              ),
            ],
          ),
        ],
      );

  Widget _nameStep(TextTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(t, 'أهلًا فيك 👋', 'أول مرة تطلب من برونز؟ عرّفنا باسمك عشان نوصل طلبك.'),
          TextField(
            controller: _firstCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            decoration: _field('الاسم الأول'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastCtrl,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.familyName],
            decoration: _field('اسم العائلة'),
            onSubmitted: (_) => _register(),
          ),
          const SizedBox(height: 20),
          _button('متابعة', _register),
        ],
      );
}
