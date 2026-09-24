import 'package:flutter/material.dart';

import 'distance_page.dart';
import 'location_list_page.dart';
import 'map_page.dart';

// 지명(전체) / 성경 지도 / 거리 계산을 좌우 슬라이드로 전환하는 화면
class MapHubPage extends StatefulWidget {
  final List<Location> locations;
  const MapHubPage({super.key, required this.locations});

  @override
  State<MapHubPage> createState() => _MapHubPageState();
}

class _MapHubPageState extends State<MapHubPage>
    with SingleTickerProviderStateMixin {
  static const int _mapTabIndex = 1;

  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );
  // 지명(전체)에서 선택한 지명을 성경 지도에 전달
  final ValueNotifier<Location?> _focus = ValueNotifier<Location?>(null);

  @override
  void dispose() {
    _tabController.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _showOnMap(Location loc) {
    // 같은 지명을 다시 눌러도 알림이 가도록 null을 거친다
    _focus.value = null;
    _focus.value = loc;
    _tabController.animateTo(_mapTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '지명(전체)'),
              Tab(text: '성경 지도'),
              Tab(text: '거리 계산'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              LocationListPage(
                locations: widget.locations,
                onSelect: _showOnMap,
              ),
              MapPage(locations: widget.locations, focusRequest: _focus),
              DistancePage(locations: widget.locations),
            ],
          ),
        ),
      ],
    );
  }
}
