import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_tutorial_flutter/tutorial/TutorialPage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'design_system.dart';
import 'localization.dart';

const _widgetChannel = MethodChannel('com.qrfri.app/widget');
final ValueNotifier<String?> _widgetAction = ValueNotifier<String?>(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _widgetChannel.setMethodCallHandler((call) async {
    if (call.method == 'open') {
      final action = call.arguments?.toString();
      if (action == 'scan' || action == 'search') _widgetAction.value = action;
    }
    return null;
  });
  final store = LocalStore(await SharedPreferences.getInstance());
  await store.load();
  store.widgetTheme = store.prefs.getString('widgetTheme') == 'black' ? 'black' : 'light';
  try {
    final initialAction = await _widgetChannel.invokeMethod<String>('getInitialAction');
    if (initialAction == 'scan' || initialAction == 'search') _widgetAction.value = initialAction;
    await _widgetChannel.invokeMethod('setTheme', store.widgetTheme);
  } catch (_) {
    // The channel is only available on Android; desktop and tests keep the app usable.
  }
  runApp(QrStudioApp(store: store));
}

QrType detectQrType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.startsWith('wifi:')) return QrType.wifi;
  if (normalized.startsWith('begin:vcard')) {
    final hasName = RegExp(r'(?:^|\n)fn(?:;[^:]*)?:', caseSensitive: false).hasMatch(value);
    final hasOrganization = RegExp(r'(?:^|\n)org(?:;[^:]*)?:', caseSensitive: false).hasMatch(value);
    return hasOrganization && !hasName ? QrType.business : QrType.contact;
  }
  if (normalized.startsWith('mecard:')) return QrType.contact;
  if (normalized.startsWith('begin:vevent')) return QrType.event;
  if (normalized.startsWith('begin:vcalendar')) return QrType.calendar;
  if (normalized.startsWith('mailto:') || normalized.startsWith('matmsg:')) return QrType.email;
  if (normalized.startsWith('tel:')) return QrType.phone;
  if (normalized.startsWith('smsto:') || normalized.startsWith('sms:')) return QrType.sms;
  if (normalized.startsWith('geo:')) return QrType.location;
  if (RegExp(r'^(bitcoin|ethereum|litecoin|dogecoin|monero|solana):').hasMatch(normalized)) return QrType.crypto;
  if (normalized.startsWith('app store:') || normalized.startsWith('play store:') || normalized.startsWith('market://') || normalized.contains('apps.apple.com/') || normalized.contains('play.google.com/store/')) return QrType.appStore;
  if (normalized.startsWith('redes sociales') || RegExp(r'(?:^|\n)(instagram|facebook|linkedin)\s*:', caseSensitive: false).hasMatch(value)) return QrType.social;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized.contains('wa.me/') || normalized.contains('whatsapp.com') ? QrType.whatsapp : QrType.url;
  }
  return QrType.text;
}

bool isValidQrPayload(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return false;
  final normalized = raw.toLowerCase();
  if (normalized.startsWith('wifi:')) return RegExp(r'(?:^|;)s:', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('begin:vcard')) return RegExp(r'(?:^|\n)(fn|org|tel|email)(?:;[^:]*)?:', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('mecard:')) return RegExp(r'^mecard:(n|tel|email):', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('mailto:')) return Uri.tryParse(raw)?.path.trim().isNotEmpty == true;
  if (normalized.startsWith('tel:')) return RegExp(r'tel:\s*\+?[0-9 ()-]{3,}', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('smsto:') || normalized.startsWith('sms:')) return RegExp(r'^(?:smsto|sms):\s*\+?[0-9 ()-]{3,}', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('geo:')) return RegExp(r'^geo:-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    return uri != null && uri.host.isNotEmpty;
  }
  return true;
}

enum QrReadActionKind { open, shareFile, copy }

class QrReadAction {
  const QrReadAction({required this.label, required this.icon, required this.kind, this.uri, this.extension});
  final String label;
  final IconData icon;
  final QrReadActionKind kind;
  final Uri? uri;
  final String? extension;
}

QrReadAction qrReadActionFor(String value) {
  final type = detectQrType(value);
  switch (type) {
    case QrType.url:
    case QrType.whatsapp:
    case QrType.email:
    case QrType.phone:
    case QrType.sms:
    case QrType.location:
    case QrType.crypto:
    case QrType.appStore:
      return QrReadAction(label: 'open_${type.name}', icon: type.icon, kind: QrReadActionKind.open, uri: Uri.tryParse(value.trim()));
    case QrType.contact:
      return QrReadAction(label: 'use_contact', icon: Icons.person_add_alt_1_outlined, kind: QrReadActionKind.shareFile, extension: value.trim().toUpperCase().startsWith('BEGIN:VCARD') ? 'vcf' : 'txt');
    case QrType.event:
    case QrType.calendar:
      return const QrReadAction(label: 'use_event', icon: Icons.event_available_outlined, kind: QrReadActionKind.shareFile, extension: 'ics');
    case QrType.wifi:
    case QrType.text:
    case QrType.social:
    case QrType.business:
      return const QrReadAction(label: 'copy_info', icon: Icons.copy_outlined, kind: QrReadActionKind.copy);
  }
}

String localizedReadActionLabel(BuildContext context, String value) {
  return switch (detectQrType(value)) {
    QrType.whatsapp => context.qrL10n.t('reader.action.whatsapp'),
    QrType.email => context.qrL10n.t('reader.action.email'),
    QrType.phone => context.qrL10n.t('reader.action.phone'),
    QrType.sms => context.qrL10n.t('reader.action.sms'),
    QrType.location => context.qrL10n.t('reader.action.location'),
    QrType.contact => context.qrL10n.t('reader.action.contact'),
    QrType.event || QrType.calendar => context.qrL10n.t('reader.action.event'),
    QrType.wifi || QrType.text || QrType.social || QrType.business => context.qrL10n.t('reader.action.copy'),
    _ => context.qrL10n.t('reader.action.openUrl'),
  };
}

enum QrType { url, contact, wifi, whatsapp, text, email, phone, sms, location, event, social, business, crypto, appStore, calendar }

extension QrTypeInfo on QrType {
  String get label => switch (this) {
    QrType.url => 'Enlace', QrType.contact => 'Contacto', QrType.wifi => 'Wi-Fi', QrType.whatsapp => 'WhatsApp',
    QrType.text => 'Texto', QrType.email => 'Email', QrType.phone => 'Teléfono', QrType.sms => 'SMS',
    QrType.location => 'Ubicación', QrType.event => 'Evento', QrType.social => 'Redes sociales', QrType.business => 'Negocio',
    QrType.crypto => 'Cripto', QrType.appStore => 'App Store', QrType.calendar => 'Calendario',
  };
  IconData get icon => switch (this) {
    QrType.url => Icons.link, QrType.contact => Icons.person_outline, QrType.wifi => Icons.wifi,
    QrType.whatsapp => Icons.chat, QrType.text => Icons.notes, QrType.email => Icons.email_outlined,
    QrType.phone => Icons.phone_outlined, QrType.sms => Icons.sms_outlined, QrType.location => Icons.location_on_outlined,
    QrType.event || QrType.calendar => Icons.event_outlined, QrType.social => Icons.people_outline,
    QrType.business => Icons.storefront_outlined, QrType.crypto => Icons.currency_bitcoin, QrType.appStore => Icons.apps,
  };
  static QrType from(String value) => QrType.values.firstWhere((x) => x.name == value, orElse: () => QrType.text);
}

