part of '../../app/app.dart';

class EditorPage extends StatefulWidget { const EditorPage({super.key, required this.store, this.initialType, this.existing, this.initialContent, this.initialName}); final LocalStore store; final QrType? initialType; final QrItem? existing; final String? initialContent, initialName; @override State<EditorPage> createState() => _EditorPageState(); }
class _EditorPageState extends State<EditorPage> {
  late QrType type; final name = TextEditingController(); final fields = <String, TextEditingController>{}; int fg = 0xff172033, bg = 0xffffffff, module = 0; String caption = ''; String? logoPath;
  @override void initState() { super.initState(); final current = widget.existing; type = current?.type ?? widget.initialType ?? QrType.url; name.text = current?.name ?? widget.initialName ?? ''; fg = current?.foreground ?? fg; bg = current?.background ?? bg; module = current?.module ?? module; caption = current?.caption ?? ''; frame = current?.frame ?? 0; logoEnabled = current?.logoEnabled ?? false; captionFont = current?.captionFont ?? 0; logoPlacement = current?.logoPlacement ?? 0; gradient = current?.gradient ?? false; logoPath = current?.logoPath; backgroundOpacity = current?.backgroundOpacity ?? 1; gradientAngle = current?.gradientAngle ?? 45; radialGradient = current?.radialGradient ?? false; eyeStyle = current?.eyeStyle ?? 0; eyeColor = current?.eyeColor ?? 0xff172033; cornerRadius = current?.cornerRadius ?? .5; quietZone = current?.quietZone ?? 4; logoSize = current?.logoSize ?? .2; logoPadding = current?.logoPadding ?? 5; logoMask = current?.logoMask ?? 1; logoBackground = current?.logoBackground ?? 0xffffffff; logoBorder = current?.logoBorder ?? true; frameColor = current?.frameColor ?? 0xff3730e0; frameThickness = current?.frameThickness ?? 2; frameShadow = current?.frameShadow ?? false; shadowOpacity = current?.shadowOpacity ?? .12; captionAbove = current?.captionAbove ?? ''; captionAlign = current?.captionAlign ?? 1; captionColor = current?.captionColor ?? 0xff0f172a; correction = current?.correction ?? 1; exportSize = current?.exportSize ?? 1024; exportFormat = current?.exportFormat ?? 'PNG'; transparentExport = current?.transparentExport ?? false; backgroundTexture = current?.backgroundTexture ?? false; _resetFields(); final content = current?.content ?? widget.initialContent; if (content != null && content.trim().isNotEmpty) _populateFieldsFromPayload(content); }
  @override void dispose() { name.dispose(); for (final controller in fields.values) { controller.dispose(); } super.dispose(); }
  void _setField(String key, String? value) { final controller = fields[key]; if (controller != null && value != null) controller.text = value; }
  String _unescapeQr(String value) => value.replaceAll(r'\n', '\n').replaceAll(r'\;', ';').replaceAll(r'\,', ',').replaceAll(r'\\', '\\');
  String? _property(String raw, String name) {
    for (final line in raw.replaceAll('\r\n', '\n').split('\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).split(';').first.toUpperCase();
      if (key == name.toUpperCase() || key.endsWith('.${name.toUpperCase()}')) return _unescapeQr(line.substring(separator + 1).trim());
    }
    return null;
  }
  void _populateFieldsFromPayload(String raw) {
    final value = raw.trim();
    switch (type) {
      case QrType.url: _setField('URL', value); break;
      case QrType.contact:
        final isMecard = value.toUpperCase().startsWith('MECARD:');
        if (isMecard) {
          for (final token in value.substring(value.indexOf(':') + 1).split(';')) {
            final separator = token.indexOf(':');
            if (separator <= 0) continue;
            final key = token.substring(0, separator).toUpperCase();
            final tokenValue = _unescapeQr(token.substring(separator + 1));
            if (key == 'N') _setField('Nombre', tokenValue);
             if (key == 'TEL') _setField('Teléfono', tokenValue);
            if (key == 'EMAIL') _setField('Email', tokenValue);
            if (key == 'ORG') _setField('Empresa', tokenValue);
          }
        } else {
          _setField('Nombre', _property(value, 'FN'));
           _setField('Teléfono', _property(value, 'TEL'));
          _setField('Email', _property(value, 'EMAIL'));
          _setField('Empresa', _property(value, 'ORG'));
        }
        break;
      case QrType.business:
         _setField('Negocio', _property(value, 'ORG')); _setField('Teléfono', _property(value, 'TEL')); _setField('Dirección', _property(value, 'ADR')); _setField('Web', _property(value, 'URL')); break;
      case QrType.wifi:
         for (final token in value.replaceFirst(RegExp('^WIFI:', caseSensitive: false), '').split(';')) { final separator = token.indexOf(':'); if (separator <= 0) continue; final key = token.substring(0, separator).toUpperCase(); final tokenValue = _unescapeQr(token.substring(separator + 1)); if (key == 'S') _setField('SSID', tokenValue); if (key == 'P') _setField('Contraseña', tokenValue); } break;
      case QrType.whatsapp:
         final uri = Uri.tryParse(value); if (uri != null) { _setField('Número', uri.queryParameters['phone'] ?? (uri.pathSegments.isEmpty ? null : uri.pathSegments.last)); _setField('Mensaje', uri.queryParameters['text']); } break;
      case QrType.email:
        if (value.toUpperCase().startsWith('MATMSG:')) {
          for (final token in value.substring(value.indexOf(':') + 1).split(';')) { final separator = token.indexOf(':'); if (separator <= 0) continue; final key = token.substring(0, separator).toUpperCase(); final tokenValue = _unescapeQr(token.substring(separator + 1)); if (key == 'TO') _setField('Destinatario', tokenValue); if (key == 'SUB') _setField('Asunto', tokenValue); if (key == 'BODY') _setField('Mensaje', tokenValue); }
        } else {
          final uri = Uri.tryParse(value); if (uri != null) { _setField('Destinatario', uri.path); _setField('Asunto', uri.queryParameters['subject']); _setField('Mensaje', uri.queryParameters['body']); }
        }
        break;
       case QrType.phone: _setField('Número', value.replaceFirst(RegExp('^tel:', caseSensitive: false), '')); break;
      case QrType.sms:
        if (value.toUpperCase().startsWith('SMSTO:')) {
           final match = RegExp(r'^SMSTO:([^:]+)(?::(.*))?$', caseSensitive: false).firstMatch(value); _setField('Número', match?.group(1)); _setField('Mensaje', match?.group(2));
        } else {
           final uri = Uri.tryParse(value); if (uri != null) { _setField('Número', uri.path); _setField('Mensaje', uri.queryParameters['body']); }
        }
        break;
      case QrType.location:
        final match = RegExp(r'^geo:([^,]+),([^?]+)(?:\?q=(.*))?$', caseSensitive: false).firstMatch(value); _setField('Latitud', match?.group(1)); _setField('Longitud', match?.group(2)); _setField('Etiqueta', match?.group(3) == null ? null : Uri.decodeComponent(match!.group(3)!)); break;
      case QrType.event:
      case QrType.calendar:
         _setField('Título', _property(value, 'SUMMARY')); _setField('Inicio', _property(value, 'DTSTART')); _setField('Fin', _property(value, 'DTEND')); _setField('Lugar', _property(value, 'LOCATION')); _setField('Descripción', _property(value, 'DESCRIPTION')); break;
      case QrType.social:
        for (final line in value.split('\n')) { final separator = line.indexOf(':'); if (separator > 0) _setField(line.substring(0, separator).trim(), line.substring(separator + 1).trim()); } break;
      case QrType.crypto:
         final uri = Uri.tryParse(value); if (uri != null) { _setField('Moneda', uri.scheme); _setField('Dirección', uri.path); _setField('Importe', uri.queryParameters['amount']); } break;
      case QrType.appStore:
        for (final line in value.split('\n')) { final separator = line.indexOf(':'); if (separator <= 0) continue; final key = line.substring(0, separator); if (key.contains('App Store')) _setField('Enlace App Store', line.substring(separator + 1).trim()); if (key.contains('Play Store')) _setField('Enlace Play Store', line.substring(separator + 1).trim()); } break;
      case QrType.text: _setField('Contenido', value); break;
    }
  }
  int frame = 0; bool logoEnabled = false; int captionFont = 0; int logoPlacement = 0; bool gradient = false;
  double backgroundOpacity = 1, gradientAngle = 45, cornerRadius = .5, quietZone = 4, logoSize = .2, logoPadding = 5, frameThickness = 2, shadowOpacity = .12;
  bool radialGradient = false, logoBorder = true, frameShadow = false, transparentExport = false, backgroundTexture = false;
  int eyeStyle = 0, eyeColor = 0xff172033, logoMask = 1, logoBackground = 0xffffffff, frameColor = 0xff3730e0, captionAlign = 1, captionColor = 0xff0f172a, correction = 1, exportSize = 1024;
  String captionAbove = '', exportFormat = 'PNG';
  void _disposeFieldControllers() { for (final controller in fields.values) { controller.dispose(); } }
   void _resetFields() { fields.clear(); final keys = switch (type) { QrType.url => ['URL'], QrType.contact => ['Nombre', 'Teléfono', 'Email', 'Empresa'], QrType.wifi => ['SSID', 'Contraseña'], QrType.whatsapp => ['Número', 'Mensaje'], QrType.email => ['Destinatario', 'Asunto', 'Mensaje'], QrType.phone => ['Número'], QrType.sms => ['Número', 'Mensaje'], QrType.location => ['Latitud', 'Longitud', 'Etiqueta'], QrType.event || QrType.calendar => ['Título', 'Inicio', 'Fin', 'Lugar', 'Descripción'], QrType.social => ['Instagram', 'Facebook', 'LinkedIn'], QrType.business => ['Negocio', 'Teléfono', 'Dirección', 'Web'], QrType.crypto => ['Moneda', 'Dirección', 'Importe'], QrType.appStore => ['Enlace App Store', 'Enlace Play Store'], QrType.text => ['Contenido'] }; for (final key in keys) { fields[key] = TextEditingController(); } }
  String get payload {
    final values = {
      for (final entry in fields.entries) entry.key: entry.value.text.trim(),
    };
    String value(String key) => values[key] ?? '';

    return switch (type) {
      QrType.url => value('URL'),
       QrType.contact => 'BEGIN:VCARD\nVERSION:3.0\nFN:${value('Nombre')}\nORG:${value('Empresa')}\nTEL:${value('Teléfono')}\nEMAIL:${value('Email')}\nEND:VCARD',
       QrType.wifi => 'WIFI:T:WPA;S:${value('SSID')};P:${value('Contraseña')};;',
       QrType.whatsapp => 'https://wa.me/${value('Número').replaceAll(RegExp(r'[^0-9+]'), '')}?text=${Uri.encodeComponent(value('Mensaje'))}',
      QrType.email => 'mailto:${value('Destinatario')}?subject=${Uri.encodeComponent(value('Asunto'))}&body=${Uri.encodeComponent(value('Mensaje'))}',
       QrType.phone => 'tel:${value('Número')}',
       QrType.sms => 'SMSTO:${value('Número')}:${value('Mensaje')}',
      QrType.location => 'geo:${value('Latitud')},${value('Longitud')}?q=${Uri.encodeComponent(value('Etiqueta'))}',
       QrType.event || QrType.calendar => 'BEGIN:VEVENT\nSUMMARY:${value('Título')}\nDTSTART:${value('Inicio')}\nDTEND:${value('Fin')}\nLOCATION:${value('Lugar')}\nDESCRIPTION:${value('Descripción')}\nEND:VEVENT',
      QrType.social => 'Redes sociales\n${values.entries.where((entry) => entry.value.isNotEmpty).map((entry) => '${entry.key}: ${entry.value}').join('\n')}',
       QrType.business => 'BEGIN:VCARD\nVERSION:3.0\nORG:${value('Negocio')}\nTEL:${value('Teléfono')}\nADR:${value('Dirección')}\nURL:${value('Web')}\nEND:VCARD',
       QrType.crypto => '${value('Moneda')}:${value('Dirección')}${value('Importe').isEmpty ? '' : '?amount=${value('Importe')}'}',
      QrType.appStore => 'App Store: ${value('Enlace App Store')}\nPlay Store: ${value('Enlace Play Store')}',
      QrType.text => value('Contenido'),
    };
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? context.qrL10n.t('editor.create') : context.qrL10n.t('editor.edit')),
        actions: [
          IconButton(tooltip: context.qrL10n.t('editor.help'), onPressed: _showFieldHelp, icon: const Icon(Icons.help_outline)),
          IconButton(tooltip: context.qrL10n.t('common.save'), onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(gradient: gradient ? LinearGradient(colors: [Color(bg), Color(fg).withValues(alpha: .16)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null, color: gradient ? null : Color(bg), borderRadius: BorderRadius.circular(12), border: frame > 0 ? Border.all(color: Color(fg), width: frame == 2 ? 3 : 1.5) : null),
                  child: Stack(alignment: logoPlacement == 1 ? Alignment.topCenter : logoPlacement == 2 ? Alignment.bottomCenter : Alignment.center, children: [
                    QrImageView(key: ValueKey('editor-qr:$payload:$fg:$bg:$module:$eyeStyle:$eyeColor:$correction'), data: payload.isEmpty ? 'QRfri' : payload, version: QrVersions.auto, errorCorrectionLevel: _qrErrorCorrection(correction), size: 220, eyeStyle: QrEyeStyle(eyeShape: eyeStyle >= 1 ? QrEyeShape.circle : QrEyeShape.square, color: Color(eyeColor)), dataModuleStyle: QrDataModuleStyle(dataModuleShape: module >= 1 ? QrDataModuleShape.circle : QrDataModuleShape.square, color: Color(fg)), backgroundColor: Color(bg)),
                    if (logoEnabled) Container(width: 48, height: 48, padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(bg), width: 2)), child: logoPath != null ? Image.file(File(logoPath!), key: ValueKey('editor-logo:$logoPath'), fit: BoxFit.contain) : Image.asset('assets/vertical.png', key: const ValueKey('editor-logo-default'), fit: BoxFit.contain)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(context.qrL10n.t('editor.contentType'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          DropdownButtonFormField<QrType>(
            initialValue: type,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
            items: QrType.values.map((t) => DropdownMenuItem(value: t, child: Row(children: [Icon(t.icon, size: 19), const SizedBox(width: 10), Text(context.qrL10n.typeLabel(t))]))).toList(),
            onChanged: (value) {
              if (value != null) setState(() { _disposeFieldControllers(); type = value; _resetFields(); });
            },
          ),
          const SizedBox(height: 14),
          TextField(controller: name, decoration: InputDecoration(labelText: context.qrL10n.t('editor.name'), prefixIcon: const Icon(Icons.label_outline))),
          const SizedBox(height: 14),
          ...fields.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: entry.value,
              onChanged: (_) => setState(() {}),
               maxLines: entry.key == 'Mensaje' || entry.key == 'Descripción' || entry.key == 'Contenido' ? 3 : 1,
              keyboardType: entry.key.contains('Email') || entry.key.contains('Web') || entry.key == 'URL' ? TextInputType.url : TextInputType.text,
              decoration: InputDecoration(labelText: context.qrL10n.fieldLabel(entry.key), prefixIcon: Icon(_fieldIcon(entry.key))),
            ),
          )),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined, color: QrFriColors.indigo),
              title: Text(context.qrL10n.t('editor.design'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(context.qrL10n.t('editor.design.subtitle')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ComprehensiveDesignPage(
                  data: payload,
                  store: widget.store,
                  foreground: fg,
                  background: bg,
                  module: module,
                  frame: frame,
                  logoEnabled: logoEnabled,
                  logoPath: logoPath,
                  logoPlacement: logoPlacement,
                  gradient: gradient,
                  caption: caption,
                  captionFont: captionFont,
                  backgroundOpacity: backgroundOpacity,
                  gradientAngle: gradientAngle,
                  radialGradient: radialGradient,
                  eyeStyle: eyeStyle,
                  eyeColor: eyeColor,
                  cornerRadius: cornerRadius,
                  quietZone: quietZone,
                  logoSize: logoSize,
                  logoPadding: logoPadding,
                  logoMask: logoMask,
                  logoBackground: logoBackground,
                  logoBorder: logoBorder,
                  frameColor: frameColor,
                  frameThickness: frameThickness,
                  frameShadow: frameShadow,
                  shadowOpacity: shadowOpacity,
                  captionAbove: captionAbove,
                  captionAlign: captionAlign,
                  captionColor: captionColor,
                  correction: correction,
                  exportSize: exportSize,
                  exportFormat: exportFormat,
                  transparentExport: transparentExport,
                  backgroundTexture: backgroundTexture,
                  onApply: (design) => setState(() {
                    fg = design.foreground;
                    bg = design.background;
                    module = design.module;
                    frame = design.frame;
                    logoEnabled = design.logoEnabled;
                    logoPath = design.logoPath;
                    logoPlacement = design.logoPlacement;
                    gradient = design.gradient;
                    caption = design.caption;
                    captionFont = design.captionFont;
                    backgroundOpacity = design.backgroundOpacity;
                    gradientAngle = design.gradientAngle;
                    radialGradient = design.radialGradient;
                    eyeStyle = design.eyeStyle;
                    eyeColor = design.eyeColor;
                    cornerRadius = design.cornerRadius;
                    quietZone = design.quietZone;
                    logoSize = design.logoSize;
                    logoPadding = design.logoPadding;
                    logoMask = design.logoMask;
                    logoBackground = design.logoBackground;
                    logoBorder = design.logoBorder;
                    frameColor = design.frameColor;
                    frameThickness = design.frameThickness;
                    frameShadow = design.frameShadow;
                    shadowOpacity = design.shadowOpacity;
                    captionAbove = design.captionAbove;
                    captionAlign = design.captionAlign;
                    captionColor = design.captionColor;
                    correction = design.correction;
                    exportSize = design.exportSize;
                    exportFormat = design.exportFormat;
                    transparentExport = design.transparentExport;
                    backgroundTexture = design.backgroundTexture;
                  }),
                )));
              },
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(widget.existing == null ? context.qrL10n.t('editor.saveLibrary') : context.qrL10n.t('editor.saveChanges')))),
          if (widget.existing != null) TextButton.icon(onPressed: () => _save(asNew: true), icon: const Icon(Icons.copy_outlined), label: Text(context.qrL10n.t('editor.saveNew'))),
        ],
      ),
    );
  }
   IconData _fieldIcon(String s) => s.toLowerCase().contains('tel') || s.toLowerCase().contains('número') ? Icons.phone_outlined : s.toLowerCase().contains('email') || s.toLowerCase().contains('destinatario') ? Icons.email_outlined : s.toLowerCase().contains('url') || s.toLowerCase().contains('web') ? Icons.link : Icons.edit_outlined;
  void _showFieldHelp() {
    String h(String key) => context.qrL10n.t('help.$key');
    final guidance = switch (type) {
      QrType.url => {'URL': h('URL')},
       QrType.contact => {'Nombre': h('Nombre'), 'Teléfono': h('Teléfono'), 'Email': h('Email'), 'Empresa': h('Empresa')},
       QrType.wifi => {'SSID': h('SSID'), 'Contraseña': h('Contraseña')},
       QrType.whatsapp => {'Número': h('Número'), 'Mensaje': h('Mensaje')},
      QrType.email => {'Destinatario': h('Destinatario'), 'Asunto': h('Asunto'), 'Mensaje': h('Mensaje')},
       QrType.phone => {'Número': h('Número')},
       QrType.sms => {'Número': h('Número'), 'Mensaje': h('Mensaje')},
      QrType.location => {'Latitud': h('Latitud'), 'Longitud': h('Longitud'), 'Etiqueta': h('Etiqueta')},
       QrType.event || QrType.calendar => {'Título': h('Título'), 'Inicio': h('Inicio'), 'Fin': h('Fin'), 'Lugar': h('Lugar'), 'Descripción': h('Descripción')},
      QrType.social => {'Instagram': h('Instagram'), 'Facebook': h('Facebook'), 'LinkedIn': h('LinkedIn')},
       QrType.business => {'Negocio': h('Negocio'), 'Teléfono': h('Teléfono'), 'Dirección': h('Dirección'), 'Web': h('Web')},
       QrType.crypto => {'Moneda': h('Moneda'), 'Dirección': h('Dirección'), 'Importe': h('Importe')},
      QrType.appStore => {'Enlace App Store': h('Enlace App Store'), 'Enlace Play Store': h('Enlace Play Store')},
      QrType.text => {'Contenido': h('Contenido')},
    };
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: QrFriColors.indigo.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.help_outline, color: QrFriColors.indigo, size: 21)),
          const SizedBox(width: 10),
          Expanded(child: Text('${context.qrL10n.t('help.fields.title')} ${context.qrL10n.typeLabel(type)}')),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.qrL10n.t('help.fields.intro')),
              const SizedBox(height: 14),
              for (final entry in guidance.entries) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check_circle_outline, color: QrFriColors.emerald, size: 19),
                  const SizedBox(width: 8),
                  Expanded(child: RichText(text: TextSpan(style: Theme.of(dialogContext).textTheme.bodyMedium, children: [TextSpan(text: '${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.w800)), TextSpan(text: entry.value)]))),
                ]),
              ),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.qrL10n.t('common.done')))],
      ),
    );
  }
  Future<void> _save({bool asNew = false}) async {
    if (payload.trim().isEmpty) {
      showQrToast(context, context.qrL10n.t('editor.empty'), kind: QrToastKind.error);
      return;
    }
    final item = QrItem(id: asNew || widget.existing == null ? const Uuid().v4() : widget.existing!.id, name: name.text.trim().isEmpty ? context.qrL10n.typeLabel(type) : name.text.trim(), type: type, content: payload, foreground: fg, background: bg, module: module, caption: '', frame: frame, logoEnabled: logoEnabled, captionFont: captionFont, logoPlacement: logoPlacement, gradient: gradient, logoPath: logoPath, backgroundOpacity: backgroundOpacity, gradientAngle: gradientAngle, radialGradient: radialGradient, eyeStyle: eyeStyle, eyeColor: eyeColor, cornerRadius: cornerRadius, quietZone: quietZone, logoSize: logoSize, logoPadding: logoPadding, logoMask: logoMask, logoBackground: logoBackground, logoBorder: logoBorder, frameColor: frameColor, frameThickness: frameThickness, frameShadow: frameShadow, shadowOpacity: shadowOpacity, captionAbove: '', captionAlign: captionAlign, captionColor: captionColor, correction: correction, exportSize: exportSize, exportFormat: exportFormat, transparentExport: transparentExport, backgroundTexture: backgroundTexture, favorite: widget.existing?.favorite ?? false, tags: widget.existing?.tags ?? const [], folder: widget.existing?.folder ?? '');
    try {
      if (widget.existing != null && !asNew) {
        await widget.store.replace(item);
      } else {
        await widget.store.add(item);
      }
      if (!mounted) return;
      showQrToast(context, widget.existing != null && !asNew ? context.qrL10n.t('editor.updated') : context.qrL10n.t('editor.saved'), kind: QrToastKind.success);
      Navigator.pop(context);
    } catch (_) {
      if (mounted) showQrToast(context, context.qrL10n.t('editor.saveError'), kind: QrToastKind.error);
    }
  }
}

