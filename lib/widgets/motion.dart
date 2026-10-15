import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// يصغر قليلًا عند الضغط ثم يرجع — إحساس لمس حيّ كتطبيقات آيفون.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// ظهور ناعم (تلاشٍ + انزلاق لأعلى) لأقسام الشاشة.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int order;
  const FadeSlideIn({super.key, required this.child, this.order = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + order * 110),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
      ),
      child: child,
    );
  }
}

/// شريط يتحرك بهدوء بلا توقف (ميزات المتجر).
class Marquee extends StatefulWidget {
  final List<Widget> children;
  final double speed;
  final double height;
  const Marquee({super.key, required this.children, this.speed = 26, this.height = 40});

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  final _sc = ScrollController();
  late final _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_sc.hasClients) _sc.jumpTo(_sc.offset + widget.speed * dt);
  }

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, i) => widget.children[i % n],
      ),
    );
  }
}
