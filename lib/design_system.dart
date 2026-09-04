import 'package:flutter/material.dart';
import 'localization.dart';

/// QRfri visual language: indigo for action and trust, emerald for momentum.
abstract final class QrFriColors {
  static const indigo = Color(0xff3730e0);
  static const indigoDark = Color(0xff27238f);
  static const emerald = Color(0xff0fae6b);
  static const ink = Color(0xff0f172a);
  static const slate = Color(0xff334155);
  static const muted = Color(0xff64748b);
  static const border = Color(0xffe2e8f0);
  static const surface = Color(0xfff8fafc);
  static const white = Color(0xffffffff);
  static const success = Color(0xff0f9f68);
  static const warning = Color(0xffc47a15);
  static const error = Color(0xffc2415d);
  static const info = Color(0xff2563a8);
  static const darkSurface = Color(0xff111a2d);
  static const darkRaised = Color(0xff1b2740);
}

abstract final class QrFriSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 20.0;
}

abstract final class QrFriRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const pill = 999.0;
}

abstract final class QrFriElevation {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x120f172a), blurRadius: 18, offset: Offset(0, 8)),
  ];
  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x1f3730e0), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

enum QrToastKind { info, success, warning, error }

void showQrToast(BuildContext context, String message, {QrToastKind kind = QrToastKind.info}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final scheme = Theme.of(context).colorScheme;
  final color = switch (kind) {
    QrToastKind.success => QrFriColors.success,
    QrToastKind.warning => QrFriColors.warning,
    QrToastKind.error => scheme.error,
    QrToastKind.info => QrFriColors.indigo,
  };
  final foreground = kind == QrToastKind.warning ? QrFriColors.ink : Colors.white;
  final icon = switch (kind) {
    QrToastKind.success => Icons.check_circle_outline,
    QrToastKind.warning => Icons.warning_amber_rounded,
    QrToastKind.error => Icons.error_outline,
    QrToastKind.info => Icons.info_outline,
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: kind == QrToastKind.error || kind == QrToastKind.warning ? 4 : 3),
        backgroundColor: color,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QrFriRadius.md)),
        content: Row(children: [Icon(icon, color: foreground, size: 20), const SizedBox(width: 10), Expanded(child: Text(message, style: TextStyle(color: foreground, fontWeight: FontWeight.w700)))]),
      ),
    );
}

Future<bool?> showQrConfirmation(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  bool destructive = false,
  IconData icon = Icons.help_outline,
}) => showDialog<bool>(
  context: context,
  builder: (dialogContext) {
    final scheme = Theme.of(dialogContext).colorScheme;
    final accent = destructive ? scheme.error : QrFriColors.indigo;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(QrFriRadius.sm)), child: Icon(icon, color: accent)), const SizedBox(width: 12), Expanded(child: Text(title, style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)))]),
              const SizedBox(height: 14),
              Text(description, style: Theme.of(dialogContext).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.qrL10n.t('common.cancel'))),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: destructive ? Colors.white : Colors.white), child: Text(confirmLabel)),
              ]),
            ],
          ),
        ),
      ),
    );
  },
);

ThemeData qrFriTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: QrFriColors.indigo,
    brightness: brightness,
    surface: dark ? QrFriColors.darkSurface : QrFriColors.surface,
    primary: QrFriColors.indigo,
    secondary: QrFriColors.emerald,
    error: QrFriColors.error,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? QrFriColors.darkSurface : QrFriColors.surface,
    fontFamily: 'Arial',
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? QrFriColors.darkSurface : QrFriColors.surface,
      foregroundColor: dark ? Colors.white : QrFriColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: dark ? Colors.white : QrFriColors.ink),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? QrFriColors.darkRaised : QrFriColors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QrFriRadius.lg), side: BorderSide(color: dark ? Colors.white12 : QrFriColors.border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? QrFriColors.darkRaised : QrFriColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(QrFriRadius.md), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(QrFriRadius.md), borderSide: BorderSide(color: dark ? Colors.white12 : QrFriColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(QrFriRadius.md), borderSide: const BorderSide(color: QrFriColors.indigo, width: 1.5)),
      labelStyle: TextStyle(color: dark ? Colors.white70 : QrFriColors.muted),
      hintStyle: TextStyle(color: dark ? Colors.white38 : QrFriColors.muted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? QrFriColors.darkRaised : QrFriColors.white,
      indicatorColor: QrFriColors.indigo.withValues(alpha: .14),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark ? Colors.white70 : QrFriColors.slate)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QrFriRadius.pill)),
      side: BorderSide(color: dark ? Colors.white12 : QrFriColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: QrFriColors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QrFriRadius.md)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: QrFriColors.indigo,
        side: const BorderSide(color: QrFriColors.indigo),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QrFriRadius.md)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    ),
    switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? QrFriColors.emerald : null), trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? QrFriColors.emerald.withValues(alpha: .35) : null)),
  );
}

class QrFriLogo extends StatelessWidget {
  const QrFriLogo({super.key, this.wordmark = true, this.height = 38});
  final bool wordmark;
  final double height;
  @override
  Widget build(BuildContext context) => Image.asset(wordmark ? 'assets/horizontal.png' : 'assets/vertical.png', height: height, fit: BoxFit.contain, semanticLabel: wordmark ? 'QRfri' : 'QRfri icon');
}

class QrFriSectionHeader extends StatelessWidget {
  const QrFriSectionHeader({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), if (action != null) TextButton(onPressed: onAction, child: Text(action!))]);
}

class QrFriStatusBadge extends StatelessWidget {
  const QrFriStatusBadge({super.key, required this.label, this.color = QrFriColors.emerald});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(QrFriRadius.pill)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))]));
}

/// Barra inferior compacta con estados animados y soporte claro/oscuro.
class QrFriBottomNavigationBar extends StatelessWidget {
  const QrFriBottomNavigationBar({super.key, required this.selectedIndex, required this.onDestinationSelected});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = <({IconData icon, IconData activeIcon, String key})>[
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, key: 'nav.home'),
    (icon: Icons.qr_code_2_outlined, activeIcon: Icons.qr_code_2_rounded, key: 'nav.library'),
    (icon: Icons.center_focus_weak, activeIcon: Icons.center_focus_strong, key: 'nav.scan'),
    (icon: Icons.tune_outlined, activeIcon: Icons.tune_rounded, key: 'nav.settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: dark ? QrFriColors.darkRaised : QrFriColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: dark ? Colors.white10 : QrFriColors.border),
          boxShadow: [
            BoxShadow(
              color: dark ? Colors.black26 : const Color(0x160f172a),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _QrFriBottomNavItem(
                  icon: _items[i].icon,
                  activeIcon: _items[i].activeIcon,
                  label: context.qrL10n.t(_items[i].key),
                  selected: selectedIndex == i,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QrFriBottomNavItem extends StatefulWidget {
  const _QrFriBottomNavItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_QrFriBottomNavItem> createState() => _QrFriBottomNavItemState();
}

class _QrFriBottomNavItemState extends State<_QrFriBottomNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = QrFriColors.indigo;
    final inactive = dark ? Colors.white54 : const Color(0xff94a3b8);
    final color = widget.selected ? active : inactive;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? .94 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: widget.selected ? active.withValues(alpha: dark ? .2 : .11) : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
                  child: Icon(widget.selected ? widget.activeIcon : widget.icon, key: ValueKey(widget.selected), color: color, size: 23),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600, height: 1.1),
                  child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