class DesignValues {
  const DesignValues({this.name = 'Mi plantilla', required this.foreground, required this.background, required this.module, required this.frame, required this.logoEnabled, required this.logoPath, required this.logoPlacement, required this.gradient, required this.caption, required this.captionFont, this.backgroundOpacity = 1, this.gradientAngle = 45, this.radialGradient = false, this.eyeStyle = 0, this.eyeColor = 0xff172033, this.cornerRadius = .5, this.quietZone = 4, this.logoSize = .2, this.logoPadding = 5, this.logoMask = 1, this.logoBackground = 0xffffffff, this.logoBorder = true, this.frameColor = 0xff3730e0, this.frameThickness = 2, this.frameShadow = false, this.shadowOpacity = .12, this.captionAbove = '', this.captionAlign = 1, this.captionColor = 0xff0f172a, this.correction = 1, this.exportSize = 1024, this.exportFormat = 'PNG', this.transparentExport = false, this.backgroundTexture = false});
  final String name;
  final int foreground, background, module, frame, logoPlacement, captionFont;
  final bool logoEnabled, gradient;
  final String caption;
  final String? logoPath;
  final double backgroundOpacity, gradientAngle, cornerRadius, quietZone, logoSize, logoPadding, frameThickness, shadowOpacity;
  final bool radialGradient, logoBorder, frameShadow, transparentExport, backgroundTexture;
  final int eyeStyle, eyeColor, logoMask, logoBackground, frameColor, captionAlign, captionColor, correction, exportSize;
  final String captionAbove, exportFormat;
  Map<String, dynamic> toJson() => {'name': name, 'foreground': foreground, 'background': background, 'module': module, 'frame': frame, 'logoEnabled': logoEnabled, 'logoPath': logoPath, 'logoPlacement': logoPlacement, 'gradient': gradient, 'caption': caption, 'captionFont': captionFont, 'backgroundOpacity': backgroundOpacity, 'gradientAngle': gradientAngle, 'radialGradient': radialGradient, 'eyeStyle': eyeStyle, 'eyeColor': eyeColor, 'cornerRadius': cornerRadius, 'quietZone': quietZone, 'logoSize': logoSize, 'logoPadding': logoPadding, 'logoMask': logoMask, 'logoBackground': logoBackground, 'logoBorder': logoBorder, 'frameColor': frameColor, 'frameThickness': frameThickness, 'frameShadow': frameShadow, 'shadowOpacity': shadowOpacity, 'captionAbove': captionAbove, 'captionAlign': captionAlign, 'captionColor': captionColor, 'correction': correction, 'exportSize': exportSize, 'exportFormat': exportFormat, 'transparentExport': transparentExport, 'backgroundTexture': backgroundTexture};
  factory DesignValues.fromJson(Map<String, dynamic> j) => DesignValues(name: j['name'] as String? ?? 'Mi plantilla', foreground: j['foreground'] as int? ?? 0xff172033, background: j['background'] as int? ?? 0xffffffff, module: j['module'] as int? ?? 0, frame: j['frame'] as int? ?? 0, logoEnabled: j['logoEnabled'] as bool? ?? false, logoPath: j['logoPath'] as String?, logoPlacement: j['logoPlacement'] as int? ?? 0, gradient: j['gradient'] as bool? ?? false, caption: j['caption'] as String? ?? '', captionFont: j['captionFont'] as int? ?? 0, backgroundOpacity: (j['backgroundOpacity'] as num?)?.toDouble() ?? 1, gradientAngle: (j['gradientAngle'] as num?)?.toDouble() ?? 45, radialGradient: j['radialGradient'] as bool? ?? false, eyeStyle: j['eyeStyle'] as int? ?? 0, eyeColor: j['eyeColor'] as int? ?? 0xff172033, cornerRadius: (j['cornerRadius'] as num?)?.toDouble() ?? .5, quietZone: (j['quietZone'] as num?)?.toDouble() ?? 4, logoSize: (j['logoSize'] as num?)?.toDouble() ?? .2, logoPadding: (j['logoPadding'] as num?)?.toDouble() ?? 5, logoMask: j['logoMask'] as int? ?? 1, logoBackground: j['logoBackground'] as int? ?? 0xffffffff, logoBorder: j['logoBorder'] as bool? ?? true, frameColor: j['frameColor'] as int? ?? 0xff3730e0, frameThickness: (j['frameThickness'] as num?)?.toDouble() ?? 2, frameShadow: j['frameShadow'] as bool? ?? false, shadowOpacity: (j['shadowOpacity'] as num?)?.toDouble() ?? .12, captionAbove: j['captionAbove'] as String? ?? '', captionAlign: j['captionAlign'] as int? ?? 1, captionColor: j['captionColor'] as int? ?? 0xff0f172a, correction: j['correction'] as int? ?? 1, exportSize: j['exportSize'] as int? ?? 1024, exportFormat: j['exportFormat'] as String? ?? 'PNG', transparentExport: j['transparentExport'] as bool? ?? false, backgroundTexture: j['backgroundTexture'] as bool? ?? false);
}