class QrItem {
  QrItem({required this.id, required this.name, required this.type, required this.content, DateTime? createdAt, this.favorite = false, this.archived = false, this.folder = '', this.tags = const [], this.foreground = 0xff172033, this.background = 0xffffffff, this.module = 0, this.caption = '', this.frame = 0, this.logoEnabled = false, this.captionFont = 0, this.logoPlacement = 0, this.gradient = false, this.logoPath, this.backgroundOpacity = 1, this.gradientAngle = 45, this.radialGradient = false, this.eyeStyle = 0, this.eyeColor = 0xff172033, this.cornerRadius = .5, this.quietZone = 4, this.logoSize = .2, this.logoPadding = 5, this.logoMask = 1, this.logoBackground = 0xffffffff, this.logoBorder = true, this.frameColor = 0xff3730e0, this.frameThickness = 2, this.frameShadow = false, this.shadowOpacity = .12, this.captionAbove = '', this.captionAlign = 1, this.captionColor = 0xff0f172a, this.correction = 1, this.exportSize = 1024, this.exportFormat = 'PNG', this.transparentExport = false, this.backgroundTexture = false}) : createdAt = createdAt ?? DateTime.now();
  final String id, name, content, folder, caption, captionAbove, exportFormat;
  final QrType type;
  final DateTime createdAt;
  final bool favorite, archived;
  final List<String> tags;
  final int foreground, background, module, frame, captionFont, logoPlacement, eyeStyle, eyeColor, logoMask, logoBackground, frameColor, captionAlign, captionColor, correction, exportSize;
  final double backgroundOpacity, gradientAngle, cornerRadius, quietZone, logoSize, logoPadding, frameThickness, shadowOpacity;
  final bool logoEnabled, gradient, radialGradient, logoBorder, frameShadow, transparentExport, backgroundTexture;
  final String? logoPath;
  QrItem copyWith({String? name, String? content, QrType? type, bool? favorite, bool? archived, String? folder, List<String>? tags, int? foreground, int? background, int? module, String? caption, int? frame, bool? logoEnabled, int? captionFont, int? logoPlacement, bool? gradient, String? logoPath, double? backgroundOpacity, double? gradientAngle, bool? radialGradient, int? eyeStyle, int? eyeColor, double? cornerRadius, double? quietZone, double? logoSize, double? logoPadding, int? logoMask, int? logoBackground, bool? logoBorder, int? frameColor, double? frameThickness, bool? frameShadow, double? shadowOpacity, String? captionAbove, int? captionAlign, int? captionColor, int? correction, int? exportSize, String? exportFormat, bool? transparentExport, bool? backgroundTexture}) => QrItem(id: id, name: name ?? this.name, type: type ?? this.type, content: content ?? this.content, createdAt: createdAt, favorite: favorite ?? this.favorite, archived: archived ?? this.archived, folder: folder ?? this.folder, tags: tags ?? this.tags, foreground: foreground ?? this.foreground, background: background ?? this.background, module: module ?? this.module, caption: caption ?? this.caption, frame: frame ?? this.frame, logoEnabled: logoEnabled ?? this.logoEnabled, captionFont: captionFont ?? this.captionFont, logoPlacement: logoPlacement ?? this.logoPlacement, gradient: gradient ?? this.gradient, logoPath: logoPath ?? this.logoPath, backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity, gradientAngle: gradientAngle ?? this.gradientAngle, radialGradient: radialGradient ?? this.radialGradient, eyeStyle: eyeStyle ?? this.eyeStyle, eyeColor: eyeColor ?? this.eyeColor, cornerRadius: cornerRadius ?? this.cornerRadius, quietZone: quietZone ?? this.quietZone, logoSize: logoSize ?? this.logoSize, logoPadding: logoPadding ?? this.logoPadding, logoMask: logoMask ?? this.logoMask, logoBackground: logoBackground ?? this.logoBackground, logoBorder: logoBorder ?? this.logoBorder, frameColor: frameColor ?? this.frameColor, frameThickness: frameThickness ?? this.frameThickness, frameShadow: frameShadow ?? this.frameShadow, shadowOpacity: shadowOpacity ?? this.shadowOpacity, captionAbove: captionAbove ?? this.captionAbove, captionAlign: captionAlign ?? this.captionAlign, captionColor: captionColor ?? this.captionColor, correction: correction ?? this.correction, exportSize: exportSize ?? this.exportSize, exportFormat: exportFormat ?? this.exportFormat, transparentExport: transparentExport ?? this.transparentExport, backgroundTexture: backgroundTexture ?? this.backgroundTexture);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type.name, 'content': content, 'createdAt': createdAt.toIso8601String(), 'favorite': favorite, 'archived': archived, 'folder': folder, 'tags': tags, 'foreground': foreground, 'background': background, 'module': module, 'caption': caption, 'frame': frame, 'logoEnabled': logoEnabled, 'captionFont': captionFont, 'logoPlacement': logoPlacement, 'gradient': gradient, 'logoPath': logoPath, 'backgroundOpacity': backgroundOpacity, 'gradientAngle': gradientAngle, 'radialGradient': radialGradient, 'eyeStyle': eyeStyle, 'eyeColor': eyeColor, 'cornerRadius': cornerRadius, 'quietZone': quietZone, 'logoSize': logoSize, 'logoPadding': logoPadding, 'logoMask': logoMask, 'logoBackground': logoBackground, 'logoBorder': logoBorder, 'frameColor': frameColor, 'frameThickness': frameThickness, 'frameShadow': frameShadow, 'shadowOpacity': shadowOpacity, 'captionAbove': captionAbove, 'captionAlign': captionAlign, 'captionColor': captionColor, 'correction': correction, 'exportSize': exportSize, 'exportFormat': exportFormat, 'transparentExport': transparentExport, 'backgroundTexture': backgroundTexture};
  factory QrItem.fromJson(Map<String, dynamic> j) => QrItem(id: j['id'] as String? ?? const Uuid().v4(), name: j['name'] as String? ?? 'QR', type: QrTypeInfo.from(j['type'] as String? ?? 'text'), content: j['content'] as String? ?? '', createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(), favorite: j['favorite'] as bool? ?? false, archived: j['archived'] as bool? ?? false, folder: j['folder'] as String? ?? '', tags: List<String>.from(j['tags'] as List? ?? const []), foreground: j['foreground'] as int? ?? 0xff172033, background: j['background'] as int? ?? 0xffffffff, module: j['module'] as int? ?? 0, caption: j['caption'] as String? ?? '', frame: j['frame'] as int? ?? 0, logoEnabled: j['logoEnabled'] as bool? ?? false, captionFont: j['captionFont'] as int? ?? 0, logoPlacement: j['logoPlacement'] as int? ?? 0, gradient: j['gradient'] as bool? ?? false, logoPath: j['logoPath'] as String?, backgroundOpacity: (j['backgroundOpacity'] as num?)?.toDouble() ?? 1, gradientAngle: (j['gradientAngle'] as num?)?.toDouble() ?? 45, radialGradient: j['radialGradient'] as bool? ?? false, eyeStyle: j['eyeStyle'] as int? ?? 0, eyeColor: j['eyeColor'] as int? ?? 0xff172033, cornerRadius: (j['cornerRadius'] as num?)?.toDouble() ?? .5, quietZone: (j['quietZone'] as num?)?.toDouble() ?? 4, logoSize: (j['logoSize'] as num?)?.toDouble() ?? .2, logoPadding: (j['logoPadding'] as num?)?.toDouble() ?? 5, logoMask: j['logoMask'] as int? ?? 1, logoBackground: j['logoBackground'] as int? ?? 0xffffffff, logoBorder: j['logoBorder'] as bool? ?? true, frameColor: j['frameColor'] as int? ?? 0xff3730e0, frameThickness: (j['frameThickness'] as num?)?.toDouble() ?? 2, frameShadow: j['frameShadow'] as bool? ?? false, shadowOpacity: (j['shadowOpacity'] as num?)?.toDouble() ?? .12, captionAbove: j['captionAbove'] as String? ?? '', captionAlign: j['captionAlign'] as int? ?? 1, captionColor: j['captionColor'] as int? ?? 0xff0f172a, correction: j['correction'] as int? ?? 1, exportSize: j['exportSize'] as int? ?? 1024, exportFormat: j['exportFormat'] as String? ?? 'PNG', transparentExport: j['transparentExport'] as bool? ?? false, backgroundTexture: j['backgroundTexture'] as bool? ?? false);
}

