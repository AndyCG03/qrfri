part of '../../app/app.dart';

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