Alignment _gradientAlignment(double degrees, {bool end = false}) {
  final radians = degrees * math.pi / 180;
  final x = math.cos(radians).clamp(-1.0, 1.0).toDouble();
  final y = math.sin(radians).clamp(-1.0, 1.0).toDouble();
  return Alignment((end ? x : -x), (end ? y : -y));
}

int _qrErrorCorrection(int index) => const [QrErrorCorrectLevel.L, QrErrorCorrectLevel.M, QrErrorCorrectLevel.Q, QrErrorCorrectLevel.H][index.clamp(0, 3).toInt()];

Color _logoBackdrop(int configured, String? path) {
  // Imported images with alpha need a light backing so transparent pixels do not
  // expose dark QR modules or a black canvas.
  if (configured == 0 && path != null) return Colors.white;
  return configured == 0 ? Colors.transparent : Color(configured);
}

class ComprehensiveDesignPage extends StatefulWidget {
  const ComprehensiveDesignPage({super.key, required this.data, required this.store, required this.foreground, required this.background, required this.module, required this.frame, required this.logoEnabled, required this.logoPath, required this.logoPlacement, required this.gradient, required this.caption, required this.captionFont, this.backgroundOpacity = 1, this.gradientAngle = 45, this.radialGradient = false, this.eyeStyle = 0, this.eyeColor = 0xff172033, this.cornerRadius = .5, this.quietZone = 4, this.logoSize = .2, this.logoPadding = 5, this.logoMask = 1, this.logoBackground = 0xffffffff, this.logoBorder = true, this.frameColor = 0xff3730e0, this.frameThickness = 2, this.frameShadow = false, this.shadowOpacity = .12, this.captionAbove = '', this.captionAlign = 1, this.captionColor = 0xff0f172a, this.correction = 1, this.exportSize = 1024, this.exportFormat = 'PNG', this.transparentExport = false, this.backgroundTexture = false, required this.onApply});
  final String data, caption;
  final LocalStore store;
  final int foreground, background, module, frame, logoPlacement, captionFont;
  final bool logoEnabled, gradient;
  final String? logoPath;
  final double backgroundOpacity, gradientAngle, cornerRadius, quietZone, logoSize, logoPadding, frameThickness, shadowOpacity;
  final bool radialGradient, logoBorder, frameShadow, transparentExport, backgroundTexture;
  final int eyeStyle, eyeColor, logoMask, logoBackground, frameColor, captionAlign, captionColor, correction, exportSize;
  final String captionAbove, exportFormat;
  final ValueChanged<DesignValues> onApply;

