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
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../design_system.dart';
import '../localization.dart';
import '../features/tutorial/tutorial_screen.dart';

part '../core/qr/qr_payload.dart';
part '../core/storage/local_store.dart';
part '../features/home/home_shell.dart';
part '../features/qr_creation/editor_design.dart';
part '../features/qr_library/library.dart';
part '../features/qr_library/qr_visual.dart';
part '../features/qr_library/detail_export.dart';
part '../features/qr_scanner/scanner.dart';
part '../features/settings/settings.dart';

const _widgetChannel = MethodChannel('com.qrfri.app/widget');
final ValueNotifier<String?> _widgetAction = ValueNotifier<String?>(null);

Future<void> bootstrap() async {
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

