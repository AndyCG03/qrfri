part of '../../app/app.dart';

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
        SwitchListTile(
          value: store.widgetTheme == 'black',
          onChanged: (dark) => store.setWidgetTheme(dark ? 'black' : 'light'),
          title: Text(context.qrL10n.t('settings.widgetTheme')),
          subtitle: Text(store.widgetTheme == 'black' ? context.qrL10n.t('settings.widgetTheme.black') : context.qrL10n.t('settings.widgetTheme.light')),
          secondary: const _SettingsIconBadge(icon: Icons.widgets_outlined, color: QrFriColors.indigo),
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