  @override
  State<ComprehensiveDesignPage> createState() => _ComprehensiveDesignPageState();
}

class _ComprehensiveDesignPageState extends State<ComprehensiveDesignPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late int foreground, background, module, frame, logoPlacement, captionFont;
  late bool logoEnabled, gradient;
  String? logoPath;
  late final TextEditingController caption;
  int eyeStyle = 0;
  int eyeColor = 0xff172033;
  int logoMask = 1;
  int logoBackground = 0xffffffff;
  int frameColor = 0xff3730e0;
  int captionColor = 0xff0f172a;
  double backgroundOpacity = 1;
  double gradientAngle = 45;
  double cornerRadius = .5;
  double quietZone = 4;
  double logoSize = .2;
  double logoPadding = 5;
  double frameThickness = 2;
  double shadowOpacity = .12;
  bool radialGradient = false, logoBorder = true, frameShadow = false, backgroundTexture = false, transparentExport = false;
  String captionAbove = '';
  int captionAlign = 1;
  int correction = 1;
  int exportSize = 1024;
  String exportFormat = 'PNG';
  double density = .6;
  List<DesignValues> savedTemplates = [];
  int _previewRevision = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    foreground = widget.foreground;
    background = widget.background;
    module = widget.module;
    frame = widget.frame;
    logoEnabled = widget.logoEnabled;
    logoPath = widget.logoPath;
    logoPlacement = widget.logoPlacement;
    gradient = widget.gradient;
    captionFont = widget.captionFont;
    caption = TextEditingController(text: widget.caption);
    backgroundOpacity = widget.backgroundOpacity;
    gradientAngle = widget.gradientAngle;
    radialGradient = widget.radialGradient;
    eyeStyle = widget.eyeStyle;
    eyeColor = widget.eyeColor;
    cornerRadius = widget.cornerRadius;
    quietZone = widget.quietZone;
    logoSize = widget.logoSize;
    logoPadding = widget.logoPadding;
    logoMask = widget.logoMask;
    logoBackground = widget.logoBackground;
    logoBorder = widget.logoBorder;
    frameColor = widget.frameColor;
    frameThickness = widget.frameThickness;
    frameShadow = widget.frameShadow;
    shadowOpacity = widget.shadowOpacity;
    captionAbove = widget.captionAbove;
    captionAlign = widget.captionAlign;
    captionColor = widget.captionColor;
    correction = widget.correction;
    exportSize = widget.exportSize;
    exportFormat = widget.exportFormat;
    transparentExport = widget.transparentExport;
    backgroundTexture = widget.backgroundTexture;
    density = ((18 - quietZone) / 16).clamp(.3, .8).toDouble();
    savedTemplates = widget.store.loadTemplates();
  }

  @override
  void dispose() { _tabs.dispose(); caption.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.qrL10n.t('design.title')), actions: [IconButton(tooltip: context.qrL10n.t('common.reset'), onPressed: _reset, icon: const Icon(Icons.restart_alt))]),
    body: Column(children: [
      SizedBox(height: 320, child: _previewCard(context)),
      Material(color: Theme.of(context).scaffoldBackgroundColor, child: TabBar(controller: _tabs, isScrollable: true, labelColor: QrFriColors.indigo, unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant, indicatorColor: QrFriColors.indigo, tabs: [Tab(text: context.qrL10n.t('design.colorsStyle')), Tab(text: context.qrL10n.t('design.logo')), Tab(text: context.qrL10n.t('design.templates'))])),
      Expanded(child: TabBarView(controller: _tabs, children: [_colorsStyleTab(), _logoTab(), _templatesTab()])),
    ]),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt), label: Text(context.qrL10n.t('common.reset')))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: _apply, icon: const Icon(Icons.check), label: Text(context.qrL10n.t('common.save')))),
          ],
        ),
      ),
    ),
  );

  Widget _previewCard(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(children: [
        Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: _qrPreview(size: 210)))),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [OutlinedButton.icon(onPressed: _testScan, icon: const Icon(Icons.center_focus_strong, size: 18), label: Text(context.qrL10n.t('design.readTest')))]),
      ]),
    ),
  );

  Widget _qrPreview({double size = 210}) => Container(
    padding: EdgeInsets.all(quietZone.clamp(2, 16).toDouble()),
    decoration: BoxDecoration(
      color: transparentExport ? Colors.transparent : Color(background).withValues(alpha: backgroundOpacity),
      gradient: gradient ? (radialGradient ? RadialGradient(colors: [Color(background), Color(foreground).withValues(alpha: .14)]) : LinearGradient(colors: [Color(background), Color(foreground).withValues(alpha: .14)], begin: _gradientAlignment(gradientAngle), end: _gradientAlignment(gradientAngle, end: true))) : backgroundTexture ? LinearGradient(colors: [Color(background), Color(foreground).withValues(alpha: .05)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
      borderRadius: BorderRadius.circular(frame == 4 ? 26 : frame == 2 ? 6 : 16),
      border: frame > 0 ? Border.all(color: Color(frameColor), width: frameThickness.clamp(1, 8).toDouble()) : null,
      boxShadow: frameShadow ? [BoxShadow(color: Color(frameColor).withValues(alpha: shadowOpacity), blurRadius: 16, offset: const Offset(0, 6))] : null,
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(alignment: logoPlacement == 1 ? Alignment.topCenter : logoPlacement == 2 ? Alignment.bottomCenter : Alignment.center, children: [
        QrImageView(key: ValueKey('$foreground$background$backgroundOpacity$gradient$radialGradient$module$eyeStyle$eyeColor$correction$quietZone:$_previewRevision'), data: widget.data.isEmpty ? 'QRfri' : widget.data, version: QrVersions.auto, errorCorrectionLevel: _qrErrorCorrection(correction), size: size, padding: EdgeInsets.zero, backgroundColor: (transparentExport || gradient) ? Colors.transparent : Color(background).withValues(alpha: backgroundOpacity), eyeStyle: QrEyeStyle(eyeShape: eyeStyle >= 1 ? QrEyeShape.circle : QrEyeShape.square, color: Color(eyeColor)), dataModuleStyle: QrDataModuleStyle(dataModuleShape: module >= 1 ? QrDataModuleShape.circle : QrDataModuleShape.square, color: Color(foreground))),
        if (logoEnabled) Container(width: size * logoSize.clamp(.12, .28).toDouble(), height: size * logoSize.clamp(.12, .28).toDouble(), padding: EdgeInsets.all(logoPadding.clamp(0, 12).toDouble()), decoration: BoxDecoration(color: _logoBackdrop(logoBackground, logoPath), shape: logoMask == 0 ? BoxShape.circle : BoxShape.rectangle, borderRadius: logoMask == 0 ? null : BorderRadius.circular(logoMask == 3 ? 0 : logoMask == 2 ? 3 : 12), border: logoBorder ? Border.all(color: Color(foreground), width: 1.2) : null), child: logoPath != null ? Image.file(File(logoPath!), key: ValueKey('comprehensive-logo:$logoPath'), fit: BoxFit.contain) : Image.asset('assets/vertical.png', fit: BoxFit.contain)),
      ]),
    ]),
  );


  Widget _scroll(List<Widget> children) => ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: children);
  Widget _card(String title, IconData icon, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: QrFriColors.indigo), const SizedBox(width: 9), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]), const SizedBox(height: 12), ...children])));
  Widget _colorsStyleTab() => _scroll([
    _card(context.qrL10n.t('design.colors'), Icons.palette_outlined, [
      _ColorRow(label: context.qrL10n.t('design.colorModules'), selected: foreground, colors: const [0xff0f172a, 0xff3730e0, 0xff0fae6b, 0xff7c3aed, 0xffc2415d], onSelect: (v) => setState(() => foreground = v)),
      _HexColorField(value: foreground, onChanged: (v) => setState(() => foreground = v)),
      _ColorRow(label: context.qrL10n.t('design.colorEyes'), selected: eyeColor, colors: const [0xff172033, 0xff3730e0, 0xff0fae6b, 0xff7c3aed], onSelect: _setEyeColor),
      _HexColorField(value: eyeColor, onChanged: _setEyeColor),
      _ColorRow(label: context.qrL10n.t('design.colorBackground'), selected: background, colors: const [0xffffffff, 0xfff8fafc, 0xffeef2ff, 0xffecfdf5, 0xff0f172a], onSelect: (v) => setState(() => background = v)),
      _HexColorField(value: background, onChanged: (v) => setState(() => background = v)),
    ]),
    _card(context.qrL10n.t('design.forms'), Icons.grid_4x4, [
      _ChoiceGroup(label: context.qrL10n.t('design.moduleShape'), values: [context.qrL10n.t('design.square'), context.qrL10n.t('design.circle')], selected: module.clamp(0, 1).toInt(), onChanged: (v) => setState(() => module = v)),
      _ChoiceGroup(label: context.qrL10n.t('design.eyeShape'), values: [context.qrL10n.t('design.square'), context.qrL10n.t('design.circle')], selected: eyeStyle.clamp(0, 1).toInt(), onChanged: (v) => setState(() => eyeStyle = v)),
    ]),
    _card(context.qrL10n.t('design.gradientSection'), Icons.gradient, [
      SwitchListTile(contentPadding: EdgeInsets.zero, value: gradient, onChanged: (v) => setState(() => gradient = v), title: Text(context.qrL10n.t('design.gradient')), subtitle: Text(context.qrL10n.t('design.gradient.subtitle'))),
      if (gradient) ...[SwitchListTile(contentPadding: EdgeInsets.zero, value: radialGradient, onChanged: (v) => setState(() => radialGradient = v), title: Text(context.qrL10n.t('design.radial'))), _slider(context.qrL10n.t('design.gradientAngle'), gradientAngle, 0, 360, (v) => setState(() => gradientAngle = v))],
      _slider(context.qrL10n.t('design.backgroundOpacity'), backgroundOpacity, .1, 1, (v) => setState(() => backgroundOpacity = v)),
      _contrastIndicator(),
    ]),
  ]);
  void _setEyeColor(int value) => setState(() { eyeColor = value; _previewRevision++; });
  Widget _colorsTab() => _scroll([_card(context.qrL10n.t('design.colors'), Icons.palette_outlined, [_ColorRow(label: context.qrL10n.t('design.modules'), selected: foreground, colors: const [0xff0f172a, 0xff3730e0, 0xff0fae6b, 0xff7c3aed, 0xffc2415d], onSelect: (v) => setState(() => foreground = v)), _HexColorField(value: foreground, onChanged: (v) => setState(() => foreground = v)), _ColorRow(label: context.qrL10n.t('design.colorBackground'), selected: background, colors: const [0xffffffff, 0xfff8fafc, 0xffeef2ff, 0xffecfdf5, 0xff0f172a], onSelect: (v) => setState(() => background = v)), _HexColorField(value: background, onChanged: (v) => setState(() => background = v)), SwitchListTile(contentPadding: EdgeInsets.zero, value: gradient, onChanged: (v) => setState(() => gradient = v), title: Text(context.qrL10n.t('design.gradientModules')), subtitle: Text(context.qrL10n.t('design.gradientDescription')), secondary: const Icon(Icons.gradient)), if (gradient) ...[SwitchListTile(contentPadding: EdgeInsets.zero, value: radialGradient, onChanged: (v) => setState(() => radialGradient = v), title: Text(context.qrL10n.t('design.radial'))), _slider(context.qrL10n.t('design.gradientAngle'), gradientAngle, 0, 360, (v) => setState(() => gradientAngle = v))], _slider(context.qrL10n.t('design.backgroundOpacity'), backgroundOpacity, .1, 1, (v) => setState(() => backgroundOpacity = v)), _contrastIndicator()])]);
   Widget _contrastIndicator() { final score = _contrastScore(); final good = score >= 4.5; return ListTile(contentPadding: EdgeInsets.zero, leading: Icon(good ? Icons.check_circle : Icons.warning_amber_rounded, color: good ? QrFriColors.emerald : QrFriColors.warning), title: Text(good ? context.qrL10n.t('design.contrastGood') : context.qrL10n.t('design.contrastLow')), subtitle: Text('${context.qrL10n.t('design.contrastScore')} ${score.toStringAsFixed(1)}:1 · ${good ? context.qrL10n.t('design.goodReading') : context.qrL10n.t('design.useContrast')}')); }
  double _contrastScore() { final a = Color(foreground), b = Color(background); double lum(Color c) { final r = c.red / 255, g = c.green / 255, bl = c.blue / 255; double f(double x) => x <= .03928 ? x / 12.92 : ((x + .055) / 1.055).clamp(0, 1).toDouble(); return .2126 * f(r) + .7152 * f(g) + .0722 * f(bl); } final l1 = lum(a), l2 = lum(b); return (l1 > l2 ? (l1 + .05) / (l2 + .05) : (l2 + .05) / (l1 + .05)); }
  Widget _styleTab() => _scroll([
      _card(context.qrL10n.t('design.modules'), Icons.grid_4x4, [
      Text(context.qrL10n.t('design.engineForms'), style: const TextStyle(color: Colors.grey)),
      _ChoiceGroup(label: context.qrL10n.t('design.form'), values: [context.qrL10n.t('design.classic'), context.qrL10n.t('design.moduleOrganic')], selected: module.clamp(0, 1).toInt(), onChanged: (v) => setState(() => module = v)),
    ]),
    _card(context.qrL10n.t('design.eyes'), Icons.crop_square, [
      Text(context.qrL10n.t('design.engineEyes'), style: const TextStyle(color: Colors.grey)),
      _ChoiceGroup(label: context.qrL10n.t('design.form'), values: [context.qrL10n.t('design.square'), context.qrL10n.t('design.circle')], selected: eyeStyle.clamp(0, 1).toInt(), onChanged: (v) => setState(() => eyeStyle = v)),
      _ColorRow(label: context.qrL10n.t('design.independentColor'), selected: eyeColor, colors: const [0xff3730e0, 0xff0fae6b, 0xff0f172a, 0xff7c3aed], onSelect: (v) => setState(() => eyeColor = v)),
      _HexColorField(value: eyeColor, onChanged: (v) => setState(() => eyeColor = v)),
    ]),
  ]);
  Widget _logoTab() => _scroll([_card(context.qrL10n.t('design.logo'), Icons.image_outlined, [SwitchListTile(contentPadding: EdgeInsets.zero, value: logoEnabled, onChanged: (v) => setState(() => logoEnabled = v), title: Text(context.qrL10n.t('design.logoSafe')), subtitle: Text(context.qrL10n.t('design.logoSafe.subtitle'))), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.photo_library_outlined), label: Text(logoPath == null ? context.qrL10n.t('design.chooseImage') : context.qrL10n.t('design.changeImage')))), if (logoPath != null) IconButton(tooltip: context.qrL10n.t('design.logoDefault'), onPressed: () => setState(() => logoPath = null), icon: const Icon(Icons.restart_alt))]), _ChoiceGroup(label: context.qrL10n.t('design.mask'), values: [context.qrL10n.t('design.circle'), context.qrL10n.t('design.rounded'), context.qrL10n.t('design.square'), context.qrL10n.t('design.none')], selected: logoMask, onChanged: (v) => setState(() => logoMask = v)), _slider(context.qrL10n.t('design.safeSize'), logoSize, .12, .28, (v) => setState(() => logoSize = v)), _slider(context.qrL10n.t('design.logoPadding'), logoPadding, 0, 12, (v) => setState(() => logoPadding = v)), _ChoiceGroup(label: context.qrL10n.t('design.logoBackground'), values: [context.qrL10n.t('design.white'), context.qrL10n.t('design.transparent'), context.qrL10n.t('design.indigo')], selected: logoBackground == 0xffffffff ? 0 : logoBackground == 0 ? 1 : 2, onChanged: (v) => setState(() => logoBackground = v == 0 ? 0xffffffff : v == 1 ? 0 : foreground)), _HexColorField(value: logoBackground, onChanged: (v) => setState(() => logoBackground = v)), SwitchListTile(contentPadding: EdgeInsets.zero, value: logoBorder, onChanged: (v) => setState(() => logoBorder = v), title: Text(context.qrL10n.t('design.subtleBorder')))])]);
  Widget _templatesTab() => _scroll([
    if (savedTemplates.isNotEmpty)
      _card(context.qrL10n.t('design.templates'), Icons.bookmarks_outlined, [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < savedTemplates.length; i++)
              InputChip(
                avatar: CircleAvatar(backgroundColor: Color(savedTemplates[i].foreground), radius: 9),
                label: Text(savedTemplates[i].name),
                onPressed: () => _applyDesign(savedTemplates[i]),
                onDeleted: () => _deleteTemplate(i),
                deleteButtonTooltipMessage: context.qrL10n.t('design.removeTemplate'),
              ),
          ],
        ),
      ]),
    _card(context.qrL10n.t('design.saveCurrent'), Icons.bookmark_add_outlined, [
      FilledButton.icon(onPressed: _saveTemplate, icon: const Icon(Icons.bookmark_add_outlined), label: Text(context.qrL10n.t('templates.save'))),
    ]),
  ]);

  DesignValues _currentDesign({String name = 'Mi plantilla'}) => DesignValues(name: name, foreground: foreground, background: background, module: module, frame: frame, logoEnabled: logoEnabled, logoPath: logoPath, logoPlacement: logoPlacement, gradient: gradient, caption: caption.text, captionFont: captionFont, backgroundOpacity: backgroundOpacity, gradientAngle: gradientAngle, radialGradient: radialGradient, eyeStyle: eyeStyle, eyeColor: eyeColor, cornerRadius: cornerRadius, quietZone: quietZone, logoSize: logoSize, logoPadding: logoPadding, logoMask: logoMask, logoBackground: logoBackground, logoBorder: logoBorder, frameColor: frameColor, frameThickness: frameThickness, frameShadow: frameShadow, shadowOpacity: shadowOpacity, captionAbove: captionAbove, captionAlign: captionAlign, captionColor: captionColor, correction: correction, exportSize: exportSize, exportFormat: exportFormat, transparentExport: transparentExport, backgroundTexture: backgroundTexture);

  void _applyDesign(DesignValues value) => setState(() { foreground = value.foreground; background = value.background; module = value.module.clamp(0, 1).toInt(); frame = value.frame; logoEnabled = value.logoEnabled; logoPath = value.logoPath; logoPlacement = value.logoPlacement; gradient = value.gradient; caption.value = TextEditingValue(text: value.caption); captionFont = value.captionFont; backgroundOpacity = value.backgroundOpacity; gradientAngle = value.gradientAngle; radialGradient = value.radialGradient; eyeStyle = value.eyeStyle.clamp(0, 1).toInt(); eyeColor = value.eyeColor; cornerRadius = value.cornerRadius; quietZone = value.quietZone; density = ((18 - quietZone) / 16).clamp(.3, .8).toDouble(); logoSize = value.logoSize; logoPadding = value.logoPadding; logoMask = value.logoMask; logoBackground = value.logoBackground; logoBorder = value.logoBorder; frameColor = value.frameColor; frameThickness = value.frameThickness; frameShadow = value.frameShadow; shadowOpacity = value.shadowOpacity; captionAbove = value.captionAbove; captionAlign = value.captionAlign; captionColor = value.captionColor; correction = value.correction; exportSize = value.exportSize; exportFormat = value.exportFormat; transparentExport = value.transparentExport; backgroundTexture = value.backgroundTexture; });

  Future<void> _saveTemplate() async {
    final controller = TextEditingController(text: 'Mi plantilla ${savedTemplates.length + 1}');
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(context.qrL10n.t('templates.saveDialog')), content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: context.qrL10n.t('templates.name'))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.qrL10n.t('common.cancel'))), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(context.qrL10n.t('common.save')))]));
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (name == null || name.isEmpty) return;
    try {
      await widget.store.saveTemplate(_currentDesign(name: name));
      if (!mounted) return;
      setState(() => savedTemplates = widget.store.loadTemplates());
      showQrToast(context, context.qrL10n.t('templates.saved'), kind: QrToastKind.success);
    } catch (_) {
      if (mounted) showQrToast(context, context.qrL10n.t('templates.saveError'), kind: QrToastKind.error);
    }
  }
  Future<void> _deleteTemplate(int index) async {
    if (index < 0 || index >= savedTemplates.length) return;
    final templateName = savedTemplates[index].name;
    final confirmed = await showQrConfirmation(context, title: context.qrL10n.t('templates.deleteTitle'), description: context.qrL10n.t('templates.deleteDescription').replaceAll('{name}', templateName), confirmLabel: context.qrL10n.t('templates.delete'), destructive: true, icon: Icons.delete_outline);
    if (confirmed != true || !mounted) return;
    try {
      await widget.store.removeTemplateAt(index);
      if (!mounted) return;
      setState(() => savedTemplates = widget.store.loadTemplates());
      showQrToast(context, context.qrL10n.t('templates.deleted'), kind: QrToastKind.success);
    } catch (_) {
      if (mounted) showQrToast(context, context.qrL10n.t('templates.deleteError'), kind: QrToastKind.error);
    }
  }
  Widget _template(String name, int fg, int bg) => ActionChip(avatar: CircleAvatar(backgroundColor: Color(fg), radius: 9), label: Text(name), onPressed: () => setState(() { foreground = fg; background = bg; gradient = false; }));
  Widget _advancedTab() => _scroll([
    _card(context.qrL10n.t('design.correctionExport'), Icons.tune, [
       _ChoiceGroup(label: context.qrL10n.t('design.errorCorrection'), values: const ['L · Básica', 'M · Equilibrada', 'Q · Alta', 'H · Máxima'], selected: correction, onChanged: (v) => setState(() => correction = v)),
      Text(logoEnabled ? context.qrL10n.t('design.recommendedLogo') : context.qrL10n.t('design.correctionHint'), style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 10),
      _ChoiceGroup(label: context.qrL10n.t('design.quality'), values: const ['512 px', '1024 px', '2048 px', '4096 px'], selected: [512, 1024, 2048, 4096].indexOf(exportSize), onChanged: (v) => setState(() => exportSize = [512, 1024, 2048, 4096][v])),
      _ChoiceGroup(label: context.qrL10n.t('design.format'), values: const ['PNG', 'JPG', 'PDF'], selected: ['PNG', 'JPG', 'PDF'].contains(exportFormat) ? ['PNG', 'JPG', 'PDF'].indexOf(exportFormat) : 0, onChanged: (v) => setState(() => exportFormat = ['PNG', 'JPG', 'PDF'][v])),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: transparentExport, onChanged: (v) => setState(() => transparentExport = v), title: Text(context.qrL10n.t('design.transparentExport')), subtitle: Text(context.qrL10n.t('design.transparent.subtitle'))),
    ]),
    _card(context.qrL10n.t('design.decorativeBackground'), Icons.texture, [
      SwitchListTile(contentPadding: EdgeInsets.zero, value: backgroundTexture, onChanged: (v) => setState(() => backgroundTexture = v), title: Text(context.qrL10n.t('design.texture')), subtitle: Text(context.qrL10n.t('design.textureDescription'))),
    ]),
  ]);
   Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$label · ${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}'), Slider(value: value, min: min, max: max, activeColor: QrFriColors.indigo, onChanged: onChanged)]);
  Future<void> _pickLogo() async { try { final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false); final path = picked?.files.single.path; if (path == null || !mounted) return; await FileImage(File(path)).evict(); setState(() { logoPath = path; logoEnabled = true; }); showQrToast(context, context.qrL10n.t('feedback.logoUpdated'), kind: QrToastKind.success); } catch (_) { if (mounted) showQrToast(context, context.qrL10n.t('feedback.logoError'), kind: QrToastKind.error); } }
  void _testScan() => showDialog(
    context: context,
    builder: (_) => _QrReadTestDialog(preview: _qrPreview(size: 180), contrast: _contrastScore()),
  );
  void _reset() => setState(() { foreground = widget.foreground; background = widget.background; module = widget.module.clamp(0, 1).toInt(); frame = widget.frame; logoEnabled = widget.logoEnabled; logoPath = widget.logoPath; logoPlacement = widget.logoPlacement; gradient = widget.gradient; caption.text = widget.caption; backgroundOpacity = widget.backgroundOpacity; gradientAngle = widget.gradientAngle; radialGradient = widget.radialGradient; eyeStyle = widget.eyeStyle.clamp(0, 1).toInt(); eyeColor = widget.eyeColor; cornerRadius = widget.cornerRadius; quietZone = widget.quietZone; density = ((18 - quietZone) / 16).clamp(.3, .8).toDouble(); logoSize = widget.logoSize; logoPadding = widget.logoPadding; logoMask = widget.logoMask; logoBackground = widget.logoBackground; logoBorder = widget.logoBorder; frameColor = widget.frameColor; frameThickness = widget.frameThickness; frameShadow = widget.frameShadow; shadowOpacity = widget.shadowOpacity; captionAbove = widget.captionAbove; captionAlign = widget.captionAlign; captionColor = widget.captionColor; correction = widget.correction; exportSize = widget.exportSize; exportFormat = widget.exportFormat; transparentExport = widget.transparentExport; backgroundTexture = widget.backgroundTexture; });
  void _apply() { widget.onApply(DesignValues(foreground: foreground, background: background, module: module, frame: frame, logoEnabled: logoEnabled, logoPath: logoPath, logoPlacement: logoPlacement, gradient: gradient, caption: caption.text, captionFont: captionFont, backgroundOpacity: backgroundOpacity, gradientAngle: gradientAngle, radialGradient: radialGradient, eyeStyle: eyeStyle, eyeColor: eyeColor, cornerRadius: cornerRadius, quietZone: quietZone, logoSize: logoSize, logoPadding: logoPadding, logoMask: logoMask, logoBackground: logoBackground, logoBorder: logoBorder, frameColor: frameColor, frameThickness: frameThickness, frameShadow: frameShadow, shadowOpacity: shadowOpacity, captionAbove: captionAbove, captionAlign: captionAlign, captionColor: captionColor, correction: correction, exportSize: exportSize, exportFormat: exportFormat, transparentExport: transparentExport, backgroundTexture: backgroundTexture)); Navigator.pop(context); }
}