class LocalStore extends ChangeNotifier {
  LocalStore(this.prefs);
  final SharedPreferences prefs;
  final List<QrItem> items = [];
  bool darkMode = false;
  String widgetTheme = 'light';
  String languageCode = 'en';
  bool libraryGrid = true;
  List<QrType> quickTypes = [QrType.url, QrType.contact, QrType.wifi, QrType.whatsapp, QrType.text];
  Future<void> load() async { darkMode = prefs.getBool('dark') ?? false; final savedLanguage = prefs.getString('languageCode'); if (QrFriLocalizations.languageCodes.contains(savedLanguage)) { languageCode = savedLanguage!; } else { final systemLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase(); languageCode = QrFriLocalizations.languageCodes.contains(systemLanguage) ? systemLanguage : 'en'; await prefs.setString('languageCode', languageCode); } libraryGrid = prefs.getBool('libraryGrid') ?? true; final raw = prefs.getString('items'); if (raw != null) { try { items.addAll((jsonDecode(raw) as List).map((e) => QrItem.fromJson(Map<String, dynamic>.from(e)))); } catch (_) {} } final shortcuts = prefs.getStringList('quickTypes'); if (shortcuts != null && shortcuts.isNotEmpty) quickTypes = shortcuts.map(QrTypeInfo.from).toList(); }
  Future<void> save() async { await prefs.setString('items', jsonEncode(items.map((e) => e.toJson()).toList())); notifyListeners(); }
  Future<void> add(QrItem item) async { items.insert(0, item); await save(); }
  Future<void> replace(QrItem item) async { final i = items.indexWhere((e) => e.id == item.id); if (i >= 0) items[i] = item; await save(); }
  Future<void> remove(QrItem item) async { items.removeWhere((e) => e.id == item.id); await save(); }
  Future<void> setDark(bool value) async { darkMode = value; await prefs.setBool('dark', value); notifyListeners(); }
  Future<void> setWidgetTheme(String value) async {
    widgetTheme = value == 'black' ? 'black' : 'light';
    await prefs.setString('widgetTheme', widgetTheme);
    try { await _widgetChannel.invokeMethod('setTheme', widgetTheme); } catch (_) {}
    notifyListeners();
  }
  Future<void> setLanguage(String value) async { languageCode = QrFriLocalizations.languageCodes.contains(value) ? value : 'en'; await prefs.setString('languageCode', languageCode); notifyListeners(); }
  Future<void> setLibraryGrid(bool value) async { libraryGrid = value; await prefs.setBool('libraryGrid', value); notifyListeners(); }
  Future<void> setQuickTypes(List<QrType> values) async { quickTypes = values; await prefs.setStringList('quickTypes', values.map((e) => e.name).toList()); notifyListeners(); }
  Future<File> backup() async { final dir = await getApplicationDocumentsDirectory(); final file = File('${dir.path}/qrfri-backup.json'); return file.writeAsString(jsonEncode({'version': 1, 'exportedAt': DateTime.now().toIso8601String(), 'items': items.map((e) => e.toJson()).toList()})); }
  Future<void> restore(String path) async {
    final decoded = jsonDecode(await File(path).readAsString());
    if (decoded is! Map<String, dynamic>) throw const FormatException('invalid_backup');
    final version = decoded['version'];
    if (version is num && version.toInt() != 1) throw const FormatException('unsupported_backup_version');
    final rawItems = decoded['items'];
    if (rawItems is! List) throw const FormatException('invalid_backup_items');
    final restored = rawItems.map((entry) {
      if (entry is! Map) throw const FormatException('invalid_backup_item');
      return QrItem.fromJson(Map<String, dynamic>.from(entry));
    }).toList(growable: false);
    items..clear()..addAll(restored);
    await save();
  }
  List<DesignValues> loadTemplates() { final raw = prefs.getString('design_templates'); if (raw == null) return []; try { return (jsonDecode(raw) as List).map((e) => DesignValues.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) { return []; } }
  Future<void> saveTemplate(DesignValues template) async { final templates = loadTemplates()..add(template); await prefs.setString('design_templates', jsonEncode(templates.map((e) => e.toJson()).toList())); }
  Future<void> removeTemplateAt(int index) async { final templates = loadTemplates(); if (index < 0 || index >= templates.length) return; templates.removeAt(index); await prefs.setString('design_templates', jsonEncode(templates.map((e) => e.toJson()).toList())); }
}

class QrStudioApp extends StatelessWidget {
  const QrStudioApp({super.key, required this.store});
  final LocalStore store;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: store, builder: (_, __) => MaterialApp(title: 'QRfri', debugShowCheckedModeBanner: false, locale: Locale(store.languageCode), supportedLocales: QrFriLocalizations.supported, localizationsDelegates: const [QrFriLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate], themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light, theme: _theme(Brightness.light), darkTheme: _theme(Brightness.dark), home: _LaunchGate(store: store)));
  ThemeData _theme(Brightness brightness) => qrFriTheme(brightness);
}

class _LaunchGate extends StatefulWidget {
  const _LaunchGate({required this.store});
  final LocalStore store;

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  late bool seen;
  bool completing = false;

  @override
  void initState() {
    super.initState();
    seen = widget.store.prefs.getBool('seen_tutorial') ?? false;
  }

  Future<void> _complete() async {
    if (completing || seen) return;
    completing = true;
    await widget.store.prefs.setBool('seen_tutorial', true);
    if (mounted) setState(() => seen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (seen) return HomeShell(store: widget.store);
    return TutorialScreen(onCompleted: _complete, showSkipButton: true, languageCode: widget.store.languageCode);
  }
}

class HomeShell extends StatefulWidget { const HomeShell({super.key, required this.store}); final LocalStore store; @override State<HomeShell> createState() => _HomeShellState(); }
class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  bool focusLibrarySearch = false;

  @override
  void initState() {
    super.initState();
    _widgetAction.addListener(_handleWidgetAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleWidgetAction());
  }

  @override
  void dispose() {
    _widgetAction.removeListener(_handleWidgetAction);
    super.dispose();
  }

