import 'package:flutter/material.dart';
import 'strong_code_cache.dart';
import 'nav_state.dart';
import 'app_settings.dart';

class StrongCodePage extends StatefulWidget {
  final String code;
  const StrongCodePage({super.key, required this.code});

  static void navigate(BuildContext context, String code) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StrongCodePage(code: code)),
    );
  }

  @override
  State<StrongCodePage> createState() => _StrongCodePageState();
}

class _StrongCodePageState extends State<StrongCodePage> {
  bool _loading = true;
  String? _errorMsg;
  Map<String, dynamic>? _entry;
  List<String> _sampleKeys = [];

  String get _prefix => widget.code.toUpperCase().startsWith('G') ? 'G' : 'H';
  //  String get _langLabel => _prefix == 'G' ? '헬라어 (신약)' : '히브리어 (구약)';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await StrongCodeCache.load(_prefix);
      final codeUpper = widget.code.toUpperCase();
      final codeNum = widget.code.replaceAll(RegExp(r'[^0-9]'), '');

      String? foundKey;
      for (final k in data.keys) {
        if (k.toUpperCase() == codeUpper) {
          foundKey = k;
          break;
        }
      }
      if (foundKey == null && codeNum.isNotEmpty) {
        for (final k in data.keys) {
          if (k.replaceAll(RegExp(r'[^0-9]'), '') == codeNum) {
            foundKey = k;
            break;
          }
        }
      }
      if (foundKey != null) {
        final value = data[foundKey];
        setState(() {
          _entry = value is Map<String, dynamic>
              ? value
              : {'contents': value.toString()};
          _loading = false;
        });
      } else {
        setState(() {
          _sampleKeys = data.keys.take(10).toList();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  // 탭 선택 → navTabNotifier 설정 후 BibleHomePage로 이동
  void _onNavTap(int index) {
    onNavTap(context, index); // nav_state.dart의 안전한 함수 사용
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = _prefix == 'G'
        ? Colors.indigo[700]!
        : Colors.purple[700]!;

    return Scaffold(
      backgroundColor: context.isDark ? null : const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '항목 번호  ${widget.code.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            //  Text(
            //    _langLabel,
            //    style: const TextStyle(fontSize: 12, color: Colors.white70),
            //  ),
          ],
        ),
      ),
      body: _buildBody(appBarColor),
      bottomNavigationBar: AppBottomNav(
        currentIndex: navDict, // 용어사전에서 진입하는 경우가 많아 용어사전으로 표시
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildBody(Color accentColor) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMsg != null) {
      return _ErrorView(title: 'JSON 로드 오류', body: _errorMsg!);
    }
    if (_entry == null) {
      return _ErrorView(
        title: '코드를 찾지 못했습니다',
        body:
            '검색한 코드: ${widget.code.toUpperCase()}\n\n'
            'JSON 샘플 키:\n${_sampleKeys.join(', ')}',
      );
    }
    return _DetailView(
      code: widget.code.toUpperCase(),
      entry: _entry!,
      accentColor: accentColor,
      isGreek: _prefix == 'G',
    );
  }
}

class _DetailView extends StatelessWidget {
  final String code;
  final Map<String, dynamic> entry;
  final Color accentColor;
  final bool isGreek;

  const _DetailView({
    required this.code,
    required this.entry,
    required this.accentColor,
    required this.isGreek,
  });

  String _v(String key) => entry[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _v('no').isNotEmpty
                      ? _v('no')
                      : code.replaceAll(RegExp(r'[^0-9]'), ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Box(
                  label: '표제어',
                  accentColor: accentColor,
                  child: Text(
                    _v('word').isNotEmpty ? _v('word') : '-',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: isGreek ? null : 'EzraSIL',
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: isGreek ? TextAlign.left : TextAlign.right,
                    textDirection: isGreek
                        ? TextDirection.ltr
                        : TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Box(
                  label: 'title',
                  accentColor: accentColor,
                  child: Text(
                    _v('word2').isNotEmpty ? _v('word2') : '-',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontFamily: isGreek ? null : 'EzraSIL',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Box(
            label: 'contents',
            accentColor: accentColor,
            minHeight: 200,
            child: Text(
              _v('contents').isNotEmpty ? _v('contents') : '-',
              style: TextStyle(
                fontSize: 16,
                height: 1.7,
                fontFamily: isGreek ? null : 'EzraSIL',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String label;
  final Widget child;
  final Color accentColor;
  final double minHeight;

  const _Box({
    required this.label,
    required this.child,
    required this.accentColor,
    this.minHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String title;
  final String body;
  const _ErrorView({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.search_off, size: 72, color: Colors.purple[200]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.softBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderSoft),
            ),
            child: Text(
              body,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