class _QrReadTestDialog extends StatefulWidget {
  const _QrReadTestDialog({required this.preview, required this.contrast});

  final Widget preview;
  final double contrast;

  @override
  State<_QrReadTestDialog> createState() => _QrReadTestDialogState();
}

class _QrReadTestDialogState extends State<_QrReadTestDialog> {
  final previewKey = GlobalKey();
  bool reading = false;
  String? detected;
  String? error;
  bool usingAction = false;

  Future<void> _readPreview() async {
    if (reading) return;
    setState(() {
      reading = true;
      error = null;
      detected = null;
    });
    File? temporaryFile;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('preview_not_ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('preview_capture_failed');
      final directory = await getTemporaryDirectory();
      temporaryFile = File('${directory.path}/qrfri-read-test-${DateTime.now().microsecondsSinceEpoch}.png');
      await temporaryFile.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      final analyzer = MobileScannerController(autoStart: false);
      final capture = await analyzer.analyzeImage(temporaryFile.path);
      await analyzer.dispose();
      final value = capture?.barcodes.firstOrNull?.rawValue?.trim();
      if (!mounted) return;
      setState(() {
        reading = false;
        detected = value;
         error = value == null || value.isEmpty ? context.qrL10n.t('reader.error.read') : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        reading = false;
        error = context.qrL10n.t('scanner.analyzeError');
      });
    } finally {
      if (temporaryFile != null) {
        try { await temporaryFile.delete(); } catch (_) {}
      }
    }
  }