  void _handleWidgetAction() {
    final action = _widgetAction.value;
    if (!mounted || action == null) return;
    _widgetAction.value = null;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      tab = action == 'scan' ? 2 : 1;
      focusLibrarySearch = action == 'search';
    });
  }

  @override Widget build(BuildContext context) { final pages = [HomePage(store: widget.store, openCreate: (t) => _create(context, t)), LibraryPage(store: widget.store, openCreate: () => _create(context, null), autoFocusSearch: focusLibrarySearch), ScannerPage(store: widget.store, onSaved: () => setState(() => tab = 1)), SettingsPage(store: widget.store)]; return Scaffold(body: SafeArea(child: pages[tab]), bottomNavigationBar: QrFriBottomNavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() { tab = i; focusLibrarySearch = false; }))); }
  Future<void> _create(BuildContext context, QrType? type, {QrItem? existing}) async { await Navigator.push(context, MaterialPageRoute(builder: (_) => EditorPage(store: widget.store, initialType: type, existing: existing))); setState(() {}); }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      boxShadow: const [BoxShadow(color: Color(0x100f172a), blurRadius: 10, offset: Offset(0, 4))],
    ),
    child: IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon, color: QrFriColors.indigo, size: 23)),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store, required this.openCreate});
  final LocalStore store;
  final void Function(QrType) openCreate;

  @override
  Widget build(BuildContext context) {
    final recent = store.items.where((e) => !e.archived).take(3).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const QrFriLogo(height: 42),
            _CircleActionButton(tooltip: context.qrL10n.t('home.new'), icon: Icons.add, onPressed: () => openCreate(QrType.url)),
          ],
        ),
        const SizedBox(height: 8),
        Text(context.qrL10n.t('home.tagline'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => openCreate(QrType.url),
          icon: const Icon(Icons.qr_code_2),
          label: Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(context.qrL10n.t('home.create'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.qrL10n.t('home.shortcuts'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuickAccessPage(store: store))), child: Text(context.qrL10n.t('home.edit'))),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.0,
          children: store.quickTypes.map((t) => Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openCreate(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Row(
                  children: [
                    Icon(t.icon, color: QrFriColors.indigo, size: 20),
                    const SizedBox(width: 6),
                    Expanded(child: Text(context.qrL10n.typeLabel(t), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.qrL10n.t('home.recent'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (store.items.isNotEmpty) Text('${store.items.length} ${context.qrL10n.t('library.savedCount')}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          _EmptyState(icon: Icons.qr_code_2, title: context.qrL10n.t('home.empty.title'), subtitle: context.qrL10n.t('home.empty.subtitle'))
        else
          ...recent.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: QrListTile(item: item, store: store))),
      ],
    );
  }
}

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
        error = value == null || value.isEmpty ? 'No se pudo leer este QR. Aumenta el contraste o el tamaño.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        reading = false;
        error = 'No se pudo analizar el QR en pantalla.';
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
        setState(() => error = 'No se pudo completar esta acción. Puedes copiar el contenido manualmente.');
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

class LibraryPage extends StatefulWidget { const LibraryPage({super.key, required this.store, required this.openCreate, this.autoFocusSearch = false}); final LocalStore store; final VoidCallback openCreate; final bool autoFocusSearch; @override State<LibraryPage> createState() => _LibraryPageState(); }
class _LibraryPageState extends State<LibraryPage> {
  String query = '';
  late bool grid;
  bool favoritesOnly = false;
  String sort = 'newest';
  QrType? filter;
  final searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    grid = widget.store.libraryGrid;
    if (widget.autoFocusSearch) WidgetsBinding.instance.addPostFrameCallback((_) => searchFocus.requestFocus());
  }

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoFocusSearch && !oldWidget.autoFocusSearch) WidgetsBinding.instance.addPostFrameCallback((_) => searchFocus.requestFocus());
  }

  @override
  void dispose() {
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.store.items.where((item) {
      final matchesQuery = query.isEmpty || '${item.name} ${item.content}'.toLowerCase().contains(query.toLowerCase());
      return !item.archived && matchesQuery && (filter == null || item.type == filter) && (!favoritesOnly || item.favorite);
    }).toList()
      ..sort((a, b) {
        switch (sort) {
          case 'oldest': return a.createdAt.compareTo(b.createdAt);
          case 'name': return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          default: return b.createdAt.compareTo(a.createdAt);
        }
      });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(children: [
            Expanded(child: Text(context.qrL10n.t('nav.library'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
            _CircleActionButton(tooltip: context.qrL10n.t('library.new'), icon: Icons.add, onPressed: widget.openCreate),
          ]),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(focusNode: searchFocus, onChanged: (value) => setState(() => query = value), decoration: InputDecoration(hintText: context.qrL10n.t('library.search'), prefixIcon: const Icon(Icons.search)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? QrFriColors.darkRaised : QrFriColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : QrFriColors.border),
                  ),
                  child: Row(children: [
                    _LibraryViewButton(selected: !grid, icon: Icons.view_list_rounded, label: context.qrL10n.t('library.list'), onTap: () { setState(() => grid = false); widget.store.setLibraryGrid(false); }),
                    _LibraryViewButton(selected: grid, icon: Icons.grid_view_rounded, label: context.qrL10n.t('library.grid'), onTap: () { setState(() => grid = true); widget.store.setLibraryGrid(true); }),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              _LibraryActionButton(icon: Icons.sort_rounded, label: context.qrL10n.t('library.sort'), onTap: () => _chooseSort(context)),
              const SizedBox(width: 8),
              _LibraryFavoriteFilter(active: favoritesOnly, onTap: () => setState(() => favoritesOnly = !favoritesOnly)),
            ],
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              FilterChip(label: Text(context.qrL10n.t('library.all')), selected: filter == null, onSelected: (_) => setState(() => filter = null)),
              ...QrType.values.map((type) => Padding(padding: const EdgeInsets.only(left: 8), child: FilterChip(label: Text(context.qrL10n.typeLabel(type)), selected: filter == type, onSelected: (_) => setState(() => filter = filter == type ? null : type)))),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            child: items.isEmpty
                ? _EmptyState(key: const ValueKey('library-empty'), icon: Icons.search_off, title: context.qrL10n.t('library.empty'), subtitle: context.qrL10n.t('library.empty.subtitle'))
                : grid
                    ? GridView.builder(key: ValueKey('grid:$sort:$favoritesOnly:${filter?.name}:$query'), padding: const EdgeInsets.all(20), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 210, mainAxisExtent: 250, crossAxisSpacing: 14, mainAxisSpacing: 14), itemCount: items.length, itemBuilder: (_, index) => QrCard(item: items[index], store: widget.store))
                    : ListView.separated(key: ValueKey('list:$sort:$favoritesOnly:${filter?.name}:$query'), padding: const EdgeInsets.all(20), itemCount: items.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, index) => QrListTile(item: items[index], store: widget.store)),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseSort(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sheetContext.qrL10n.t('library.sortTitle'), style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final option in [('newest', sheetContext.qrL10n.t('library.sort.newest')), ('oldest', sheetContext.qrL10n.t('library.sort.oldest')), ('name', sheetContext.qrL10n.t('library.sort.name'))])
                RadioListTile<String>(value: option.$1, groupValue: sort, title: Text(option.$2), activeColor: QrFriColors.indigo, onChanged: (value) => Navigator.pop(sheetContext, value)),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => sort = selected);
  }
}

class _LibraryViewButton extends StatelessWidget {
  const _LibraryViewButton({required this.selected, required this.icon, required this.label, required this.onTap});
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(color: selected ? QrFriColors.indigo.withValues(alpha: .12) : Colors.transparent, borderRadius: BorderRadius.circular(11)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: selected ? QrFriColors.indigo : const Color(0xff94a3b8)), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? QrFriColors.indigo : const Color(0xff94a3b8)))]),
      ),
    ),
  );
}

class _LibraryActionButton extends StatelessWidget {
  const _LibraryActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? QrFriColors.darkRaised : QrFriColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : QrFriColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 19, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
      ),
    ),
  );
}

