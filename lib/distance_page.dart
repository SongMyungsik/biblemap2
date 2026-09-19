import 'dart:math';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart'
    show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_page.dart'; // Location, getInitialConsonant 사용

class DistancePage extends StatefulWidget {
  final List<Location> locations;
  const DistancePage({super.key, required this.locations});

  @override
  State<DistancePage> createState() => _DistancePageState();
}

class _DistancePageState extends State<DistancePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Location? firstLocation;
  Location? secondLocation;
  double? distance;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  late GoogleMapController mapController;
  String? filterConsonant;
  bool selectingFirst = true; // true면 첫 번째 지명 선택 모드, false면 두 번째 지명 선택 모드

  List<Location> get filteredLocations {
    if (filterConsonant == null) return [];
    return widget.locations.where((loc) {
      final initial = getInitialConsonant(loc.name.trim());
      return initial == filterConsonant;
    }).toList();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // 지구 반지름 (km)
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void updateMap() {
    if (firstLocation != null && secondLocation != null) {
      setState(() {
        markers = {
          Marker(
            markerId: MarkerId(firstLocation!.id.toString()),
            position: LatLng(firstLocation!.lat, firstLocation!.lng),
            infoWindow: InfoWindow(title: firstLocation!.name),
          ),
          Marker(
            markerId: MarkerId(secondLocation!.id.toString()),
            position: LatLng(secondLocation!.lat, secondLocation!.lng),
            infoWindow: InfoWindow(title: secondLocation!.name),
          ),
        };

        polylines = {
          Polyline(
            polylineId: const PolylineId("line"),
            points: [
              LatLng(firstLocation!.lat, firstLocation!.lng),
              LatLng(secondLocation!.lat, secondLocation!.lng),
            ],
            color: Colors.red,
            width: 3,
          ),
        };

        distance = calculateDistance(
          firstLocation!.lat,
          firstLocation!.lng,
          secondLocation!.lat,
          secondLocation!.lng,
        );

        // ✅ mapController가 준비된 경우에만 실행
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                min(firstLocation!.lat, secondLocation!.lat),
                min(firstLocation!.lng, secondLocation!.lng),
              ),
              northeast: LatLng(
                max(firstLocation!.lat, secondLocation!.lat),
                max(firstLocation!.lng, secondLocation!.lng),
              ),
            ),
            50,
          ),
        );
      });
    }
  }

  void _showLocationMenu(BuildContext context) async {
    if (filteredLocations.isEmpty) return;
    final loc = await showMenu<Location>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 150, 100, 100),
      items: filteredLocations.map((loc) {
        return PopupMenuItem<Location>(
          value: loc,
          child: Text(
            loc.currentName.isNotEmpty
                ? "${loc.name} (${loc.currentName})"
                : loc.name,
          ),
        );
      }).toList(),
    );

    if (loc != null) {
      setState(() {
        if (selectingFirst) {
          firstLocation = loc;
        } else {
          secondLocation = loc;
        }
      });
      updateMap();
    }
  }

  // 지명이 선택되면 버튼을 진한 색으로 채우고 지명 이름을 표시한다.
  // active: 지금 지명을 고르는 중인 버튼 (테두리로 강조)
  Widget _buildSlotButton({
    required String emptyLabel,
    required Location? location,
    required Color color,
    required bool active,
    required VoidCallback onPressed,
  }) {
    final selected = location != null;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? color : null,
        foregroundColor: selected ? Colors.white : null,
        side: BorderSide(
          color: active ? color : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: Text(
        selected ? location.name : emptyLabel,
        style: TextStyle(fontWeight: selected ? FontWeight.bold : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final consonants = ["ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", "ㅇ", "ㅌ", "ㅎ"];

    return Column(
      children: [
        // 1지명/2지명 선택 모드 전환 버튼 (초성 버튼 위)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSlotButton(
              emptyLabel: '1지명',
              location: firstLocation,
              color: Colors.blue.shade700,
              active: selectingFirst,
              onPressed: () => setState(() => selectingFirst = true),
            ),
            const SizedBox(width: 10),
            _buildSlotButton(
              emptyLabel: '2지명',
              location: secondLocation,
              color: Colors.red.shade600,
              active: !selectingFirst,
              onPressed: () => setState(() => selectingFirst = false),
            ),
          ],
        ),

        // 초성 버튼
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: consonants.map((c) {
              return SizedBox(
                width: 32, // 40 → 32로 축소
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(32, 50), // 최소 크기 지정
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 축소
                    textStyle: const TextStyle(fontSize: 16), // 글씨 크기 축소
                  ),
                  onPressed: () {
                    setState(() {
                      filterConsonant = c;
                    });
                    _showLocationMenu(context);
                  },
                  child: Text(
                    c,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 선택된 지명 및 거리 표시 (한 줄, bold 처리)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (firstLocation != null &&
                  secondLocation != null &&
                  distance != null)
                Text(
                  "${firstLocation!.name} <--> ${secondLocation!.name} : ${distance!.toStringAsFixed(2)} km",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),

        // 지도
        Expanded(
          child: GoogleMap(
            // 지도를 끌 때 TabBarView 좌우 스와이프와 충돌하지 않도록 지도가 제스처를 우선 처리
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(32.75315, 35.27383),
              zoom: 7,
            ),
            markers: markers,
            polylines: polylines,
          ),
        ),
      ],
    );
  }
}
