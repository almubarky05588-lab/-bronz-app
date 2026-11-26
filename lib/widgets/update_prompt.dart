import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_version.dart';
import '../core/push.dart';
import '../core/remote_config.dart';
import '../core/theme.dart';

/// نافذة «تحديث جديد متوفّر»:
/// - نسخة أحدث في App Store → نافذة فيها «لاحقًا» (مرة وحدة باليوم بالكثير)
/// - النسخة أقدم من «أقل نسخة مسموحة» في اللوحة → تحديث إجباري بدون «لاحقًا»
class UpdatePrompt {
  UpdatePrompt._();
  static const _appStoreId = '6823190822';
  static const _storeUrl = 'https://apps.apple.com/sa/app/id$_appStoreId';
  static const _dayKey = 'update_prompt_day';
  static bool _showing = false;

  /// يقارن نسختين مثل 1.0.9 و 1.0.10 — موجب لو a أحدث.
  static int compare(String a, String b) {
    List<int> p(String v) => v.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final x = p(a), y = p(b);
    for (var i = 0; i < 4; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }

  /// آخر نسخة منشورة في App Store (السعودية).
  static Future<String?> _storeVersion() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(
          'https://itunes.apple.com/lookup?id=$_appStoreId&country=sa&t=${DateTime.now().millisecondsSinceEpoch}'));
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final m = jsonDecode(await res.transform(utf8.decoder).join());
      final r = (m is Map && m['results'] is List && (m['results'] as List).isNotEmpty) ? (m['results'] as List).first : null;
      final v = r is Map ? '${r['version'] ?? ''}'.trim() : '';
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// يفحص ويعرض النافذة لو لزم. يرجع true لو التحديث إجباري (التطبيق يوقف هنا).
  static Future<bool> check() async {
    if (_showing) return false;
    final min = RemoteConfig.instance.config.value?.minVersion ?? '';
    final forced = min.isNotEmpty && compare(appVersion, min) < 0;

    if (!forced) {
      final latest = await _storeVersion();
      if (latest == null || compare(latest, appVersion) <= 0) return false;
      // النافذة العادية: مرة وحدة باليوم
      try {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (prefs.getString(_dayKey) == today) return false;
        await prefs.setString(_dayKey, today);
      } catch (_) {}
    }

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return false;
    _showing = true;
    await showGeneralDialog(
      context: context,
      barrierDismissible: !forced,
      barrierLabel: 'إغلاق',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, __) => PopScope(canPop: !forced, child: _UpdateCard(forced: forced)),
      transitionBuilder: (ctx, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * a.value, sigmaY: 6 * a.value),
          child: FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(c), child: child),
          ),
        );
      },
    );
    _showing = false;
    return forced;
  }

  static Future<void> openStore() =>
      launchUrl(Uri.parse('itms-apps://itunes.apple.com/app/id$_appStoreId'), mode: LaunchMode.externalApplication)
          .catchError((_) => launchUrl(Uri.parse(_storeUrl), mode: LaunchMode.externalApplication));
}

class _UpdateCard extends StatelessWidget {
  final bool forced;
  const _UpdateCard({required this.forced});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF6EBD6), Color(0xFFE6CF9E)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('✨', style: TextStyle(fontSize: 34)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'تحديث جديد متوفّر',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: BronzColors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  forced
                      ? 'نسختك من برونز قديمة وما عاد تشتغل بشكل صحيح. حدّث التطبيق عشان تكمل تسوّقك.'
                      : 'حدّث برونز واستمتع بأحدث المزايا وتجربة أسرع وأسلس.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.6, color: BronzColors.muted),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: UpdatePrompt.openStore,
                    style: FilledButton.styleFrom(
                      backgroundColor: BronzColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: const Text('حدّث الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                if (!forced)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('لاحقًا', style: TextStyle(color: BronzColors.muted, fontWeight: FontWeight.w600)),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