class _LibraryFavoriteFilter extends StatelessWidget {
  const _LibraryFavoriteFilter({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: active ? QrFriColors.indigo.withValues(alpha: .12) : (Theme.of(context).brightness == Brightness.dark ? QrFriColors.darkRaised : QrFriColors.white), borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? QrFriColors.indigo.withValues(alpha: .2) : (Theme.of(context).brightness == Brightness.dark ? Colors.white12 : QrFriColors.border))),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              active ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(active),
              size: 20,
              color: active ? QrFriColors.indigo : const Color(0xff94a3b8),
            ),
          ),
        ),
      ),
    ),
  );
}

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

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.item, required this.store});
  final QrItem item;
  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    final qrSize = (MediaQuery.sizeOf(context).width - 100).clamp(180.0, 250.0).toDouble();
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          _FavoriteButton(favorite: item.favorite, onChanged: (value) => store.replace(item.copyWith(favorite: value))),
          IconButton(tooltip: context.qrL10n.t('detail.edit'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditorPage(store: store, existing: item))), icon: const Icon(Icons.edit_outlined)),
          IconButton(tooltip: context.qrL10n.t('detail.delete'), onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Card(child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 16), child: Column(children: [QrVisual(item: item, size: qrSize), const SizedBox(height: 12), Text(context.qrL10n.typeLabel(item.type), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: QrFriColors.indigo, fontWeight: FontWeight.w700))]))),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.qrL10n.t('detail.content'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), SelectableText(item.content)]))),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            OutlinedButton.icon(onPressed: () async { try { await Clipboard.setData(ClipboardData(text: item.content)); if (context.mounted) showQrToast(context, context.qrL10n.t('scanner.copySuccess'), kind: QrToastKind.success); } catch (_) { if (context.mounted) showQrToast(context, context.qrL10n.t('scanner.copyError'), kind: QrToastKind.error); } }, icon: const Icon(Icons.copy), label: Text(context.qrL10n.t('detail.copyContent'))),
            FilledButton.icon(onPressed: () => _shareContent(context), icon: const Icon(Icons.ios_share), label: Text(context.qrL10n.t('common.share'))),
            OutlinedButton.icon(onPressed: () => _showAdvanced(context), icon: const Icon(Icons.download_outlined), label: Text(context.qrL10n.t('detail.export'))),
          ]),
        ],
      ),
    );
  }

  Future<void> _shareContent(BuildContext context) async {
    try {
      final result = await Share.share(item.content, subject: item.name);
      if (context.mounted && result.status == ShareResultStatus.success) showQrToast(context, context.qrL10n.t('feedback.qrShared'), kind: QrToastKind.success);
      if (context.mounted && result.status == ShareResultStatus.dismissed) showQrToast(context, context.qrL10n.t('feedback.shareCancelled'), kind: QrToastKind.info);
      if (context.mounted && result.status == ShareResultStatus.unavailable) showQrToast(context, context.qrL10n.t('feedback.shareMenu'), kind: QrToastKind.info);
    } catch (_) {
      if (context.mounted) showQrToast(context, context.qrL10n.t('feedback.openError'), kind: QrToastKind.error);
    }
  }

  Future<void> _showAdvanced(BuildContext context) async {
    var correction = item.correction;
    var exportSize = [512, 1024, 2048, 4096].contains(item.exportSize) ? item.exportSize : 1024;
    var exportFormat = ['PNG', 'JPG', 'PDF'].contains(item.exportFormat) ? item.exportFormat : 'PNG';
    var transparent = item.transparentExport;
    var texture = item.backgroundTexture;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      elevation: 14,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [QrFriColors.indigo, QrFriColors.indigoDark]), borderRadius: BorderRadius.circular(14), boxShadow: QrFriElevation.floating), child: const Icon(Icons.file_download_outlined, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.qrL10n.t('export.title'), style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(context.qrL10n.t('export.subtitle'), style: Theme.of(sheetContext).textTheme.bodySmall)])), IconButton(tooltip: context.qrL10n.t('common.close'), onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close))]),
              const SizedBox(height: 14),
              Text(context.qrL10n.t('export.configuration'), style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(color: QrFriColors.indigo, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _ChoiceGroup(label: context.qrL10n.t('design.errorCorrection'), values: const ['L · Básica', 'M · Equilibrada', 'Q · Alta', 'H · Máxima'], selected: correction, onChanged: (v) => setSheetState(() => correction = v)),
              _ChoiceGroup(label: context.qrL10n.t('export.quality'), values: const ['512 px', '1024 px', '2048 px', '4096 px'], selected: [512, 1024, 2048, 4096].indexOf(exportSize), onChanged: (v) => setSheetState(() => exportSize = [512, 1024, 2048, 4096][v])),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest.withValues(alpha: .55), borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(sheetContext).colorScheme.outlineVariant)), child: Row(children: [Container(width: 76, height: 76, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: QrVisual(item: item, size: 68)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${sheetContext.qrL10n.typeLabel(item.type)} · $exportFormat', style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: QrFriColors.indigo, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${exportSize}px', style: Theme.of(sheetContext).textTheme.bodySmall)]))])),
              const SizedBox(height: 14),
              const SizedBox(height: 2),
              Text(context.qrL10n.t('export.finish'), style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(color: QrFriColors.indigo, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _ChoiceGroup(label: context.qrL10n.t('export.format'), values: const ['PNG', 'JPG', 'PDF'], selected: ['PNG', 'JPG', 'PDF'].indexOf(exportFormat), onChanged: (v) => setSheetState(() => exportFormat = ['PNG', 'JPG', 'PDF'][v])),
              SwitchListTile(contentPadding: EdgeInsets.zero, value: transparent, onChanged: (v) => setSheetState(() => transparent = v), title: Text(context.qrL10n.t('export.transparent'))),
              SwitchListTile(contentPadding: EdgeInsets.zero, value: texture, onChanged: (v) => setSheetState(() => texture = v), title: Text(context.qrL10n.t('export.texture'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(sheetContext, true), icon: const Icon(Icons.download_outlined), label: Text(context.qrL10n.t('export.start')))),
            ]),
          ),
        ),
      ),
    );
    if (saved != true) return;
    try {
      final updatedItem = item.copyWith(correction: correction, exportSize: exportSize, exportFormat: exportFormat, transparentExport: transparent, backgroundTexture: texture);
      await store.replace(updatedItem);
      if (context.mounted) await _exportQr(context, updatedItem);
    } catch (_) {
      if (context.mounted) showQrToast(context, context.qrL10n.t('feedback.exportError'), kind: QrToastKind.error);
    }
  }

  Future<void> _exportQr(BuildContext context, QrItem exportItem) async {
    final pngBytes = await showDialog<Uint8List>(context: context, barrierDismissible: false, builder: (_) => _QrExportCaptureDialog(item: exportItem));
    if (pngBytes == null || !context.mounted) return;
    late Uint8List bytes;
    late String extension;
    switch (exportItem.exportFormat) {
      case 'JPG':
        final decoded = img.decodeImage(pngBytes);
        if (decoded == null) throw StateError('jpg_decode_failed');
        final quality = exportItem.exportSize >= 4096 ? 96 : exportItem.exportSize >= 2048 ? 93 : exportItem.exportSize >= 1024 ? 88 : 82;
        bytes = img.encodeJpg(decoded, quality: quality);
        extension = 'jpg';
        break;
      case 'PDF':
        final document = pw.Document();
        final image = pw.MemoryImage(pngBytes);
        document.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain))));
        bytes = await document.save();
        extension = 'pdf';
        break;
      default:
        bytes = pngBytes;
        extension = 'png';
    }
    final safeName = exportItem.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${safeName.isEmpty ? 'qrfri' : safeName}-${DateTime.now().millisecondsSinceEpoch}.$extension');
    await file.writeAsBytes(bytes, flush: true);
    final result = await Share.shareXFiles([XFile(file.path)], subject: exportItem.name);
    if (context.mounted && result.status == ShareResultStatus.success) showQrToast(context, context.qrL10n.t('feedback.qrExported').replaceAll('{format}', exportItem.exportFormat), kind: QrToastKind.success);
    if (context.mounted && result.status == ShareResultStatus.dismissed) showQrToast(context, context.qrL10n.t('export.cancelled'), kind: QrToastKind.info);
    if (context.mounted && result.status == ShareResultStatus.unavailable) showQrToast(context, context.qrL10n.t('feedback.fileGenerated'), kind: QrToastKind.info);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showQrConfirmation(context, title: context.qrL10n.t('detail.deleteTitle'), description: context.qrL10n.t('detail.deleteDescription'), confirmLabel: context.qrL10n.t('common.delete'), destructive: true, icon: Icons.delete_outline);
    if (confirmed != true) return;
    try {
      await store.remove(item);
      if (context.mounted) {
        showQrToast(context, context.qrL10n.t('feedback.qrDeleted'), kind: QrToastKind.success);
        Navigator.pop(context);
      }
    } catch (_) {
      if (context.mounted) showQrToast(context, context.qrL10n.t('feedback.qrDeleteError'), kind: QrToastKind.error);
    }
  }
}

