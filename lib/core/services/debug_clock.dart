/// 디버그용 앱 공용 시계 (#115).
///
/// 시간 이동 버튼(`+1시간`/`+1일`)이 앱이 인식하는 날짜를 통째로 미룬다.
/// 씨앗·수확물 저장소의 기본 시계와 정원 탭의 오늘 날짜가 모두 여기를 본다.
/// 오프셋이 0이면 실제 시각과 동일하다. 이동 버튼이 `kDebugMode` 한정이므로
/// 릴리즈에서는 항상 실제 시각이다.
abstract class DebugClock {
  static Duration _offset = Duration.zero;

  /// 앱이 인식하는 현재 시각.
  static DateTime now() => DateTime.now().add(_offset);

  /// 시각을 [by]만큼 미룬다. 디버그 전용.
  static void shift(Duration by) {
    _offset += by;
  }

  /// 미뤄둔 시각을 실제 시각으로 되돌린다. 테스트 뒷정리용.
  static void reset() {
    _offset = Duration.zero;
  }

  /// 시각이 미뤄져 있는지 여부.
  static bool get isShifted => _offset != Duration.zero;
}
