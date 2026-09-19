import 'package:flutter/material.dart';
import 'strong_code_cache.dart';
import 'strong_code_page.dart';
import 'nav_state.dart';

class _Group {
  final String label;
  final List<String> indices;
  const _Group(this.label, this.indices);
}

const _groups = [
  _Group('가', ['ㄱ']), _Group('나', ['ㄴ']), _Group('다', ['ㄷ']),
  _Group('라', ['ㄹ']), _Group('마', ['ㅁ']), _Group('바', ['ㅂ']),
  _Group('사', ['ㅅ']), _Group('아', ['ㅇ']), _Group('자', ['ㅈ']),
  _Group('차', ['ㅊ']), _Group('카', ['ㅋ']), _Group('타', ['ㅌ']),
  _Group('파', ['ㅍ']), _Group('하', ['ㅎ']),
];

String _chosung(String word) {
  if (word.isEmpty) return '';
  final code = word.codeUnitAt(0);
  if (code < 0xAC00 || code > 0xD7A3) return word[0];
  const initials = [
    'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ',
    'ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
  ];
  return initials[((code - 0xAC00) ~/ 28) ~/ 21];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VisionIndexPage — BottomNav 없음 (BibleHomePage IndexedStack 안)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VisionIndexPage extends StatefulWidget {
  const VisionIndexPage({super.key});
  @override
  State<VisionIndexPage> createState() => _VisionIndexPageState();
}

class _VisionIndexPageState extends State<VisionIndexPage> {
  bool _loading = true;
  List<CodeListEntry> _allList = [];
  final _ctrl = TextEditingController();
  String _query = '';
  String _searchMode = 'word';

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final hData = await StrongCodeCache.load('H');
      final gData = await StrongCodeCache.load('G');
      final list = <CodeListEntry>[];
      for (final src in [hData, gData]) {
        for (final key in src.keys) {
          final item = src[key];
          if (item is Map<String, dynamic>) {
            final numStr = key.replaceAll(RegExp(r'[^0-9]'), '');
            final num = int.tryParse(numStr) ?? 999999;
            list.add(CodeListEntry(
              code: key.toUpperCase(), number: num,
              word: item['word']?.toString() ?? '',
              word2: item['word2']?.toString() ?? '',
              contents: item['contents']?.toString() ?? '',
              pronunciation: item['pronunciation']?.toString() ?? '',
              korean: item['korean']?.toString() ?? '',
              times: item['times']?.toString() ?? '',
              no: item['no']?.toString() ?? num.toString(),
            ));
          }
        }
      }
      list.sort((a, b) => a.number.compareTo(b.number));
      if (mounted) {
        setState(() { _allList = list; _loading = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<CodeListEntry> get _filtered {
    if (_query.isEmpty) return _allList;
    final q = _query.trim().toLowerCase();
    return _allList.where((e) {
      if (_searchMode == 'word') {
        return e.word.toLowerCase().contains(q) ||
            e.word2.toLowerCase().contains(q) ||
            e.pronunciation.toLowerCase().contains(q);
      } else if (_searchMode == 'contents') {
        return e.contents.toLowerCase().contains(q);
      } else {
        return e.word.toLowerCase().contains(q) ||
            e.word2.toLowerCase().contains(q) ||
            e.contents.toLowerCase().contains(q) ||
            e.pronunciation.toLowerCase().contains(q);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _SearchBar(
                  ctrl: _ctrl, mode: _searchMode,
                  total: _allList.length, filtered: filtered.length,
                  onMode: (m) => setState(() => _searchMode = m),
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () { _ctrl.clear(); setState(() => _query = ''); },
                ),
                Expanded(
                  child: _query.isNotEmpty
                      ? _SearchResultList(
                          entries: filtered, query: _query, mode: _searchMode)
                      : _GroupGrid(allList: _allList),
                ),
              ],
            ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VisionGroupPage — BottomNav 5개
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VisionGroupPage extends StatefulWidget {
  final String groupLabel;
  final List<CodeListEntry> entries;
  const VisionGroupPage({
    super.key, required this.groupLabel, required this.entries,
  });

  @override
  State<VisionGroupPage> createState() => _VisionGroupPageState();
}

class _VisionGroupPageState extends State<VisionGroupPage> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _searchMode = 'word';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<CodeListEntry> get _filtered {
    if (_query.isEmpty) return widget.entries;
    final q = _query.trim().toLowerCase();
    return widget.entries.where((e) {
      if (_searchMode == 'word') {
        return e.word.toLowerCase().contains(q) ||
            e.word2.toLowerCase().contains(q) ||
            e.pronunciation.toLowerCase().contains(q);
      } else if (_searchMode == 'contents') {
        return e.contents.toLowerCase().contains(q);
      } else {
        return e.word.toLowerCase().contains(q) ||
            e.word2.toLowerCase().contains(q) ||
            e.contents.toLowerCase().contains(q) ||
            e.pronunciation.toLowerCase().contains(q);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C3D99),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '"${widget.groupLabel}" 그룹',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _SearchBar(
            ctrl: _ctrl, mode: _searchMode,
            total: widget.entries.length, filtered: filtered.length,
            onMode: (m) => setState(() => _searchMode = m),
            onChanged: (v) => setState(() => _query = v),
            onClear: () { _ctrl.clear(); setState(() => _query = ''); },
          ),
          Expanded(
            child: _SearchResultList(
              entries: filtered, query: _query, mode: _searchMode),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),          label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book),     label: '개역개정'),
          BottomNavigationBarItem(icon: Icon(Icons.search),        label: '성경검색'),
          BottomNavigationBarItem(icon: Icon(Icons.sort_by_alpha), label: '용어목록'),
          BottomNavigationBarItem(icon: Icon(Icons.map),           label: '성경지도'),
          BottomNavigationBarItem(icon: Icon(Icons.straighten),    label: '거리계산'),
        ],
        currentIndex: 3,
        // ✅ isFirst 조건 추가 → '/bible'을 못 찾아도 앱 중단 없음
        onTap: (index) => onNavTap(context, index),
        selectedItemColor: const Color.fromARGB(255, 255, 53, 53),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 공통 위젯: 검색바
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final String mode;
  final int total, filtered;
  final ValueChanged<String> onMode, onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.ctrl, required this.mode,
    required this.total, required this.filtered,
    required this.onMode, required this.onChanged, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _ModeChip(label: '표제어', selected: mode == 'word',
                onTap: () => onMode('word')),
            const SizedBox(width: 8),
            _ModeChip(label: '내용', selected: mode == 'contents',
                onTap: () => onMode('contents')),
            const SizedBox(width: 8),
            _ModeChip(label: '전체', selected: mode == 'all',
                onTap: () => onMode('all')),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl, onChanged: onChanged,
            decoration: InputDecoration(
              hintText: mode == 'word'
                  ? '표제어 검색'
                  : mode == 'contents' ? '내용 검색' : '전체 검색',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF5C3D99)),
              suffixIcon: ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClear)
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFF5C3D99)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                    color: Color(0xFF5C3D99), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 6),
          Text('$filtered / $total 건',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 공통 위젯: 검색 결과 목록
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SearchResultList extends StatelessWidget {
  final List<CodeListEntry> entries;
  final String query, mode;
  const _SearchResultList({
    required this.entries, required this.query, required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
          child: Text('검색 결과가 없습니다.',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, i) {
        final e = entries[i];
        return InkWell(
          onTap: () => StrongCodePage.navigate(context, e.no),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(e.no, style: TextStyle(
                      fontSize: e.no.length > 3 ? 10 : 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: e.word.isNotEmpty ? e.word : '-',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        if (e.word2.isNotEmpty)
                          TextSpan(
                            text: '  |  ${e.word2}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600],
                                fontWeight: FontWeight.normal),
                          ),
                      ],
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 공통 위젯: 자음 그리드
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _GroupGrid extends StatelessWidget {
  final List<CodeListEntry> allList;
  const _GroupGrid({required this.allList});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, mainAxisSpacing: 10,
          crossAxisSpacing: 10, childAspectRatio: 1.6,
        ),
        itemCount: _groups.length,
        itemBuilder: (context, i) {
          final group = _groups[i];
          final groupEntries = allList
              .where((e) => group.indices.contains(_chosung(e.word)))
              .toList();
          final count = groupEntries.length;
          return GestureDetector(
            onTap: count == 0 ? null : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VisionGroupPage(
                  groupLabel: group.label, entries: groupEntries,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: count == 0
                    ? Colors.grey[100]
                    : Colors.purple.withValues(alpha: 0.12),
                border: Border.all(
                  color: count == 0
                      ? Colors.grey.shade300
                      : Colors.purple.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(group.label, style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: count == 0
                          ? Colors.grey[400] : Colors.purple[700],
                    )),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 5, top: 4,
                      child: Text('$count', style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple.withValues(alpha: 0.7),
                      )),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 공통 위젯: 모드 선택 칩
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5C3D99) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF5C3D99) : Colors.grey.shade300,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.white : Colors.grey.shade700,
        )),
      ),
    );
  }
}