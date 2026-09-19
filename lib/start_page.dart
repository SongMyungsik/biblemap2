import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'nav_state.dart';
//import 'main.dart';

class StartPage extends StatelessWidget {
  // true: 홈 탭 안에 들어간 형태 (앱바 없음, 시작하기 → 성경 탭으로 이동)
  final bool embedded;
  const StartPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final content = Center(
      // Center 위젯의 자식으로 Column을 추가하여 위젯들을 세로로 배치합니다.
      child: Column(
        // Column의 자식들을 수직 중앙에 정렬합니다.
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 'The Bible' 텍스트를 추가하고 스타일을 적용합니다.
          Image.asset(
            'assets/images/top_image.png', // 이미지 경로
            width: 300, // 너비 조절
            height: 159, // 높이 조절
          ),
          const SizedBox(height: 30),
          const SizedBox(height: 30),
          // 텍스트와 버튼 사이에 간격을 줍니다.
          const SizedBox(height: 20),
          // 기존의 '시작하기' 버튼입니다.
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 0, 0), // 원하는 색상2
              foregroundColor: const Color.fromARGB(
                255,
                255,
                255,
                255,
              ), // 텍스트 색상2
            ),
            onPressed: () {
              if (embedded) {
                navTabNotifier.value = navBible;
              } else {
                Navigator.pushNamed(context, '/bible');
              }
            },
            child: const Text('시작하기'),
          ),
          const SizedBox(height: 40),
          Image.asset(
            'assets/images/top_image3.png', // 이미지 경로
            width: 180, // 너비 조절
            height: 47, // 높이 조절
          ),
          const SizedBox(height: 30),
          Text(
            'Visionbible ver. 3.0',
            style: TextStyle(
              fontSize: 12.0, // 글자 크기를 크게 설정
              //  fontWeight: FontWeight.bold,   // 글자를 굵게 설정
              color: context.textMain,
            ),
          ),
        ],
      ),
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('비전성경사전과 성경지도')),
      body: content,
    );
  }
}