  Future<void> _useDetected() async {
    final value = detected;
    if (value == null || value.isEmpty || usingAction) return;
    final action = qrReadActionFor(value);
    setState(() => usingAction = true);
    try {
      switch (action.kind) {
        case QrReadActionKind.open:
          final uri = action.uri;
          if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) throw StateError('launch_failed');
          if (mounted) showQrToast(context, context.qrL10n.t('feedback.contentReady').replaceAll('{action}', localizedReadActionLabel(context, value)), kind: QrToastKind.success);
          break;
        case QrReadActionKind.copy:
          await Clipboard.setData(ClipboardData(text: value));
          if (mounted) showQrToast(context, context.qrL10n.t('feedback.copied'), kind: QrToastKind.success);
          break;
        case QrReadActionKind.shareFile:
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/qrfri-${DateTime.now().microsecondsSinceEpoch}.${action.extension ?? 'txt'}');
          await file.writeAsString(value);
          try {
            final shareResult = await Share.shareXFiles([XFile(file.path)], subject: detectQrType(value) == QrType.contact ? 'Contacto QRfri' : 'Evento QRfri');
            if (mounted && shareResult.status == ShareResultStatus.success) showQrToast(context, context.qrL10n.t('feedback.shareAction').replaceAll('{action}', localizedReadActionLabel(context, value)), kind: QrToastKind.success);
            if (mounted && shareResult.status == ShareResultStatus.dismissed) showQrToast(context, context.qrL10n.t('feedback.shareCancelled'), kind: QrToastKind.info);
            if (mounted && shareResult.status == ShareResultStatus.unavailable) showQrToast(context, context.qrL10n.t('feedback.shareMenu'), kind: QrToastKind.info);
          } finally {
            try { await file.delete(); } catch (_) {}
          }
          break;
      }
    } catch (_) {
      if (mounted) {
         setState(() => error = context.qrL10n.t('reader.error.action'));
        showQrToast(context, context.qrL10n.t('feedback.openError'), kind: QrToastKind.error);
      }
    } finally {
      if (mounted) setState(() => usingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGoodContrast = widget.contrast >= 4.5;
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: QrFriColors.indigo.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.qr_code_scanner, color: QrFriColors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.qrL10n.t('reader.title'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                  IconButton(tooltip: context.qrL10n.t('reader.close'), onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: RepaintBoundary(
                  key: previewKey,
                  child: Container(
                    key: const ValueKey('preview'),
                    width: double.infinity,
                    height: 250,
                    color: Colors.white,
                    child: Center(child: widget.preview),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (detected != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: QrFriColors.emerald.withValues(alpha: .1), borderRadius: BorderRadius.circular(14), border: Border.all(color: QrFriColors.emerald.withValues(alpha: .28))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [const Icon(Icons.check_circle, color: QrFriColors.emerald, size: 19), const SizedBox(width: 7), Text(context.qrL10n.t('reader.success'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: QrFriColors.emerald))]),
                    const SizedBox(height: 7),
                    Text('${context.qrL10n.t('reader.type')}: ${context.qrL10n.typeLabel(detectQrType(detected!))}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    SelectableText(detected!, maxLines: 5),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: usingAction ? null : _useDetected,
                        icon: Icon(usingAction ? Icons.hourglass_top : qrReadActionFor(detected!).icon),
                        label: Text(usingAction ? context.qrL10n.t('reader.opening') : localizedReadActionLabel(context, detected!)),
                      ),
                    ),
                  ]),
                )
              else
                Row(children: [Icon(hasGoodContrast ? Icons.check_circle : Icons.warning_amber_rounded, color: hasGoodContrast ? QrFriColors.emerald : QrFriColors.warning), const SizedBox(width: 8), Expanded(child: Text(hasGoodContrast ? context.qrL10n.t('reader.ready') : context.qrL10n.t('reader.lowContrast')))]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: reading ? null : _readPreview,
                  icon: Icon(reading ? Icons.hourglass_top : detected == null ? Icons.qr_code_scanner : Icons.refresh),
                  label: Text(reading ? context.qrL10n.t('reader.checking') : detected == null ? context.qrL10n.t('reader.check') : context.qrL10n.t('reader.again')),
                ),
              ),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}

class DesignPage extends StatefulWidget {
  const DesignPage({super.key, required this.data, required this.foreground, required this.background, required this.module, required this.frame, required this.logoEnabled, required this.logoPath, required this.logoPlacement, required this.gradient, required this.caption, required this.captionFont, required this.onApply});
  final String data, caption;
  final int foreground, background, module, frame, logoPlacement, captionFont;
  final bool logoEnabled, gradient;
  final String? logoPath;
  final ValueChanged<DesignValues> onApply;
  @override State<DesignPage> createState() => _DesignPageState();
}

class _DesignPageState extends State<DesignPage> {
  late int foreground, background, module, frame, logoPlacement, captionFont;
  int eyeColor = 0xff172033;
  late bool logoEnabled, gradient;
  double cornerRadius = .5;
  String? logoPath;
  late final TextEditingController caption;

