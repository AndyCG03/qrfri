part of '../../app/app.dart';

class QrVisual extends StatelessWidget {
  const QrVisual({super.key, required this.item, this.size = 220});
  final QrItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final alignment = item.logoPlacement == 1 ? Alignment.topCenter : item.logoPlacement == 2 ? Alignment.bottomCenter : Alignment.center;
    // Las miniaturas tienen un espacio disponible fijo; reducir el quiet zone evita
     // que el padding se sume al tamaño del QR y desborde el contenedor.
    final compact = size < 96;
    final qrPadding = compact ? 0.0 : item.quietZone.clamp(2, 16).toDouble();
    return Container(
      width: size + qrPadding * 2,
      padding: EdgeInsets.all(qrPadding),
      decoration: BoxDecoration(
        color: item.transparentExport ? Colors.transparent : Color(item.background).withValues(alpha: item.backgroundOpacity),
        gradient: item.gradient ? (item.radialGradient ? RadialGradient(colors: [Color(item.background), Color(item.foreground).withValues(alpha: .14)]) : LinearGradient(colors: [Color(item.background), Color(item.foreground).withValues(alpha: .14)], begin: _gradientAlignment(item.gradientAngle), end: _gradientAlignment(item.gradientAngle, end: true))) : item.backgroundTexture ? LinearGradient(colors: [Color(item.background), Color(item.foreground).withValues(alpha: .05)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(item.frame == 4 ? 26 : item.frame == 2 ? 6 : 18),
        border: !compact && item.frame > 0 ? Border.all(color: Color(item.frameColor), width: item.frameThickness.clamp(1, 8).toDouble()) : null,
        boxShadow: !compact && item.frameShadow ? [BoxShadow(color: Color(item.frameColor).withValues(alpha: item.shadowOpacity), blurRadius: 16, offset: const Offset(0, 6))] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: alignment,
            children: [
              QrImageView(
                key: ValueKey('${item.id}:${item.content}:${item.foreground}:${item.background}:${item.backgroundOpacity}:${item.gradient}:${item.radialGradient}:${item.module}:${item.eyeStyle}:${item.eyeColor}:${item.frame}:${item.logoEnabled}:${item.logoPath}:${item.logoPlacement}:${item.logoSize}:${item.correction}'),
                data: item.content,
                version: QrVersions.auto,
                errorCorrectionLevel: _qrErrorCorrection(item.correction),
                size: size,
                padding: EdgeInsets.zero,
                backgroundColor: item.transparentExport || item.gradient || item.backgroundOpacity < 1 ? Colors.transparent : Color(item.background),
                eyeStyle: QrEyeStyle(eyeShape: item.eyeStyle >= 1 ? QrEyeShape.circle : QrEyeShape.square, color: Color(item.eyeColor)),
                dataModuleStyle: QrDataModuleStyle(dataModuleShape: item.module >= 1 && item.cornerRadius > .25 ? QrDataModuleShape.circle : QrDataModuleShape.square, color: Color(item.foreground)),
              ),
              if (item.logoEnabled)
                Container(
                  width: size * item.logoSize.clamp(.12, .28).toDouble(),
                  height: size * item.logoSize.clamp(.12, .28).toDouble(),
                  padding: EdgeInsets.all(item.logoPadding.clamp(0, compact ? 3 : 12).toDouble()),
                  decoration: BoxDecoration(color: _logoBackdrop(item.logoBackground, item.logoPath), shape: item.logoMask == 0 ? BoxShape.circle : BoxShape.rectangle, borderRadius: item.logoMask == 0 ? null : BorderRadius.circular(item.logoMask == 3 ? 0 : item.logoMask == 2 ? 3 : 12), border: item.logoBorder ? Border.all(color: Color(item.foreground), width: 1.2) : null),
                  child: item.logoPath != null ? Image.file(File(item.logoPath!), key: ValueKey('${item.id}:${item.logoPath}'), fit: BoxFit.contain, errorBuilder: (_, __, ___) => Image.asset('assets/vertical.png', fit: BoxFit.contain)) : Image.asset('assets/vertical.png', fit: BoxFit.contain),
                ),
            ],
          ),
        ],
      ),
    );
  }

}

class _QrTypeBadge extends StatelessWidget {
  const _QrTypeBadge({required this.type, this.size = 34});
  final QrType type;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: QrFriColors.indigo, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2)),
     child: Semantics(label: 'QRfri · ${context.qrL10n.typeLabel(type)}', child: Icon(type.icon, size: size * .5, color: Colors.white)),
  );
}

class _QrWithTypeBadge extends StatelessWidget {
  const _QrWithTypeBadge({required this.item, required this.size});
  final QrItem item;
  final double size;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      QrVisual(item: item, size: size),
      Positioned(right: -3, top: -3, child: _QrTypeBadge(type: item.type, size: size < 60 ? 25 : 34)),
    ],
  );
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.favorite, required this.onChanged});
  final bool favorite;
  final ValueChanged<bool> onChanged;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  late final Animation<double> _scale = Tween(begin: .78, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: IconButton(
      tooltip: widget.favorite ? context.qrL10n.t('library.favorite.remove') : context.qrL10n.t('library.favorite.add'),
      onPressed: () { _controller.forward(from: 0); widget.onChanged(!widget.favorite); },
      icon: Icon(widget.favorite ? Icons.favorite : Icons.favorite_border, color: widget.favorite ? QrFriColors.indigo : Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class QrCard extends StatelessWidget {
  const QrCard({super.key, required this.item, required this.store});
  final QrItem item;
  final LocalStore store;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _show(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Center(child: _QrWithTypeBadge(item: item, size: 110))),
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(children: [Expanded(child: Text(context.qrL10n.typeLabel(item.type), style: Theme.of(context).textTheme.bodySmall)), _FavoriteButton(favorite: item.favorite, onChanged: (value) => store.replace(item.copyWith(favorite: value)))]),
        ]),
      ),
    ),
  );

  void _show(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(item: item, store: store)));
}

class QrListTile extends StatelessWidget {
  const QrListTile({super.key, required this.item, required this.store});
  final QrItem item;
  final LocalStore store;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(item: item, store: store))),
      leading: _QrWithTypeBadge(item: item, size: 42),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
     subtitle: Text('${context.qrL10n.typeLabel(item.type)} · ${DateFormat('d MMM yyyy', Localizations.localeOf(context).languageCode).format(item.createdAt)}'),
      trailing: _FavoriteButton(favorite: item.favorite, onChanged: (value) => store.replace(item.copyWith(favorite: value))),
    ),
  );
}

