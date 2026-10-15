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
  static Future<void> maybeShow() async {
    final p = RemoteConfig.instance.config.value?.popup;
    if (p == null || !p.active || p.isEmpty || p.id.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'popup_seen_${p.id}';
      final last = prefs.getString(key);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (p.freq == 'once' && last != null) return;
      if (p.freq == 'daily' && last == today) return;
      await prefs.setString(key, today);
    } catch (_) {}

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showGeneralDialog(
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
  }

  /// وجهة زر البوب اب بصيغة بيانات الإشعار نفسها.
  static Map<String, dynamic>? _target(PopupConfig p) {
    String digits(String pattern) {
      final m = RegExp(pattern).firstMatch(p.value);
      if (m != null) return m.group(1)!;
      return RegExp(r'^\d+$').hasMatch(p.value) ? p.value : '';
    }

    switch (p.open) {
      case 'offers':
        return {'offers': '1'};
      case 'latest':
        return {'latest': '1'};
      case 'product':
        final id = digits(r'/p(\d+)');
        return id.isEmpty ? null : {'product_id': id};
      case 'category':
        final id = digits(r'/c(\d+)');
        return id.isEmpty ? null : {'category_id': id};
      case 'url':
        return p.value.isEmpty ? null : {'url': p.value};
    }
    return null;
  }
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
