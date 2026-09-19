import 'package:flutter/material.dart';

// 하위 페이지(VisionGroupPage, StrongCodePage)에서
// BibleHomePage의 탭을 바꾸기 위한 전역 상태
final navTabNotifier = ValueNotifier<int>(1);

// 하단 네비 탭 인덱스
const int navHome = 0;
const int navBible = 1;
const int navSearch = 2;
const int navDict = 3;
const int navMap = 4;
const int navSettings = 5;

// ✅ 안전한 네비 탭 이동 함수
// '/bible'을 못 찾아도 isFirst에서 멈춰 앱 중단 방지
void onNavTap(BuildContext context, int index) {
  navTabNotifier.value = index;
  Navigator.of(context).popUntil(
    (route) => route.isFirst || route.settings.name == '/bible',
  );
}

// 모든 화면이 공유하는 하단 네비 (색상은 Theme의 bottomNavigationBarTheme)
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '성경'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
        BottomNavigationBarItem(icon: Icon(Icons.sort_by_alpha), label: '용어사전'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
      ],
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}