class _QrExportCaptureDialog extends StatefulWidget {
  const _QrExportCaptureDialog({required this.item});
  final QrItem item;

  @override
  State<_QrExportCaptureDialog> createState() => _QrExportCaptureDialogState();
}

class _QrExportCaptureDialogState extends State<_QrExportCaptureDialog> {
  final boundaryKey = GlobalKey();
  bool capturing = false;

  Future<void> _capture() async {
    if (capturing) return;
    setState(() => capturing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.size.isEmpty) throw StateError('export_not_ready');
      final pixelRatio = (widget.item.exportSize / boundary.size.longestSide).clamp(1.0, 16.0).toDouble();
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('export_capture_failed');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) setState(() => capturing = false);
      if (mounted) showQrToast(context, context.qrL10n.t('feedback.captureError'), kind: QrToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiresWhiteBackground = widget.item.exportFormat == 'JPG' || widget.item.exportFormat == 'PDF';
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [const Icon(Icons.download_outlined, color: QrFriColors.indigo), const SizedBox(width: 10), Expanded(child: Text('${context.qrL10n.t('export.title')} ${widget.item.exportFormat}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), IconButton(tooltip: context.qrL10n.t('common.close'), onPressed: capturing ? null : () => Navigator.pop(context), icon: const Icon(Icons.close))]),
            const SizedBox(height: 14),
            RepaintBoundary(key: boundaryKey, child: ColoredBox(color: requiresWhiteBackground ? Colors.white : Colors.transparent, child: Padding(padding: const EdgeInsets.all(8), child: QrVisual(item: widget.item, size: 240)))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: capturing ? null : _capture, icon: Icon(capturing ? Icons.hourglass_top : Icons.download), label: Text(capturing ? context.qrL10n.t('export.preparing') : context.qrL10n.t('export.now')))),
          ]),
        ),
      ),
    );
  }
}

