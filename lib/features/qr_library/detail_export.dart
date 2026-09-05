part of '../../app/app.dart';

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

