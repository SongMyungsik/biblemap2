//import 'dart:convert';
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
  const MapPage({super.key, required this.locations});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location? selectedLocation;
  Set<Marker> markers = {};
  late GoogleMapController mapController;
  String? filterConsonant;

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
      setState(() {
        selectedLocation = loc;
        markers = {
          Marker(
            markerId: MarkerId(loc.id.toString()),
            position: LatLng(loc.lat, loc.lng),
            infoWindow: InfoWindow(title: loc.name),
          ),
        };
        mapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(32.75315, 35.27383),
              zoom: 7,
            ),
            markers: markers,
          ),
        ),
      ],
    );
  }
}
