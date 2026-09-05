part of '../../app/app.dart';

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

