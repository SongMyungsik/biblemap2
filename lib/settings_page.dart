import 'package:flutter/material.dart';

import 'app_settings.dart';

// 설정 탭: 좌우 슬라이드로 '사용방법' / '설정' 전환
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.help_outline), text: '사용방법'),
                Tab(icon: Icon(Icons.tune), text: '설정'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [_UsageTab(), _SettingsTab()]),
          ),
        ],
      ),
    );
  }
}

// ── 사용방법 ───────────────────────────────────────
class _UsageTab extends StatelessWidget {
  const _UsageTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _UsageCard(
          icon: Icons.info_outline,
          title: '앱 소개',
          lines: [
            '이 앱은 두란노서원 발행 <간추린 비전성경사전>의 성경 용어 3,000여개를 수록하였으며, 그 중에서 500여개의 성경 지명을 구글지도에서 확인할 수 있습니다.',
          ],
        ),
        _UsageCard(
          icon: Icons.menu_book,
          title: '성경',
          lines: [
            '상단의 책·장 선택 메뉴에서 읽고 싶은 성경과 장을 고릅니다.',
            '슬라이더로 글자 크기를 조절할 수 있습니다.',
            '스피커 버튼을 누르면 해당 장을 음성으로 읽어 줍니다.',
            '좌우 화살표 버튼으로 이전 장·다음 장으로 이동합니다.',
            '본문의 H·G 번호나 보라색 밑줄 단어를 누르면 비전성경사전의 설명을 볼 수 있습니다.',
            '마지막으로 읽던 위치는 자동으로 기억됩니다.',
          ],
        ),
        _UsageCard(
          icon: Icons.search,
          title: '검색',
          lines: [
            '검색창에 단어를 입력하고 검색하면 성경 전체에서 해당 구절을 찾아 줍니다.',
            '검색된 단어는 본문에서 노란색으로 표시됩니다.',
            '검색 결과 건수가 상단에 표시됩니다.',
          ],
        ),
        _UsageCard(
          icon: Icons.sort_by_alpha,
          title: '용어사전',
          lines: [
            '비전성경사전의 성경 용어 3,000여 개를 그룹별로 찾아볼 수 있습니다.',
            '그룹을 선택한 뒤 검색창에서 용어·내용·발음으로 검색할 수 있습니다.',
            '용어를 누르면 상세 설명과 관련 항목을 볼 수 있습니다.',
          ],
        ),
        _UsageCard(
          icon: Icons.map,
          title: '지도',
          lines: [
            '화면 상단에서 좌우로 넘기거나 탭을 눌러 [성경 지도]와 [거리 계산]을 전환합니다.',
            '[성경 지도]: ㄱ·ㄴ·ㄷ… 초성 버튼을 누르고 지명을 고르면 지도에 위치가 표시됩니다.',
            '[거리 계산]: 첫 번째·두 번째 지명을 차례로 선택하면 두 지명 사이의 직선거리(km)가 지도에 표시됩니다.',
            '지도 위에서는 손가락으로 끌어서 이동하고, 두 손가락으로 확대·축소합니다.',
          ],
        ),
      ],
    );
  }
}

class _UsageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  const _UsageCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(line, style: const TextStyle(height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 설정 ───────────────────────────────────────────
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '화면모드',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '성경 본문 화면에만 적용됩니다.',
          style: TextStyle(fontSize: 12, color: context.textSub),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettings.themeMode,
          builder: (context, mode, _) => SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('시스템'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('라이트'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('다크'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => AppSettings.setThemeMode(s.first),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          '앱색상',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '상단 앱바와 하단 네비게이션의 색상이 바뀝니다.',
          style: TextStyle(fontSize: 12, color: context.textSub),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<Color>(
          valueListenable: AppSettings.appColor,
          builder: (context, current, _) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final item in appColorPalette)
                _ColorSwatch(
                  name: item.name,
                  color: item.color,
                  selected: item.color.toARGB32() == current.toARGB32(),
                  onTap: () => AppSettings.setAppColor(item.color),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorSwatch({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : context.borderSoft,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected ? Icon(Icons.check, color: onColor(color)) : null,
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
