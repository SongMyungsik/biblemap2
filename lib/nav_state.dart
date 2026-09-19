import 'package:flutter/material.dart';

// 하위 페이지(VisionGroupPage, StrongCodePage)에서
// BibleHomePage의 탭을 바꾸기 위한 전역 상태
final navTabNotifier = ValueNotifier<int>(1);

// ✅ 안전한 네비 탭 이동 함수
// '/bible'을 못 찾아도 isFirst에서 멈춰 앱 중단 방지
void onNavTap(BuildContext context, int index) {
  navTabNotifier.value = index;
  Navigator.of(context).popUntil(
    (route) => route.isFirst || route.settings.name == '/bible',
  );
}