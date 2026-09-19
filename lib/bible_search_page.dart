import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'app_settings.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BibleSearchPage  –  성경 본문 전체 검색
//   • 검색어가 포함된 구절을 책/장/절 형태로 표시
//   • 검색어를 노란색으로 하이라이트
//   • koreanbible.json을 자체 로드 (StrongCodeCache 방식)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class BibleSearchPage extends StatefulWidget {
  const BibleSearchPage({super.key});

  @override
  State<BibleSearchPage> createState() => _BibleSearchPageState();
}

class _BibleSearchPageState extends State<BibleSearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';
  List<dynamic> _allVerses = [];
  List<dynamic> _results = [];
  bool _searched = false;
  bool _loading = true;

  // ── 결과 제외 패턴 ──────────────────────────────────────────
  // 검색 결과 구절에 아래 패턴이 포함되면 결과에서 제외
  static final _excludePatterns = [
    RegExp(r'지\s*말고'),
    RegExp(r'도\s*말고'),
    RegExp(r'지\s*마라'),
    RegExp(r'지\s*마세요'),
    RegExp(r'지\s*마십시오'),
    RegExp(r'도\s*하지\s*마'),
  ];

  bool _shouldExclude(String verseText) {
    for (final pattern in _excludePatterns) {
      if (pattern.hasMatch(verseText)) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    try {
      final data = await rootBundle.loadString('assets/koreanbible.json');
      final decoded = json.decode(data) as List;
      if (mounted) {
        setState(() {
          _allVerses = decoded;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _doSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _query = '';
        _searched = false;
      });
      return;
    }

    final lower = query.toLowerCase();
    final results = _allVerses.where((v) {
      final text = (v['korean'] ?? '').toString();
      if (!text.toLowerCase().contains(lower)) return false;
      // 제외 패턴 포함 구절은 결과에서 제외
      if (_shouldExclude(text)) return false;
      return true;
    }).toList();
    setState(() {
      _query = query;
      _results = results;
      _searched = true;
    });
  }

  // 검색어 하이라이트 spans
  List<InlineSpan> _highlight(String text) {
    if (_query.isEmpty) return [TextSpan(text: text)];
    final spans = <InlineSpan>[];
    final lower = text.toLowerCase();
    final qLower = _query.toLowerCase();
    int cursor = 0;
    while (cursor < text.length) {
      final idx = lower.indexOf(qLower, cursor);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }
      if (idx > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + _query.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFE066),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
      cursor = idx + _query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── 검색창 ──────────────────────────────────────────
                Container(
                  color: const Color(0xFF5C3D99),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: TextField(
                    controller: _ctrl,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _doSearch,
                    decoration: InputDecoration(
                      hintText: '검색어를 입력하세요',
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: () {
                                _ctrl.clear();
                                _doSearch('');
                              },
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                              ),
                              onPressed: () => _doSearch(_ctrl.text),
                            ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setState(() {}), // suffixIcon 갱신용
                  ),
                ),

                // ── 결과 수 표시 ─────────────────────────────────────
                if (_searched)
                  Container(
                    width: double.infinity,
                    color: context.softBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Text(
                      _results.isEmpty
                          ? '"$_query" 검색 결과 없음'
                          : '"$_query"  검색 결과  ${_results.length}건',
                      style: TextStyle(
                        fontSize: 13,
                        color: _results.isEmpty
                            ? Colors.red.shade400
                            : context.textSub,
                      ),
                    ),
                  ),

                // ── 결과 목록 ─────────────────────────────────────────
                Expanded(
                  child: !_searched
                      ? _EmptyHint()
                      : _results.isEmpty
                      ? const Center(
                          child: Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 16),
                          itemBuilder: (context, i) {
                            final v = _results[i];
                            final book = v['book']?.toString() ?? '';
                            final chap = v['chapter']?.toString() ?? '';
                            final para = v['paragraph']?.toString() ?? '';
                            final text = v['korean']?.toString() ?? '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 책 장 절 레이블
                                  Text(
                                    '$book $chap:$para',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5C3D99),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // 본문 (검색어 하이라이트)
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: context.textMain,
                                        height: 1.5,
                                      ),
                                      children: _highlight(text),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ── 초기 안내 화면 ──────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '검색어를 입력하고\n엔터 또는 검색 버튼을 누르세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
