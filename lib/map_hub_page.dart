import 'package:flutter/material.dart';

import 'distance_page.dart';
import 'map_page.dart';

// 성경 지명 지도 + 지명 거리 계산을 좌우 슬라이드로 전환하는 화면
class MapHubPage extends StatelessWidget {
  final List<Location> locations;
  const MapHubPage({super.key, required this.locations});

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
                Tab(icon: Icon(Icons.map), text: '성경 지도'),
                Tab(icon: Icon(Icons.straighten), text: '거리 계산'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                MapPage(locations: locations),
                DistancePage(locations: locations),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
