import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/favorites.dart';
import '../core/store_api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/product_card.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<String?> _who = _load();

  /// null = زائر، نص = اسم العميل المسجّل
  Future<String?> _load() async {
    if (!await StoreApi.isLoggedIn()) return null;
    return (await StoreApi.customerName()) ?? '';
  }

  void _refresh() => setState(() => _who = _load());

  Future<void> _login() async {
    final ok = await LoginScreen.open(context);
    if (ok && mounted) {
      showBronzToast(context, 'تم تسجيل الدخول');
      _refresh();
    }
  }

  Future<void> _logout() async {
    try {
      await StoreApi.logout();
    } catch (_) {}
    if (!mounted) return;
    showBronzToast(context, 'تم تسجيل الخروج', icon: PhosphorIcons.signOut());
    _refresh();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) showBronzToast(context, 'تعذّر فتح الرابط', icon: Icons.info_outline_rounded);
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      );

  BoxDecoration get _card => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BronzColors.line),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          FadeSlideIn(
            child: FutureBuilder<String?>(
              future: _who,
              builder: (context, s) {
                final loading = s.connectionState != ConnectionState.done;
                final String? name = s.data;
                final logged = !loading && name != null;
                final first = name ?? '';
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111111), Color(0xFF3A2E22)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: Color(0x22FFFFFF), shape: BoxShape.circle),
                        child: Icon(PhosphorIcons.user(), color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              logged
                                  ? (first.isEmpty ? 'أهلًا بك' : 'أهلًا $first')
                                  : 'أهلًا بك في برونز',
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              logged ? 'حسابك مسجّل — طلباتك صارت أسرع' : 'سجّل دخولك برقم جوالك',
                              style: const TextStyle(color: BronzColors.goldSoft, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (!loading)
                        Pressable(
                          onTap: logged ? _logout : _login,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: logged ? const Color(0x22FFFFFF) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              logged ? 'خروج' : 'دخول',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: logged ? Colors.white : BronzColors.ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 26),

          // ─── المفضلة ───
          FadeSlideIn(
            order: 1,
            child: ListenableBuilder(
              listenable: Favorites.instance,
              builder: (context, _) {
                final favs = Favorites.instance.items;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('المفضلة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        if (favs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: BronzColors.soft, borderRadius: BorderRadius.circular(10)),
                            child: Text('${favs.length}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (favs.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        decoration: _card,
                        child: Column(
                          children: [
                            Icon(PhosphorIcons.heart(), size: 34, color: BronzColors.gold),
                            const SizedBox(height: 10),
                            const Text('ما أضفت شي للمفضلة بعد', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text('اضغط القلب على أي منتج يعجبك ويظهر هنا',
                                style: TextStyle(color: BronzColors.muted, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: favs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.58,
                        ),
                        itemBuilder: (_, i) => ProductCard(product: favs[i]),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 26),

          // ─── تواصل معنا ───
          FadeSlideIn(
            order: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section('تواصل معنا'),
                Container(
                  decoration: _card,
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: Icons.chat_rounded,
                        tint: const Color(0xFF25D366),
                        title: 'واتساب',
                        sub: StoreConfig.phoneDisplay,
                        onTap: () => _open('https://wa.me/${StoreConfig.whatsapp}'),
                      ),
                      const Divider(height: 1, indent: 66, color: BronzColors.line),
                      _ContactRow(
                        icon: Icons.call_rounded,
                        tint: BronzColors.ink,
                        title: 'اتصال',
                        sub: StoreConfig.phoneDisplay,
                        onTap: () => _open('tel:+${StoreConfig.whatsapp}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // ─── ليش برونز ───
          FadeSlideIn(
            order: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section('ليش برونز؟'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: _card,
                  child: Column(
                    children: [
                      _Perk(PhosphorIcons.sealCheck(), 'أصلي 100%', 'كل منتجاتنا أصلية بضمان متجر برونز'),
                      const Divider(height: 1, indent: 60, color: BronzColors.line),
                      _Perk(PhosphorIcons.truck(), 'شحن سريع', 'نوصّل لجميع مدن المملكة'),
                      const Divider(height: 1, indent: 60, color: BronzColors.line),
                      _Perk(PhosphorIcons.lock(), 'دفع آمن', 'مدى، فيزا، ماستركارد وغيرها'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: BronzLogo(width: 90)),
          const SizedBox(height: 4),
          const Center(
            child: Text('عطور أصلية بلمسة فخامة', style: TextStyle(color: BronzColors.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _ContactRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: BronzColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretLeft(), size: 15, color: BronzColors.muted),
          ],
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _Perk(this.icon, this.title, this.sub);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: BronzColors.soft, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: BronzColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: BronzColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
