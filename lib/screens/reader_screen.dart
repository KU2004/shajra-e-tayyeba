import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/reader_pdf_view.dart';

enum ReaderLanguage { urdu, hindi }

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.language});

  final ReaderLanguage language;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  static const _pdfAsset = 'assets/pdf/urdu_book.pdf';

  int _currentPage = 1;
  int? _pageCount;
  final int _fitToScreenSignal = 0;
  bool _documentLoaded = false;
  Object? _loadingError;
  final Set<int> _bookmarkedPages = <int>{};

  void _goToPage(int page) {
    final pageCount = _pageCount;
    if (page < 1 ||
        (pageCount != null && page > pageCount) ||
        page == _currentPage) {
      return;
    }
    setState(() => _currentPage = page);
  }

  Future<void> _searchPages() async {
    if (!_documentLoaded || _pageCount == null) return;

    final pageController = TextEditingController();
    final page = await showDialog<int>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 320,
          child: Container(
            color: const Color(0xFFFFC400),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox.square(
                      dimension: 72,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFF3D3320),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: 'Close search',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'GO TO PAGE*',
                  style: TextStyle(
                    color: Color(0xFF3D3320),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pageController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.go,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'eg 123',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.38),
                            fontSize: 11,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) =>
                            Navigator.of(dialogContext)
                                .pop(int.tryParse(pageController.text.trim())),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 30,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(dialogContext)
                                .pop(int.tryParse(pageController.text.trim())),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF078A43),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'GO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    pageController.dispose();

    if (!mounted || page == null) return;
    if (page < 1 || page > _pageCount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a page from 1 to $_pageCount.')),
      );
      return;
    }
    _goToPage(page);
  }

  void _toggleBookmark() {
    final wasBookmarked = _bookmarkedPages.remove(_currentPage);
    if (!wasBookmarked) {
      _bookmarkedPages.add(_currentPage);
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasBookmarked
              ? 'Removed bookmark from page $_currentPage.'
              : 'Bookmarked page $_currentPage.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F6),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _ReaderHeader(
              onHome: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              onSearch: _searchPages,
              onBookmark: _toggleBookmark,
              isBookmarked: _bookmarkedPages.contains(_currentPage),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Stack(
                      children: [
                        ReaderPdfView(
                          assetPath: _pdfAsset,
                          requestedPage: _currentPage,
                          fitToScreenSignal: _fitToScreenSignal,
                          onDocumentLoaded: (pageCount) {
                            if (!mounted) return;
                            setState(() {
                              _pageCount = pageCount == 0 ? null : pageCount;
                              _documentLoaded = true;
                              _loadingError = null;
                            });
                          },
                          onDocumentError: (error) {
                            if (mounted) {
                              setState(() {
                                _documentLoaded = false;
                                _loadingError = error;
                              });
                            }
                          },
                          onPageChanged: (page) {
                            if (mounted && page != _currentPage) {
                              setState(() => _currentPage = page);
                            }
                          },
                        ),
                        if (_loadingError != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Could not load the PDF.\n$_loadingError',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _PageControls(
              currentPage: _currentPage,
              pageCount: _pageCount,
              documentLoaded: _documentLoaded,
              onPrevious: () => _goToPage(_currentPage - 1),
              onNext: () => _goToPage(_currentPage + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.onHome,
    required this.onSearch,
    required this.onBookmark,
    required this.isBookmarked,
  });

  final VoidCallback onHome;
  final VoidCallback onSearch;
  final VoidCallback onBookmark;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconButtonSize = constraints.maxWidth < 360 ? 30.0 : 32.0;

        return ColoredBox(
          color: const Color(0xFFF2C94C),
          child: SizedBox(
            height: 72,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 7,
                    child: SizedBox(
                      width: 72,
                      height: 60,
                      child: Image.asset(
                        'assets/images/Icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 112,
                        height: 52,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 20,
                    child: Row(
                      children: [
                        _ReaderHeaderIcon(
                          icon: Icons.home_outlined,
                          size: iconButtonSize,
                          tooltip: 'Home',
                          onPressed: onHome,
                        ),
                        const SizedBox(width: 6),
                        _ReaderHeaderIcon(
                          icon: Icons.search,
                          size: iconButtonSize,
                          tooltip: 'Search',
                          onPressed: onSearch,
                        ),
                        const SizedBox(width: 4),
                        _ReaderHeaderIcon(
                          icon: isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: iconButtonSize,
                          tooltip: isBookmarked
                              ? 'Remove bookmark'
                              : 'Bookmark page',
                          onPressed: onBookmark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReaderHeaderIcon extends StatelessWidget {
  const _ReaderHeaderIcon({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, size: 25, color: const Color(0xFF3D3320)),
      ),
    );
  }
}

class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.currentPage,
    required this.pageCount,
    required this.documentLoaded,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int? pageCount;
  final bool documentLoaded;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final hasDocument = documentLoaded;
    return Material(
      color: const Color(0xFFF2C94C),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 6, 28, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PageButton(
              icon: Icons.arrow_upward,
              tooltip: 'Previous page',
              onPressed: hasDocument && currentPage > 1 ? onPrevious : null,
            ),
            Text(
              '$currentPage / ${pageCount ?? '...'}',
              style: const TextStyle(
                color: Color(0xFF241E13),
                fontWeight: FontWeight.w700,
              ),
            ),
            _PageButton(
              icon: Icons.arrow_downward,
              tooltip: 'Next page',
              onPressed:
                  hasDocument && (pageCount == null || currentPage < pageCount!)
                  ? onNext
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFFFF4D6),
          foregroundColor: const Color(0xFF3D3320),
          disabledBackgroundColor: const Color(0xFFE6D995),
          disabledForegroundColor: const Color(0xFF9B8E63),
          shape: const CircleBorder(),
        ),
        icon: Icon(icon, size: 25),
      ),
    );
  }
}
