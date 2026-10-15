import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/push.dart';
import '../core/remote_config.dart';
import '../core/theme.dart';
import 'common.dart';
import 'motion.dart';

/// البوب اب الترويجي — يُدار من «لوحة برونز».
class PromoPopup {
  static bool _showing = false;

  /// ينتظر وصول الإعدادات (حتى 15 ثانية) ثم يعرض البوب اب إن كان مفعّلًا.
  static Future<void> showWhenReady() async {
    final cfg = RemoteConfig.instance.config;
    if (cfg.value == null) {
      final done = Completer<void>();
      void listener() {
        if (cfg.value != null && !done.isCompleted) done.complete();
      }

      cfg.addListener(listener);
      try {
        await done.future.timeout(const Duration(seconds: 15));
      } catch (_) {
      } finally {
        cfg.removeListener(listener);
      }
    }
    await maybeShow();
  }

  static Future<void> maybeShow() async {
    if (_showing) return;
    final p = RemoteConfig.instance.config.value?.popup;
    if (p == null || !p.active || p.isEmpty || p.id.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    SharedPreferences? prefs;
    final key = 'popup_seen_${p.id}';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(key);
      if (p.freq == 'once' && last != null) return;
      if (p.freq == 'daily' && last == today) return;
    } catch (_) {}

    if (!context.mounted) return;
    _showing = true;
    final dialog = showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, __) => _PopupCard(p),
      transitionBuilder: (ctx, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * a.value, sigmaY: 6 * a.value),
          child: FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.88, end: 1.0).animate(c), child: child),
          ),
        );
      },
    );
    // يُسجَّل «انعرض» بعد ما يطلع فعلًا
    try {
      await prefs?.setString(key, today);
    } catch (_) {}
    await dialog;
    _showing = false;
  }

  /// وجهة زر البوب اب بصيغة بيانات الإشعار نفسها.
  static Map<String, dynamic>? _target(PopupConfig p) => LinkTarget(p.open, p.value).data(title: p.title);
}

class _PopupCard extends StatelessWidget {
  final PopupConfig p;
  const _PopupCard(this.p);

  @override
  Widget build(BuildContext context) {
    final target = PromoPopup._target(p);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 18))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.image.isNotEmpty)
                          Container(
                            height: 230,
                            width: double.infinity,
                            color: Colors.white,
                            child: NetImage(p.image, padding: 14),
                          ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(22, p.image.isEmpty ? 30 : 6, 22, 22),
                          child: Column(
                            children: [
                              if (p.title.isNotEmpty)
                                Text(
                                  p.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
                                ),
                              if (p.body.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  p.body,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14.5, color: BronzColors.muted, height: 1.6),
                                ),
                              ],
                              const SizedBox(height: 18),
                              Pressable(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  if (target != null) Push.open(target);
                                },
                                child: Container(
                                  height: 50,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFC9A66B), Color(0xFF9C7842)],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                  ),
                                  child: Text(
                                    target == null ? 'تمام' : (p.button.isEmpty ? 'تسوّق الآن' : p.button),
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: BronzColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
