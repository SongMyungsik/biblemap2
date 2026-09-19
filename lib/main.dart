import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import 'book_map.dart';
import 'chapter.dart';
import 'start_page.dart';
import 'bible_search_page.dart';
import 'strong_code_cache.dart';
import 'strong_code_page.dart';
import 'vision_index_page.dart';
import 'map_page.dart';
import 'map_hub_page.dart';
import 'settings_page.dart';
import 'app_settings.dart';
import 'nav_state.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  main
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  final String jsonString = await rootBundle.loadString('assets/location.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  final List<Location> locations = jsonList
      .map((e) => Location.fromJson(e))
      .toList();
  runApp(BibleApp(locations: locations));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BibleApp
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class BibleApp extends StatelessWidget {
  final List<Location> locations;
  const BibleApp({super.key, required this.locations});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.appColor,
      builder: (context, _) => MaterialApp(
        title: '비전성경',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(AppSettings.appColor.value, Brightness.light),
        home: const StartPage(),
        onGenerateRoute: (settings) {
          if (settings.name == '/bible') {
            return MaterialPageRoute(
              settings: settings, // ✅ '/bible' 이름 보존 → popUntil 정상 동작
              builder: (_) => BibleHomePage(locations: locations),
            );
          }
          return null;
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  스트롱 코드 파서
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final _strongCodeRegex = RegExp(r'\b[HG]\d+\b', caseSensitive: false);

List<({bool isCode, String text})> parseVerseText(String verse) {
  final result = <({bool isCode, String text})>[];
  int cursor = 0;
  for (final match in _strongCodeRegex.allMatches(verse)) {
    if (match.start > cursor) {
      result.add((isCode: false, text: verse.substring(cursor, match.start)));
    }
    result.add((isCode: true, text: match.group(0)!.toUpperCase()));
    cursor = match.end;
  }
  if (cursor < verse.length) {
    result.add((isCode: false, text: verse.substring(cursor)));
  }
  return result;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BibleHomePage
//
//  핵심 구조:
//  - index 1 (개역개정): build()에서 직접 렌더링
//    → setState() 호출 시 즉시 반영됨 (데이터 없음 문제 해결)
//  - index 0,2,3,4: IndexedStack으로 상태 유지
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class BibleHomePage extends StatefulWidget {
  final List<Location> locations;
  const BibleHomePage({super.key, required this.locations});

  @override
  State<BibleHomePage> createState() => _BibleHomePageState();
}

class _BibleHomePageState extends State<BibleHomePage> {
  int _selectedIndex = 1;

  // 개역개정(1) 제외한 5개 탭만 IndexedStack으로 관리
  // _otherPages 인덱스 매핑:
  //   selectedIndex 0 → _otherPages[0] (홈)
  //   selectedIndex 2 → _otherPages[1] (성경검색)
  //   selectedIndex 3 → _otherPages[2] (용어목록)
  //   selectedIndex 4 → _otherPages[3] (지도: 성경지도/거리계산 슬라이드)
  //   selectedIndex 5 → _otherPages[4] (설정: 사용방법/설정 슬라이드)
  late final List<Widget> _otherPages;

  int get _otherPagesIndex {
    switch (_selectedIndex) {
      case 0:
        return 0;
      case 2:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      case 5:
        return 4;
      default:
        return 0;
    }
  }

  // ── 성경 본문 상태 ──────────────────────────────
  String selectedBook = bookList.first;
  int selectedChapter = 1;
  List<dynamic> allVerses = [];
  Map<String, String> _dictMap = {};
  List<String> _dictWords = [];
  List<String> verses = [];
  double fontSize = 18.0;
  bool isLoading = false;

  bool _isReading = false;
  bool _isTtsBusy = false;
  int? _readingVerseIndex;

  final FlutterTts flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _otherPages = [
      const StartPage(embedded: true), // 0
      const BibleSearchPage(), // 1 (selectedIndex 2)
      const VisionIndexPage(), // 2 (selectedIndex 3)
      MapHubPage(locations: widget.locations), // 3 (selectedIndex 4)
      const SettingsPage(), // 4 (selectedIndex 5)
    ];
    _initTts();
    _loadLastPosition();

    // 하위 페이지(VisionGroupPage, StrongCodePage)에서
    // 탭 선택 시 이 페이지의 _selectedIndex를 업데이트
    navTabNotifier.addListener(_onNavTabChanged);
  }

  void _onNavTabChanged() {
    if (mounted) {
      setState(() => _selectedIndex = navTabNotifier.value);
    }
  }

  @override
  void dispose() {
    navTabNotifier.removeListener(_onNavTabChanged);
    flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  // ── AppBar ──────────────────────────────────────
  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return '비전성경사전';
      case 1:
        return '성경';
      case 2:
        return '성경 검색';
      case 3:
        return '용어사전';
      case 4:
        return '지도';
      case 5:
        return '설정';
      default:
        return '비전성경사전';
    }
  }

  // ── 탭 선택 ─────────────────────────────────────
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ── TTS ─────────────────────────────────────────
  Future<void> _initTts() async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stopAll() async {
    await flutterTts.stop();
    if (mounted) {
      setState(() {
        _isReading = false;
        _isTtsBusy = false;
        _readingVerseIndex = null;
      });
    }
  }

  Future<void> _startChapterReading() async {
    if (verses.isEmpty) return;
    await flutterTts.setLanguage('ko-KR');
    for (int i = 0; i < verses.length; i++) {
      if (!_isReading || !mounted) break;
      final plain = verses[i]
          .replaceFirst(RegExp(r'^\d+\.\s?'), '')
          .replaceAll(_strongCodeRegex, '');
      setState(() {
        _isTtsBusy = false;
        _readingVerseIndex = i;
      });
      await flutterTts.speak(plain);
      if (_isReading && i < verses.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (mounted) _stopAll();
  }

  void _toggleChapterReading() {
    if (_isReading) {
      _stopAll();
    } else {
      setState(() {
        _isReading = true;
        _isTtsBusy = true;
      });
      _startChapterReading();
    }
  }

  // ── 데이터 로드 ──────────────────────────────────
  Future<void> _loadLastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final book = prefs.getString('last_book');
      final chapter = prefs.getInt('last_chapter') ?? 1;
      if (book != null && bookList.contains(book)) {
        selectedBook = book;
        selectedChapter = chapter;
      }
    } catch (_) {}
    await loadBibleData();
  }

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_book', selectedBook);
    await prefs.setInt('last_chapter', selectedChapter);
  }

  Future<void> loadBibleData() async {
    try {
      final dictData = await StrongCodeCache.load('H');
      final map = <String, String>{};
      for (final key in dictData.keys) {
        final item = dictData[key];
        if (item is Map<String, dynamic>) {
          final word = item['word']?.toString() ?? '';
          final no = item['no']?.toString() ?? key;
          if (word.isNotEmpty) map[word] = no;
        }
      }
      final words = map.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      if (mounted) {
        setState(() {
          _dictMap = map;
          _dictWords = words;
        });
      }
    } catch (_) {}

    try {
      final data = await rootBundle.loadString('assets/koreanbible.json');
      final decoded = json.decode(data) as List;
      if (mounted) {
        setState(() {
          allVerses = decoded;
          loadVerses();
        });
      }
    } catch (e) {
      // 성경 데이터 로드 실패
    }
  }

  void loadVerses() {
    if (mounted) {
      setState(() {
        verses = allVerses
            .where(
              (v) =>
                  v['book'] == selectedBook &&
                  v['chapter'].toString() == selectedChapter.toString(),
            )
            .map<String>(
              (v) => '${v['paragraph']}. ${v['korean'] ?? '[본문 없음]'}',
            )
            .toList();
      });
    }
  }

  void onBookChanged(String? value) {
    if (value != null) {
      _stopAll();
      setState(() {
        selectedBook = value;
        selectedChapter = 1;
        loadVerses();
      });
      _saveLastPosition();
    }
  }

  void onChapterChanged(int? value) {
    if (value != null) {
      _stopAll();
      setState(() {
        selectedChapter = value;
        loadVerses();
      });
      _saveLastPosition();
    }
  }

  void changeChapter(int diff) {
    final chapterLen = chapterCount[selectedBook]?.length ?? 1;
    _stopAll();
    setState(() {
      selectedChapter = (selectedChapter + diff).clamp(1, chapterLen);
      loadVerses();
    });
    _saveLastPosition();
  }

  // ── RichText 렌더링 ───────────────────────────────
  Widget _buildVerseRichText(BuildContext ctx, String verseText, int idx) {
    final isHighlighted = _readingVerseIndex == idx;
    final parts = parseVerseText(verseText);
    final spans = <InlineSpan>[];
    for (final part in parts) {
      if (!part.isCode) {
        spans.addAll(_buildDictSpans(part.text, fontSize, isHighlighted, ctx));
      } else {
        final code = part.text;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => StrongCodePage.navigate(ctx, code),
              child: _buildCodeChip(code, isHighlighted),
            ),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
      child: RichText(text: TextSpan(children: spans)),
    );
  }

  bool _isExcludedContext(String text, int cursor) {
    final start = (cursor - 6).clamp(0, cursor);
    final before = text.substring(start, cursor);
    return RegExp(r'[지도]\s*$').hasMatch(before);
  }

  List<InlineSpan> _buildDictSpans(
    String text,
    double fontSize,
    bool isHighlighted,
    BuildContext ctx,
  ) {
    if (_dictWords.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            color: isHighlighted ? Colors.black87 : ctx.textMain,
            backgroundColor: isHighlighted ? Colors.yellow[200] : null,
            height: 1.6,
          ),
        ),
      ];
    }
    bool isWordChar(int cp) =>
        (cp >= 0xAC00 && cp <= 0xD7A3) ||
        (cp >= 0x3131 && cp <= 0x318E) ||
        (cp >= 0x41 && cp <= 0x5A) ||
        (cp >= 0x61 && cp <= 0x7A);
    const particleSet = <int>{
      0xC774,
      0xAC00,
      0xC744,
      0xB97C,
      0xC758,
      0xC5D0,
      0xC640,
      0xACFC,
      0xB3C4,
      0xB9CC,
      0xC740,
      0xB294,
      0xB85C,
      0xC73C,
      0xB098,
      0xC57C,
      0xB77C,
      0xBA70,
      0xACE0,
      0xC11C,
      0xAED0,
      0xBD80,
      0xAE4C,
      0xCC98,
      0xBCF4,
      0xB9C8,
    };
    final spans = <InlineSpan>[];
    int cursor = 0;
    while (cursor < text.length) {
      String? matched;
      String? matchedNo;
      for (final word in _dictWords) {
        final end = cursor + word.length;
        if (end > text.length) continue;
        if (text.substring(cursor, end) != word) continue;
        if (cursor > 0 && isWordChar(text.codeUnitAt(cursor - 1))) continue;
        if (end < text.length) {
          final nextCp = text.codeUnitAt(end);
          if (isWordChar(nextCp) && !particleSet.contains(nextCp)) continue;
        }
        if (_isExcludedContext(text, cursor)) continue;
        matched = word;
        matchedNo = _dictMap[word];
        break;
      }
      if (matched != null && matchedNo != null) {
        final capturedNo = matchedNo;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => StrongCodePage.navigate(ctx, capturedNo),
              child: Text(
                matched,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted
                      ? Colors.purple[700]
                      : (ctx.isDark ? Colors.purple[200] : Colors.purple[700]),
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.purple[300],
                  backgroundColor: isHighlighted ? Colors.yellow[200] : null,
                  height: 1.6,
                ),
              ),
            ),
          ),
        );
        cursor += matched.length;
      } else {
        spans.add(
          TextSpan(
            text: text[cursor],
            style: TextStyle(
              fontSize: fontSize,
              color: isHighlighted ? Colors.black87 : ctx.textMain,
              backgroundColor: isHighlighted ? Colors.yellow[200] : null,
              height: 1.6,
            ),
          ),
        );
        cursor++;
      }
    }
    return spans;
  }

  Widget _buildCodeChip(String code, bool isHighlighted) {
    final isGreek = code.toUpperCase().startsWith('G');
    final chipColor = isHighlighted
        ? Colors.orange[100]!
        : isGreek
        ? Colors.indigo[100]!
        : Colors.purple[100]!;
    final borderColor = isHighlighted
        ? Colors.orange.shade400
        : isGreek
        ? Colors.indigo.shade300
        : Colors.purple.shade300;
    final textColor = isHighlighted
        ? Colors.orange[900]!
        : isGreek
        ? Colors.indigo[800]!
        : Colors.purple[800]!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: chipColor,
        border: Border.all(color: borderColor, width: 0.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.bold,
          height: 1.1,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // 다크 모드는 성경 본문 화면에만 적용한다 (다른 화면은 항상 라이트)
  Widget _buildThemedBibleBody() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) {
        final dark =
            mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        if (!dark) return _buildBibleBody();
        return Theme(
          data: buildAppTheme(AppSettings.appColor.value, Brightness.dark),
          child: Builder(
            builder: (ctx) => ColoredBox(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              child: _buildBibleBody(),
            ),
          ),
        );
      },
    );
  }

  // ── 개역개정 본문 위젯 (build()에서 직접 호출) ────
  // StatefulBuilder 없이 직접 렌더링 → setState() 즉시 반영
  Widget _buildBibleBody() {
    return SafeArea(
      child: Stack(
        children: [
          _buildBibleColumn(),
          // 장 이동: 반투명 플로팅 버튼 (하단 네비 바로 위, 좌우)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildFloatingChapterButton(
              icon: Icons.arrow_back_ios_new,
              color: Colors.blue,
              onPressed: () => changeChapter(-1),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildFloatingChapterButton(
              icon: Icons.arrow_forward_ios,
              color: Colors.red,
              onPressed: () => changeChapter(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingChapterButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // 구약(창세기~말라기) / 신약(마태복음~요한계시록)
  static const int _ntStartIndex = 39; // bookList에서 '마태복음'의 위치

  bool get _isNewTestament => bookList.indexOf(selectedBook) >= _ntStartIndex;

  List<String> get _testamentBooks => _isNewTestament
      ? bookList.sublist(_ntStartIndex)
      : bookList.sublist(0, _ntStartIndex);

  void _selectTestament({required bool isNt}) {
    if (_isNewTestament == isNt) return;
    _stopAll();
    setState(() {
      selectedBook = bookList[isNt ? _ntStartIndex : 0]; // 마태복음 / 창세기
      selectedChapter = 1;
      loadVerses();
    });
    _saveLastPosition();
  }

  Widget _buildTestamentButton(String label, {required bool isNt}) {
    final selected = _isNewTestament == isNt;
    return ElevatedButton(
      onPressed: () => _selectTestament(isNt: isNt),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(44, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: selected ? Colors.purple : null,
        foregroundColor: selected ? Colors.white : null,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildBibleColumn() {
    return Column(
      children: [
        // 상단 컨트롤 바
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            children: [
              _buildTestamentButton('구약', isNt: false),
              const SizedBox(width: 6),
              _buildTestamentButton('신약', isNt: true),
              Expanded(
                child: Slider(
                  min: 12,
                  max: 32,
                  divisions: 20,
                  label: fontSize.toStringAsFixed(0),
                  value: fontSize,
                  onChanged: (val) => setState(() => fontSize = val),
                ),
              ),
              Text(
                fontSize.toStringAsFixed(0),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _toggleChapterReading,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor: _isReading ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(36, 36),
                ),
                child: _isReading
                    ? const Icon(Icons.stop, size: 20)
                    : _isTtsBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.volume_up, size: 20),
              ),
            ],
          ),
        ),
        // 책 / 장 드롭다운
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(selectedBook),
                    initialValue: selectedBook,
                    items: _testamentBooks
                        .map(
                          (book) =>
                              DropdownMenuItem(value: book, child: Text(book)),
                        )
                        .toList(),
                    onChanged: onBookChanged,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    dropdownColor: const Color.fromARGB(255, 194, 195, 250),
                    iconEnabledColor: Colors.black54,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 194, 195, 250),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('$selectedBook-$selectedChapter'),
                    initialValue: selectedChapter,
                    items: (chapterCount[selectedBook] ?? [1])
                        .map(
                          (ch) =>
                              DropdownMenuItem(value: ch, child: Text('$ch장')),
                        )
                        .toList(),
                    onChanged: onChapterChanged,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    dropdownColor: const Color.fromARGB(255, 193, 255, 193),
                    iconEnabledColor: Colors.black54,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 193, 255, 193),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // 성경 본문
        Expanded(
          child: verses.isEmpty
              ? Center(
                  child: Text('데이터 없음', style: TextStyle(fontSize: fontSize)),
                )
              : ListView.builder(
                  key: ValueKey('$selectedBook-$selectedChapter'),
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: verses.length,
                  itemBuilder: (context, idx) =>
                      _buildVerseRichText(context, verses[idx], idx),
                ),
        ),
      ],
    );
  }

  // ── build ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: _selectedIndex == 1
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Image.asset(
                    'assets/images/church_logo.png',
                    width: 110,
                    height: 32,
                  ),
                ),
              ]
            : null,
      ),

      // ── body: 개역개정(1)은 직접 렌더, 나머지는 IndexedStack
      body: _selectedIndex == 1
          ? _buildThemedBibleBody()
          : IndexedStack(index: _otherPagesIndex, children: _otherPages),

      // ── BottomNav: 항상 6개 고정 ─────────────────
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