class ScannerPage extends StatefulWidget { const ScannerPage({super.key, required this.store, this.onSaved}); final LocalStore store; final VoidCallback? onSaved; @override State<ScannerPage> createState() => _ScannerPageState(); }
class _ScannerPageState extends State<ScannerPage> {
  bool torch = false;
  bool cameraRequested = false;
  bool permissionChecked = false;
  bool showingResultActions = false;
  bool resultBusy = false;
  String? result;
  final resultNameController = TextEditingController();
  final controller = MobileScannerController(autoStart: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCamera());
  }

  @override
  void dispose() {
    resultNameController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _copyDetectedResult(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) showQrToast(context, context.qrL10n.t('scanner.copySuccess'), kind: QrToastKind.success);
    } catch (_) {
      if (mounted) showQrToast(context, context.qrL10n.t('scanner.copyError'), kind: QrToastKind.error);
    }
  }

  Future<void> _saveDetectedResult(String value, {String? suggestedName}) async {
    try {
      final type = detectQrType(value);
      final item = QrItem(id: const Uuid().v4(), name: suggestedName?.trim().isNotEmpty == true ? suggestedName!.trim() : context.qrL10n.typeLabel(type), type: type, content: value);
      await widget.store.add(item);
      if (mounted) showQrToast(context, context.qrL10n.t('scanner.saved'), kind: QrToastKind.success);
      widget.onSaved?.call();
    } catch (_) {
      if (mounted) showQrToast(context, context.qrL10n.t('scanner.saveError'), kind: QrToastKind.error);
    }
  }

  Future<void> _activateDetectedResult(String value) async {
    final action = qrReadActionFor(value);
    try {
      switch (action.kind) {
        case QrReadActionKind.open:
          final uri = action.uri;
          if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) throw StateError('launch_failed');
          if (mounted) showQrToast(context, context.qrL10n.t('feedback.contentReady').replaceAll('{action}', localizedReadActionLabel(context, value)), kind: QrToastKind.success);
          break;
        case QrReadActionKind.copy:
          await _copyDetectedResult(value);
          break;
        case QrReadActionKind.shareFile:
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/qrfri-${DateTime.now().microsecondsSinceEpoch}.${action.extension ?? 'txt'}');
          await file.writeAsString(value);
          try {
            final type = detectQrType(value);
            final shareResult = await Share.shareXFiles([XFile(file.path)], subject: type == QrType.contact ? 'Contacto QRfri' : 'Evento QRfri');
            if (mounted && shareResult.status == ShareResultStatus.success) showQrToast(context, context.qrL10n.t('feedback.shareAction').replaceAll('{action}', localizedReadActionLabel(context, value)), kind: QrToastKind.success);
            if (mounted && shareResult.status == ShareResultStatus.dismissed) showQrToast(context, context.qrL10n.t('feedback.shareCancelled'), kind: QrToastKind.info);
            if (mounted && shareResult.status == ShareResultStatus.unavailable) showQrToast(context, context.qrL10n.t('feedback.shareMenu'), kind: QrToastKind.info);
          } finally {
            try { await file.delete(); } catch (_) {}
          }
          break;
      }
    } catch (_) {
      if (mounted) showQrToast(context, context.qrL10n.t('feedback.openError'), kind: QrToastKind.error);
    }
  }

  Future<void> _runResultOperation(Future<void> Function() operation) async {
    if (resultBusy) return;
    setState(() => resultBusy = true);
    try {
      await operation();
    } finally {
      if (mounted) setState(() => resultBusy = false);
    }
  }

  Future<void> _dismissCameraResult() async {
    if (!mounted) return;
    setState(() {
      result = null;
      showingResultActions = false;
      resultBusy = false;
    });
    if (cameraRequested) await controller.start();
  }

  Future<void> _editDetectedResult(String value) async {
    final type = detectQrType(value);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EditorPage(store: widget.store, initialType: type, initialContent: value, initialName: resultNameController.text.trim())));
    if (mounted) await _dismissCameraResult();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(children: [
            Text(context.qrL10n.t('nav.scan'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(tooltip: context.qrL10n.t('scan.import'), onPressed: _importFromGallery, icon: const Icon(Icons.photo_library_outlined)),
            IconButton(tooltip: context.qrL10n.t('scan.torch'), onPressed: () { controller.toggleTorch(); setState(() => torch = !torch); }, icon: Icon(torch ? Icons.flash_on : Icons.flash_off)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!permissionChecked)
                    const Center(child: CircularProgressIndicator(color: QrFriColors.indigo))
                  else if (!cameraRequested)
                    _CameraPermissionFrame(onAccept: _requestCameraPermission)
                  else
                    MobileScanner(
                      controller: controller,
                      errorBuilder: (errorContext, error, child) => _CameraPermissionFrame(
                        onAccept: _requestCameraPermission,
                      ),
                      onDetect: (capture) {
                        final value = capture.barcodes.firstOrNull?.rawValue?.trim();
                        if (value != null && value.isNotEmpty && value != result && !showingResultActions && isValidQrPayload(value)) {
                          setState(() {
                            result = value;
                            resultNameController.text = context.qrL10n.typeLabel(detectQrType(value));
                            showingResultActions = true;
                          });
                          controller.stop();
                          _showReadResultActions(value).whenComplete(() {
                            if (mounted) {
                              setState(() {
                                result = null;
                                showingResultActions = false;
                              });
                              controller.start();
                            }
                          });
                        }
                      },
                    ),
                  if (cameraRequested)
                    Center(child: Container(width: 230, height: 230, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(18)))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Align(alignment: Alignment.centerLeft, child: Text(context.qrL10n.t('scanner.hint'), style: const TextStyle(color: Colors.grey)))),
        const SizedBox(height: 18),
      ],
    );
  }

  Future<void> _requestCameraPermission() async {
    try {
      if (!mounted) return;
      setState(() { permissionChecked = true; cameraRequested = true; });
      // El widget necesita estar montado antes de iniciar la petición nativa.
      await WidgetsBinding.instance.endOfFrame;
      await controller.start();
      if (!mounted) return;
      if (!controller.value.isRunning) {
        setState(() => cameraRequested = false);
        showQrToast(context, context.qrL10n.t('scanner.permissionError'), kind: QrToastKind.error);
      }
    } catch (_) {
      if (mounted) {
        setState(() { permissionChecked = true; cameraRequested = false; });
        showQrToast(context, context.qrL10n.t('scanner.activateError'), kind: QrToastKind.error);
      }
    }
  }

  Future<void> _prepareCamera() async {
    try {
      const channel = MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
      final state = await channel.invokeMethod<int>('state') ?? 0;
      // 1 es el estado autorizado del plugin mobile_scanner.
      if (!mounted) return;
      if (state != 1) {
        setState(() => permissionChecked = true);
        return;
      }
      setState(() { permissionChecked = true; cameraRequested = true; });
      await WidgetsBinding.instance.endOfFrame;
      await controller.start();
      if (mounted && !controller.value.isRunning) {
        setState(() => cameraRequested = false);
      }
    } catch (_) {
      if (mounted) setState(() { permissionChecked = true; cameraRequested = false; });
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      final path = picked?.files.single.path;
      if (path == null) return;
      await controller.stop();
      final capture = await controller.analyzeImage(path);
      final value = capture?.barcodes.firstOrNull?.rawValue?.trim();
      if (!mounted) return;
      if (value == null || value.isEmpty || !isValidQrPayload(value)) {
        showQrToast(context, context.qrL10n.t('scanner.noQr'), kind: QrToastKind.error);
        await controller.start();
        return;
      }
      setState(() {
        result = null;
        showingResultActions = false;
      });
      await _showReadResultActions(value);
    } catch (_) {
      if (mounted) showQrToast(context, context.qrL10n.t('scanner.analyzeError'), kind: QrToastKind.error);
    } finally {
      if (mounted) await controller.start();
    }
  }

  Future<void> _showReadResultActions(String value, {String? suggestedName}) async {
    final type = detectQrType(value);
    final action = qrReadActionFor(value);
    final nameController = TextEditingController(text: suggestedName ?? context.qrL10n.typeLabel(type));
    var busy = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (sheetContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(sheetContext).height * .9),
          child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> runAction() async {
            if (busy) return;
            setSheetState(() => busy = true);
            try {
              switch (action.kind) {
                case QrReadActionKind.open:
                  final uri = action.uri;
                  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) throw StateError('launch_failed');
                  if (mounted) showQrToast(context, context.qrL10n.t('feedback.contentReady').replaceAll('{action}', localizedReadActionLabel(context, value)), kind: QrToastKind.success);
                  break;
                case QrReadActionKind.copy:
                  await Clipboard.setData(ClipboardData(text: value));
                  if (mounted) showQrToast(context, context.qrL10n.t('scanner.copySuccess'), kind: QrToastKind.success);
                  break;
                case QrReadActionKind.shareFile:
                  final directory = await getTemporaryDirectory();
                  final file = File('${directory.path}/qrfri-${DateTime.now().microsecondsSinceEpoch}.${action.extension ?? 'txt'}');
                  await file.writeAsString(value);
                  try {
                    final shareResult = await Share.shareXFiles([XFile(file.path)], subject: type == QrType.contact ? 'Contacto QRfri' : 'Evento QRfri');
                    if (mounted && shareResult.status == ShareResultStatus.success) showQrToast(context, context.qrL10n.t('feedback.shareAction').replaceAll('{action}', localizedReadActionLabel(context, value)), kind: QrToastKind.success);
                    if (mounted && shareResult.status == ShareResultStatus.dismissed) showQrToast(context, context.qrL10n.t('feedback.shareCancelled'), kind: QrToastKind.info);
                  } finally {
                    try { await file.delete(); } catch (_) {}
                  }
                  break;
              }
            } catch (_) {
              if (mounted) showQrToast(context, context.qrL10n.t('feedback.openError'), kind: QrToastKind.error);
            } finally {
              if (sheetContext.mounted) setSheetState(() => busy = false);
            }
          }

          Future<void> saveResult() async {
            if (busy) return;
            setSheetState(() => busy = true);
            try {
              final item = QrItem(id: const Uuid().v4(), name: nameController.text.trim().isEmpty ? context.qrL10n.typeLabel(type) : nameController.text.trim(), type: type, content: value);
              await widget.store.add(item);
              if (mounted) showQrToast(context, context.qrL10n.t('scanner.saved'), kind: QrToastKind.success);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
              widget.onSaved?.call();
            } catch (_) {
              if (mounted) showQrToast(context, context.qrL10n.t('scanner.saveError'), kind: QrToastKind.error);
            } finally {
              if (sheetContext.mounted) setSheetState(() => busy = false);
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(sheetContext.qrL10n.t('reader.result'), style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                  IconButton(tooltip: sheetContext.qrL10n.t('reader.close'), onPressed: busy ? null : () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 4),
                Text('${sheetContext.qrL10n.t('scanner.type')}: ${sheetContext.qrL10n.typeLabel(type)}', style: Theme.of(sheetContext).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(controller: nameController, textInputAction: TextInputAction.done, decoration: InputDecoration(labelText: sheetContext.qrL10n.t('scanner.libraryName'), prefixIcon: const Icon(Icons.label_outline), isDense: true)),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(sheetContext).colorScheme.outlineVariant)),
                    child: QrImageView(data: value, version: QrVersions.auto, size: 310),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: QrFriColors.emerald.withValues(alpha: .1), borderRadius: BorderRadius.circular(14), border: Border.all(color: QrFriColors.emerald.withValues(alpha: .28))),
                  child: SelectableText(value),
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  OutlinedButton.icon(onPressed: busy ? null : () async { try { await Clipboard.setData(ClipboardData(text: value)); if (mounted) showQrToast(context, context.qrL10n.t('scanner.copySuccess'), kind: QrToastKind.success); } catch (_) { if (mounted) showQrToast(context, context.qrL10n.t('scanner.copyError'), kind: QrToastKind.error); } }, icon: const Icon(Icons.copy_outlined), label: Text(sheetContext.qrL10n.t('reader.copy'))),
                  FilledButton.icon(onPressed: busy ? null : runAction, icon: Icon(busy ? Icons.hourglass_top : action.icon), label: Text(busy ? sheetContext.qrL10n.t('reader.opening') : localizedReadActionLabel(sheetContext, value))),
                  OutlinedButton.icon(onPressed: busy ? null : saveResult, icon: const Icon(Icons.save_outlined), label: Text(sheetContext.qrL10n.t('common.save'))),
                  OutlinedButton.icon(onPressed: busy ? null : () async { final selectedName = nameController.text.trim(); Navigator.pop(sheetContext); await Navigator.push(context, MaterialPageRoute(builder: (_) => EditorPage(store: widget.store, initialType: type, initialContent: value, initialName: selectedName))); }, icon: const Icon(Icons.edit_outlined), label: Text(sheetContext.qrL10n.t('home.edit'))),
                  TextButton.icon(onPressed: busy ? null : () => Navigator.pop(sheetContext), icon: const Icon(Icons.close), label: Text(sheetContext.qrL10n.t('reader.close'))),
                ]),
              ],
            ),
          );
        },
          ),
        ),
      ),
    );
  }
}

