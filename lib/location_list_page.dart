import 'package:flutter/material.dart';

import 'map_page.dart';

// 초성 → 그룹 표제 (용어사전의 가/나/다… 그룹과 같은 표기)
const Map<String, String> _groupLabel = {
  'ㄱ': '가',
  'ㄲ': '가',
  'ㄴ': '나',
  'ㄷ': '다',
  'ㄸ': '다',
  'ㄹ': '라',
  'ㅁ': '마',
  'ㅂ': '바',
  'ㅃ': '바',
  'ㅅ': '사',
  'ㅆ': '사',
  'ㅇ': '아',
  'ㅈ': '자',
  'ㅉ': '자',
  'ㅊ': '차',
  'ㅋ': '카',
  'ㅌ': '타',
  'ㅍ': '파',
  'ㅎ': '하',
};

// 그룹별 지명 박스 색 (배경, 테두리) - 그룹 순서대로 돌아가며 사용
const List<({Color fill, Color border})> _boxColors = [
  (fill: Color(0xFFFFE9E0), border: Color(0xFFF2B49B)), // 살구
  (fill: Color(0xFFE3F2FD), border: Color(0xFF90C2EC)), // 하늘
  (fill: Color(0xFFE8F5E9), border: Color(0xFF9CCB9F)), // 연두
  (fill: Color(0xFFFFF6D6), border: Color(0xFFE6CC72)), // 노랑
  (fill: Color(0xFFF3E5F5), border: Color(0xFFCB9BD6)), // 연보라
  (fill: Color(0xFFE0F5F3), border: Color(0xFF86CBC4)), // 민트
  (fill: Color(0xFFFCE4EC), border: Color(0xFFEE9AB5)), // 분홍
  (fill: Color(0xFFEDE7F6), border: Color(0xFFB4A1D9)), // 라벤더
];

// 성경 지명 전체 목록: 가나다 그룹별로 지명(현 지명)을 나열하고,
// 지명을 누르면 성경 지도 화면에서 그 지명을 보여준다.
class LocationListPage extends StatefulWidget {
  final List<Location> locations;
  final ValueChanged<Location> onSelect;
  const LocationListPage({
    super.key,
    required this.locations,
    required this.onSelect,
  });

  @override
  State<LocationListPage> createState() => _LocationListPageState();
}

class _LocationListPageState extends State<LocationListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final List<MapEntry<String, List<Location>>> _groups = _buildGroups();
  // 그룹 표제 위치로 스크롤하기 위한 키
  late final Map<String, GlobalKey> _keys = {
    for (final g in _groups) g.key: GlobalKey(),
  };
  String? _selected;

  void _scrollTo(String label) {
    setState(() => _selected = label);
    final ctx = _keys[label]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<MapEntry<String, List<Location>>> _buildGroups() {
    final map = <String, List<Location>>{};
    for (final loc in widget.locations) {
      final initial = getInitialConsonant(loc.name.trim());
      final label = _groupLabel[initial] ?? initial;
      map.putIfAbsent(label, () => []).add(loc);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in entries) {
      e.value.sort((a, b) => a.name.compareTo(b.name));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _LetterBar(
          labels: [for (final g in _groups) g.key],
          selected: _selected,
          onTap: _scrollTo,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (gi, group) in _groups.indexed) ...[
                  _GroupHeader(
                    key: _keys[group.key],
                    label: group.key,
                    count: group.value.length,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final loc in group.value)
                        _LocationItem(
                          location: loc,
                          colors: _boxColors[gi % _boxColors.length],
                          onTap: () => widget.onSelect(loc),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 화면 맨 위에 고정된 가/나/다… 바로가기
class _LetterBar extends StatelessWidget {
  final List<String> labels;
  final String? selected;
  final ValueChanged<String> onTap;
  const _LetterBar({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: label == selected ? primary : Colors.white,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: label == selected ? primary : Colors.grey.shade400,
                    ),
                  ),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onTap(label),
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: label == selected ? Colors.white : primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 동그라미 안에 표제 글자 (손글씨 목록의 ㉮ ㉯ 표기처럼)
class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _GroupHeader({super.key, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count개',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _LocationItem extends StatelessWidget {
  final Location location;
  final ({Color fill, Color border}) colors;
  final VoidCallback onTap;
  const _LocationItem({
    required this.location,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: location.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (location.currentName.isNotEmpty)
                  TextSpan(
                    text: ' (${location.currentName})',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
