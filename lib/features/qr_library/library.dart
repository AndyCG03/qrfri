part of '../../app/app.dart';

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