class _CameraPermissionFrame extends StatelessWidget {
  const _CameraPermissionFrame({required this.onAccept});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => Container(
    color: QrFriColors.darkSurface,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
    child: Center(
      child: Card(
        color: Theme.of(context).cardTheme.color,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Lottie.asset('assets/lotties/scan_complex.json', repeat: true),
              ),
              const SizedBox(height: 8),
              Text(context.qrL10n.t('scan.permission.title'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(context.qrL10n.t('scan.permission.description'), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(onPressed: onAccept, icon: const Icon(Icons.camera_alt_outlined), label: Text(context.qrL10n.t('scan.permission'))),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class QuickAccessPage extends StatefulWidget {
  const QuickAccessPage({super.key, required this.store});
  final LocalStore store;
  @override State<QuickAccessPage> createState() => _QuickAccessPageState();
}

class _QuickAccessPageState extends State<QuickAccessPage> {
  late List<QrType> selected;
  @override void initState() { super.initState(); selected = [...widget.store.quickTypes]; }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(context.qrL10n.t('quick.title')), actions: [TextButton(onPressed: () async { await widget.store.setQuickTypes(selected); if (context.mounted) Navigator.pop(context); }, child: Text(context.qrL10n.t('quick.save')))]), body: ListView(padding: const EdgeInsets.all(20), children: [Text(context.qrL10n.t('quick.description'), style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 14), ReorderableListView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), onReorder: (oldIndex, newIndex) { setState(() { if (newIndex > oldIndex) newIndex--; final item = selected.removeAt(oldIndex); selected.insert(newIndex, item); }); }, children: selected.map((type) => Card(key: ValueKey(type), child: ListTile(leading: Icon(type.icon, color: QrFriColors.indigo), title: Text(context.qrL10n.typeLabel(type)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: context.qrL10n.t('quick.remove'), onPressed: () => setState(() => selected.remove(type)), icon: const Icon(Icons.remove_circle_outline)), const Icon(Icons.drag_handle)])))).toList()), const SizedBox(height: 18), Text(context.qrL10n.t('quick.add'), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: QrType.values.where((type) => !selected.contains(type)).map((type) => ActionChip(avatar: Icon(type.icon, size: 17), label: Text(context.qrL10n.typeLabel(type)), onPressed: () => setState(() => selected.add(type)))).toList())]));
}

class _SettingsIconBadge extends StatelessWidget {
  const _SettingsIconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .2 : .1),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: color, size: 21),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});
  final LocalStore store;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
    children: [
      // Encabezado inspirado en la referencia: marca a la izquierda y
      // la ilustración decorativa a la derecha, sin desbordar en 320 px.
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: QrFriLogo(height: 42),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 124,
            height: 102,
            child: Image.asset(
              'assets/settings_image.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(context.qrL10n.t('settings.title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      Card(child: Column(children: [
        SwitchListTile(
          value: store.darkMode,
          onChanged: store.setDark,
          title: Text(context.qrL10n.t('settings.dark')),
          subtitle: Text(context.qrL10n.t('settings.dark.subtitle')),
          secondary: const _SettingsIconBadge(icon: Icons.dark_mode_outlined, color: QrFriColors.indigo),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const _SettingsIconBadge(icon: Icons.tune, color: QrFriColors.indigo),
          title: Text(context.qrL10n.t('settings.shortcuts')),
          subtitle: Text(context.qrL10n.t('settings.shortcuts.subtitle')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuickAccessPage(store: store))),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const _SettingsIconBadge(icon: Icons.language, color: QrFriColors.indigo),
          title: Text(context.qrL10n.t('settings.language')),
          subtitle: Text(context.qrL10n.languageName(store.languageCode)),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _chooseLanguage(context),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const _SettingsIconBadge(icon: Icons.widgets_outlined, color: QrFriColors.indigo),
          title: Text(context.qrL10n.t('settings.widgetTheme')),
          subtitle: Text(store.widgetTheme == 'black' ? context.qrL10n.t('settings.widgetTheme.black') : context.qrL10n.t('settings.widgetTheme.light')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _chooseWidgetTheme(context),
        ),
      ])),
      const SizedBox(height: 14),
      Card(child: Column(children: [
        ListTile(
          leading: const _SettingsIconBadge(icon: Icons.backup_outlined, color: QrFriColors.emerald),
          title: Text(context.qrL10n.t('settings.backup')),
          subtitle: Text(context.qrL10n.t('settings.backup.subtitle')),
          trailing: const Icon(Icons.upload_file),
          onTap: () => _export(context),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const _SettingsIconBadge(icon: Icons.restore, color: QrFriColors.emerald),
          title: Text(context.qrL10n.t('settings.restore')),
          subtitle: Text(context.qrL10n.t('settings.restore.subtitle')),
          trailing: const Icon(Icons.file_open),
          onTap: () => _import(context),
        ),
      ])),
      const SizedBox(height: 22),
      Center(child: Text('QRfri · 1.0.0', style: Theme.of(context).textTheme.bodySmall)),
    ],
  );

  Future<void> _chooseLanguage(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: (MediaQuery.of(sheetContext).size.height * .72).clamp(320.0, 620.0).toDouble(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 10), child: Align(alignment: Alignment.centerLeft, child: Text(context.qrL10n.t('language.dialog'), style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)))),
              for (final code in QrFriLocalizations.languageCodes)
                RadioListTile<String>(value: code, groupValue: store.languageCode, secondary: Text(context.qrL10n.languageFlag(code), style: const TextStyle(fontSize: 22)), title: Text(context.qrL10n.languageName(code)), onChanged: (value) => Navigator.pop(sheetContext, value)),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await store.setLanguage(selected);
  }

  Future<void> _chooseWidgetTheme(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), child: Align(alignment: Alignment.centerLeft, child: Text(sheetContext.qrL10n.t('settings.widgetTheme'), style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)))),
            RadioListTile<String>(value: 'light', groupValue: store.widgetTheme, secondary: const Icon(Icons.light_mode_outlined), title: Text(sheetContext.qrL10n.t('settings.widgetTheme.light')), onChanged: (value) => Navigator.pop(sheetContext, value)),
            RadioListTile<String>(value: 'black', groupValue: store.widgetTheme, secondary: const Icon(Icons.dark_mode_outlined), title: Text(sheetContext.qrL10n.t('settings.widgetTheme.black')), onChanged: (value) => Navigator.pop(sheetContext, value)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) await store.setWidgetTheme(selected);
  }

  Future<void> _export(BuildContext context) async {
    try {
      final file = await store.backup();
      final result = await Share.shareXFiles([XFile(file.path)], subject: 'Copia QRfri');
      if (context.mounted && result.status == ShareResultStatus.success) showQrToast(context, context.qrL10n.t('backup.exported'), kind: QrToastKind.success);
      if (context.mounted && result.status == ShareResultStatus.dismissed) showQrToast(context, context.qrL10n.t('backup.cancelled'), kind: QrToastKind.info);
      if (context.mounted && result.status == ShareResultStatus.unavailable) showQrToast(context, context.qrL10n.t('backup.generated'), kind: QrToastKind.info);
    } catch (_) {
      if (context.mounted) showQrToast(context, context.qrL10n.t('backup.exportError'), kind: QrToastKind.error);
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      final path = picked?.files.single.path;
      if (path == null) return;
      final confirmed = await showQrConfirmation(context, title: context.qrL10n.t('backup.confirm.title'), description: context.qrL10n.t('backup.confirm.description'), confirmLabel: context.qrL10n.t('common.restore'), icon: Icons.restore);
      if (confirmed != true || !context.mounted) return;
      await store.restore(path);
      if (context.mounted) showQrToast(context, context.qrL10n.t('backup.restored'), kind: QrToastKind.success);
    } catch (_) {
      if (context.mounted) showQrToast(context, context.qrL10n.t('backup.restoreError'), kind: QrToastKind.error);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary.withValues(alpha: .55)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
