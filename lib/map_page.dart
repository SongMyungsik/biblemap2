//import 'dart:convert';
import 'package:flutter/foundation.dart'
    show
        Factory,
        TargetPlatform,
        ValueListenable,
        defaultTargetPlatform,
        kIsWeb;
import 'package:flutter/gestures.dart'
    show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Location {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final String currentName;

  Location({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.currentName,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['순번'],
      name: json['지명'],
      lat: json['위도'],
      lng: json['경도'],
      currentName: json['현 지명'],
    );
  }
}

String getInitialConsonant(String text) {
  if (text.isEmpty) return "";
  int codeUnit = text.codeUnitAt(0);
  if (codeUnit < 0xAC00 || codeUnit > 0xD7A3) return text[0];
  int code = codeUnit - 0xAC00;
  int choIndex = code ~/ (21 * 28);
  const cho = [
    "ㄱ",
    "ㄲ",
    "ㄴ",
    "ㄷ",
    "ㄸ",
    "ㄹ",
    "ㅁ",
    "ㅂ",
    "ㅃ",
    "ㅅ",
    "ㅆ",
    "ㅇ",
    "ㅈ",
    "ㅉ",
    "ㅊ",
    "ㅋ",
    "ㅌ",
    "ㅍ",
    "ㅎ",
  ];
  return cho[choIndex];
}

class MapPage extends StatefulWidget {
  final List<Location> locations;
  // 지명(전체) 목록에서 지명을 누르면 이 값이 바뀌고, 지도가 해당 지명을 표시한다.
  final ValueListenable<Location?>? focusRequest;
  const MapPage({super.key, required this.locations, this.focusRequest});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const double _focusZoom = 9;
  static const double _pinHeight = 44; // 기본 핀 마커의 화면상 높이(대략)

  Location? selectedLocation;
  Set<Marker> markers = {};
  GoogleMapController? mapController;
  String? filterConsonant;

  // 핀 위에 띄우는 지명 라벨의 화면 좌표 (지도 위젯 기준, 논리 픽셀)
  Offset? _labelPos;
  bool _updatingLabel = false;

  @override
  void initState() {
    super.initState();
    // 지도 탭이 처음 만들어지기 전에 지명이 선택된 경우를 위해 현재 값을 반영
    final pending = widget.focusRequest?.value;
    if (pending != null) _setLocation(pending);
    widget.focusRequest?.addListener(_onFocusRequest);
  }

  @override
  void dispose() {
    widget.focusRequest?.removeListener(_onFocusRequest);
    super.dispose();
  }

  void _onFocusRequest() {
    final loc = widget.focusRequest?.value;
    if (loc == null) return;
    setState(() => _setLocation(loc));
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(loc.lat, loc.lng), _focusZoom),
    );
    _updateLabelSoon();
  }

  // 지도가 움직이는 동안 핀 위 라벨 위치를 따라가게 한다.
  Future<void> _updateLabel() async {
    final loc = selectedLocation;
    final controller = mapController;
    if (loc == null || controller == null || _updatingLabel) return;
    _updatingLabel = true;
    try {
      final coord = await controller.getScreenCoordinate(
        LatLng(loc.lat, loc.lng),
      );
      if (!mounted) return;
      // Android는 물리 픽셀, iOS·웹은 논리 픽셀로 돌려준다
      final scale = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? MediaQuery.devicePixelRatioOf(context)
          : 1.0;
      setState(() => _labelPos = Offset(coord.x / scale, coord.y / scale));
    } catch (_) {
      // 지도가 아직 준비되지 않았으면 다음 갱신에서 표시
    } finally {
      _updatingLabel = false;
    }
  }

  // 카메라 이동이 끝난 뒤에 라벨 위치를 다시 계산한다.
  Future<void> _updateLabelSoon() async {
    await Future.delayed(const Duration(milliseconds: 450));
    if (mounted) _updateLabel();
  }

  // 선택 지명과 마커를 갱신한다 (setState는 호출하는 쪽에서)
  void _setLocation(Location loc) {
    selectedLocation = loc;
    _labelPos = null; // 새 지명은 카메라 이동이 끝난 뒤에 라벨을 다시 띄운다
    markers = {
      Marker(
        markerId: MarkerId(loc.id.toString()),
        position: LatLng(loc.lat, loc.lng),
      ),
    };
  }

  List<Location> get filteredLocations {
    if (filterConsonant == null) return [];
    return widget.locations.where((loc) {
      final initial = getInitialConsonant(loc.name.trim());
      return initial == filterConsonant;
    }).toList();
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
      setState(() => _setLocation(loc));
      mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      );
      _updateLabelSoon();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final consonants = ["ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", "ㅇ", "ㅌ", "ㅎ"];
    return Column(
      children: [
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ), // ✅ Bold 처리
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (selectedLocation != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              selectedLocation!.currentName.isNotEmpty
                  ? "${selectedLocation!.name} (${selectedLocation!.currentName})"
                  : selectedLocation!.name,
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                // 지도를 끌 때 TabBarView 좌우 스와이프와 충돌하지 않도록 지도가 제스처를 우선 처리
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onMapCreated: (controller) {
                  mapController = controller;
                  // 지명(전체)에서 먼저 선택해 들어온 경우 라벨도 함께 표시
                  if (selectedLocation != null) _updateLabelSoon();
                },
                onCameraMove: (_) => _updateLabel(),
                onCameraIdle: _updateLabel,
                initialCameraPosition: selectedLocation != null
                    ? CameraPosition(
                        target: LatLng(
                          selectedLocation!.lat,
                          selectedLocation!.lng,
                        ),
                        zoom: _focusZoom,
                      )
                    : const CameraPosition(
                        target: LatLng(32.75315, 35.27383),
                        zoom: 7,
                      ),
                markers: markers,
              ),
              // 핀 바로 위에 지명 라벨 (구글 말풍선 대신 앱에서 직접 그린다)
              if (selectedLocation != null && _labelPos != null)
                Positioned(
                  left: _labelPos!.dx,
                  top: _labelPos!.dy - _pinHeight,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1),
                    child: IgnorePointer(
                      child: _LocationLabel(location: selectedLocation!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// 핀 위에 띄우는 작은 지명 라벨
class _LocationLabel extends StatelessWidget {
  final Location location;
  const _LocationLabel({required this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF5C3D99), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: location.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B2470),
                  ),
                ),
                if (location.currentName.isNotEmpty)
                  TextSpan(
                    text: ' (${location.currentName})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
        // 아래쪽 작은 삼각형 (핀을 가리키는 꼬리)
        CustomPaint(size: const Size(12, 6), painter: _TailPainter()),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF5C3D99));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
