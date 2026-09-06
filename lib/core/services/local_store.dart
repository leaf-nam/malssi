import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 로컬 지속화 키 (#122). 컬렉션명(`CollectionNames`)과 1:1로 대응한다.
abstract class StoreKeys {
  static const seeds = 'seeds';
  static const fruits = 'fruits';
  static const settings = 'settings';
}

/// JSON 직렬화 로컬 저장소 (#122).
/// 값은 JSON 원시형(`String`/`num`/`bool`/`null`)만 담는다.
/// `DateTime`은 저장소가 아닌 호출 측이 [encodeDates]/[decodeDates]로 변환한다.
abstract class LocalStore {
  Future<List<Map<String, Object?>>> readList(String key);

  Future<void> writeList(String key, List<Map<String, Object?>> value);

  Future<Map<String, Object?>> readMap(String key);

  Future<void> writeMap(String key, Map<String, Object?> value);
}

/// `SharedPreferences` 기반 구현. 문자열 JSON 1건당 1키.
class PrefsLocalStore implements LocalStore {
  PrefsLocalStore(this._prefs);

  /// `main()` 시작 시 1회 생성한다. 실패하면 호출 측이 메모리 동작으로 폴백.
  static Future<PrefsLocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsLocalStore(prefs);
  }

  final SharedPreferences _prefs;

  @override
  Future<List<Map<String, Object?>>> readList(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>)
          Map<String, Object?>.from(entry),
    ];
  }

  @override
  Future<void> writeList(
      String key, List<Map<String, Object?>> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  @override
  Future<Map<String, Object?>> readMap(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const {};
    return Map<String, Object?>.from(decoded);
  }

  @override
  Future<void> writeMap(String key, Map<String, Object?> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }
}

/// 모델 `toMap()`의 `DateTime` 값을 ISO 문자열로 바꾼다.
/// [dateKeys]에 든 키만 변환하고 나머지는 그대로 둔다.
Map<String, Object?> encodeDates(
    Map<String, dynamic> map, Set<String> dateKeys) {
  return {
    for (final entry in map.entries)
      entry.key: dateKeys.contains(entry.key) && entry.value is DateTime
          ? (entry.value as DateTime).toIso8601String()
          : entry.value as Object?,
  };
}

/// Firestore `Timestamp` 흉내. 모델 `fromMap`은 `createdAt.toDate()`를
/// 호출하므로, 읽어들인 ISO 문자열을 이 형태로 감싼다.
class StoredDate {
  StoredDate(this.value);

  final DateTime value;

  DateTime toDate() => value;
}

/// ISO 문자열을 [StoredDate]로 되돌린다. [dateKeys] 외 키는 그대로 둔다.
Map<String, dynamic> decodeDates(
    Map<String, Object?> map, Set<String> dateKeys) {
  return {
    for (final entry in map.entries)
      entry.key: _decodeValue(entry.key, entry.value, dateKeys),
  };
}

dynamic _decodeValue(
    String key, Object? value, Set<String> dateKeys) {
  if (dateKeys.contains(key) && value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return StoredDate(parsed);
  }
  return value;
}
