import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JSON 캐시 (공유)
//   H 코드 → assets/visionbible.json
//   G 코드 → assets/strongcode2.json (없으면 빈 Map)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class StrongCodeCache {
  static Map<String, dynamic>? _hebrewData;
  static Map<String, dynamic>? _greekData;

  static Future<Map<String, dynamic>> load(String prefix) async {
    if (prefix == 'G') {
      // G 코드 파일이 없으면 빈 Map 반환
      if (_greekData == null) {
        try {
          _greekData = await _loadFile('assets/strongcode2.json');
        } catch (_) {
          _greekData = {};
        }
      }
      return _greekData!;
    } else {
      _hebrewData ??= await _loadFile('assets/visionbible.json');
      return _hebrewData!;
    }
  }

  static Future<Map<String, dynamic>> _loadFile(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw);

    if (decoded is Map<String, dynamic>) return decoded;

    if (decoded is List) {
      const codeKeys = ['code', 'strong_code', 'number', 'no', 'id'];
      final result = <String, dynamic>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          String? key;
          for (final ck in codeKeys) {
            if (item.containsKey(ck)) {
              key = item[ck].toString().toUpperCase();
              break;
            }
          }
          key ??= item.values.first.toString().toUpperCase();
          result[key] = item;
        }
      }
      return result;
    }

    throw Exception('$path 형식을 알 수 없습니다.');
  }

  static void clear() {
    _hebrewData = null;
    _greekData  = null;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 공유 데이터 모델
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CodeListEntry {
  final String code;
  final int    number;
  final String word;
  final String word2;
  final String contents;
  final String pronunciation;
  final String korean;
  final String times;
  final String no;

  const CodeListEntry({
    required this.code,
    required this.number,
    required this.word,
    required this.word2,
    required this.contents,
    required this.pronunciation,
    required this.korean,
    required this.times,
    required this.no,
  });
}