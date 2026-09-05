part of '../../app/app.dart';

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

