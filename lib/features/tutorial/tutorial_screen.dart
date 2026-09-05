import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../design_system.dart';
import 'tutorial_data.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({
    super.key,
    required this.onCompleted,
    this.showSkipButton = true,
    this.languageCode = 'en',
  });

  final Future<void> Function() onCompleted;
  final bool showSkipButton;
  final String languageCode;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final PageController _pageController;
  late final List<TutorialPageData> _pages;
  int _currentPage = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = tutorialPagesFor(widget.languageCode);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onCompleted();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _complete();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  void _previous() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _pages.length - 1;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const QrFriLogo(height: 34),
                  if (widget.showSkipButton)
                    TextButton(
                      onPressed: _finishing ? null : _complete,
                      child: Text(_label('Skip', 'Omitir'), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 260, child: _TutorialLottie(asset: page.asset)),
                            const SizedBox(height: 20),
                            Text(page.title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 10),
                            Text(page.description, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage ? QrFriColors.indigo : QrFriColors.indigo.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _currentPage > 0 ? _previous : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(_label('Back', 'Atrás')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QrFriRadius.md)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _finishing ? null : _next,
                          icon: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 18),
                          label: Text(isLast ? _label('Get started', 'Comenzar') : _label('Next', 'Siguiente')),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QrFriRadius.md)),
                            elevation: 0,
                            textStyle: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(String english, String spanish) {
    if (widget.languageCode == 'es') return spanish;
    const labels = <String, List<String>>{
      'pt': ['Pular', 'Próximo', 'Começar'],
      'fr': ['Passer', 'Suivant', 'Commencer'],
      'zh': ['跳过', '下一步', '开始使用'],
      'de': ['Überspringen', 'Weiter', 'Loslegen'],
      'ja': ['スキップ', '次へ', '始める'],
      'ko': ['건너뛰기', '다음', '시작하기'],
      'it': ['Salta', 'Avanti', 'Inizia'],
      'ru': ['Пропустить', 'Далее', 'Начать'],
    };
    final values = labels[widget.languageCode];
    if (values == null) return english;
    return values[english == 'Skip' ? 0 : english == 'Next' ? 1 : 2];
  }
}

class _TutorialLottie extends StatelessWidget {
  const _TutorialLottie({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) => Lottie.asset(asset, fit: BoxFit.contain, repeat: false);
}