  @override
  void initState() {
    super.initState();
    foreground = widget.foreground;
    background = widget.background;
    module = widget.module;
    frame = widget.frame;
    logoEnabled = widget.logoEnabled;
    logoPath = widget.logoPath;
    logoPlacement = widget.logoPlacement;
    gradient = widget.gradient;
    captionFont = widget.captionFont;
    caption = TextEditingController(text: widget.caption);
  }

  @override
  void dispose() { caption.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.qrL10n.t('design.title')), actions: [IconButton(tooltip: context.qrL10n.t('design.apply'), onPressed: _apply, icon: const Icon(Icons.check))]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: FilledButton.icon(onPressed: _apply, icon: const Icon(Icons.check), label: Text(context.qrL10n.t('design.apply'))))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        _designPreview(context),
        const SizedBox(height: 20),
        _section(context.qrL10n.t('design.colors'), Icons.palette_outlined, [_ColorRow(label: context.qrL10n.t('design.colorModules'), selected: foreground, colors: const [0xff0f172a, 0xff3730e0, 0xff0fae6b, 0xff8b3a62, 0xffc47a15], onSelect: (value) => setState(() => foreground = value)), _HexColorField(value: foreground, onChanged: (value) => setState(() => foreground = value)), _ColorRow(label: context.qrL10n.t('design.colorBackground'), selected: background, colors: const [0xffffffff, 0xfff8fafc, 0xffeef2ff, 0xffecfdf5], onSelect: (value) => setState(() => background = value)), _HexColorField(value: background, onChanged: (value) => setState(() => background = value))]),
        const SizedBox(height: 14),
        _section(context.qrL10n.t('design.modules'), Icons.grid_4x4, [_ChoiceGroup(label: context.qrL10n.t('design.moduleShape'), values: [context.qrL10n.t('design.classic'), context.qrL10n.t('design.dots'), context.qrL10n.t('design.soft'), context.qrL10n.t('design.pixel')], selected: module, onChanged: (value) => setState(() => module = value))]),
        const SizedBox(height: 14),
        _section(context.qrL10n.t('design.logo'), Icons.auto_awesome_outlined, [SwitchListTile(contentPadding: EdgeInsets.zero, value: logoEnabled, onChanged: (value) => setState(() => logoEnabled = value), title: Text(context.qrL10n.t('design.logoSafe')), subtitle: Text(context.qrL10n.t('design.logoSafe.subtitle'))), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.photo_library_outlined), label: Text(logoPath == null ? context.qrL10n.t('design.chooseImage') : context.qrL10n.t('design.changeImage')))), if (logoPath != null) IconButton(tooltip: context.qrL10n.t('design.logoDefault'), onPressed: () => setState(() => logoPath = null), icon: const Icon(Icons.restart_alt))]), _ChoiceGroup(label: context.qrL10n.t('design.position'), values: [context.qrL10n.t('design.center'), context.qrL10n.t('design.top'), context.qrL10n.t('design.bottom')], selected: logoPlacement, onChanged: (value) => setState(() => logoPlacement = value))]),
        const SizedBox(height: 14),
        _section(context.qrL10n.t('design.background'), Icons.gradient, [SwitchListTile(contentPadding: EdgeInsets.zero, value: gradient, onChanged: (value) => setState(() => gradient = value), title: Text(context.qrL10n.t('design.gradient')), subtitle: Text(context.qrL10n.t('design.gradient.subtitle')))]),
      ]),
    );
  }

  Widget _designPreview(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Align(alignment: Alignment.centerLeft, child: Text(context.qrL10n.t('design.previewTitle'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))), const SizedBox(height: 14), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Color(background), gradient: gradient ? LinearGradient(colors: [Color(background), Color(foreground).withValues(alpha: .16)]) : null, borderRadius: BorderRadius.circular(18), border: frame > 0 ? Border.all(color: Color(foreground), width: frame == 2 ? 3 : 1.5) : null), child: Stack(alignment: logoPlacement == 1 ? Alignment.topCenter : logoPlacement == 2 ? Alignment.bottomCenter : Alignment.center, children: [QrImageView(data: widget.data.isEmpty ? 'QRfri' : widget.data, size: 220, eyeStyle: QrEyeStyle(eyeShape: module >= 2 ? QrEyeShape.circle : QrEyeShape.square, color: Color(eyeColor)), dataModuleStyle: QrDataModuleStyle(dataModuleShape: module >= 1 && cornerRadius > .25 ? QrDataModuleShape.circle : QrDataModuleShape.square, color: Color(foreground)), backgroundColor: Color(background)), if (logoEnabled) Container(width: 44, height: 44, padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: logoPath != null ? Image.file(File(logoPath!), key: ValueKey('design-logo:$logoPath'), fit: BoxFit.contain) : Image.asset('assets/vertical.png', key: const ValueKey('design-logo-default'), fit: BoxFit.contain))]))])));
  Widget _section(String title, IconData icon, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: QrFriColors.indigo), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]), const SizedBox(height: 10), ...children])));
  Future<void> _pickLogo() async { try { final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false); final path = picked?.files.single.path; if (path == null || !mounted) return; await FileImage(File(path)).evict(); setState(() { logoPath = path; logoEnabled = true; }); showQrToast(context, context.qrL10n.t('feedback.logoUpdated'), kind: QrToastKind.success); } catch (_) { if (mounted) showQrToast(context, context.qrL10n.t('feedback.logoError'), kind: QrToastKind.error); } }
  void _apply() { widget.onApply(DesignValues(foreground: foreground, background: background, module: module, frame: frame, logoEnabled: logoEnabled, logoPath: logoPath, logoPlacement: logoPlacement, gradient: gradient, caption: caption.text, captionFont: captionFont)); Navigator.pop(context); }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.label, required this.values, required this.selected, required this.onChanged});
  final String label;
  final List<String> values;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 7), Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < values.length; i++) ChoiceChip(label: Text(values[i]), selected: selected == i, onSelected: (_) => onChanged(i))])]));
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.label, required this.selected, required this.colors, required this.onSelect});
  final String label;
  final int selected;
  final List<int> colors;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: colors.map((c) => Tooltip(
            message: '#${c.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            child: GestureDetector(
              onTap: () => onSelect(c),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(c),
                child: selected == c ? const Icon(Icons.check, size: 17, color: Colors.white) : null,
              ),
            ),
          )).toList(),
        ),
      ],
    ),
  );
}

class _HexColorField extends StatefulWidget {
  const _HexColorField({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_HexColorField> createState() => _HexColorFieldState();
}

class _HexColorFieldState extends State<_HexColorField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _HexColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      controller.value = TextEditingValue(text: _format(widget.value), selection: TextSelection.collapsed(offset: _format(widget.value).length));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _format(int value) => '#${(value & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  void _parse(String value) {
    final clean = value.trim().replaceFirst('#', '');
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)) {
      widget.onChanged(int.parse('ff$clean', radix: 16));
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: _parse,
    textCapitalization: TextCapitalization.characters,
    decoration: InputDecoration(labelText: context.qrL10n.t('design.hex'), hintText: '#3730E0', prefixIcon: const Icon(Icons.tag)),
  );
}

