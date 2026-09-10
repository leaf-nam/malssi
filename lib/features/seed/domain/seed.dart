class Seed {
  final String id;
  final String dateKey;
  final String quoteId;
  final String status;
  final DateTime createdAt;

  /// 당일 씨앗의 테마 (`SeedTheme` 값 중 1개, 미지정은 `''`).
  /// 일자별 선정 방식은 후속 이슈에서 확정한다.
  final String theme;

  /// 성장 단계 (0~5). 2시간마다 1단계씩 오른다.
  final int growthStage;

  /// 심은 시각. 경과 시간으로 단계를 계산한다.
  final DateTime plantedAt;

  /// 전체 단계 수 (0~5, 6단계).
  static const totalStages = 6;

  /// 최종 단계 (열매).
  static const maxGrowthStage = 5;

  /// 단계 상승 간격 (시간). 디버그 빨리감기 단위로도 사용.
  static const stageHours = 2;

  /// 단계 상승 간격. 디버그·릴리즈 동일하게 2시간이다 (#95).
  /// 디버그에서는 버튼(`+1단계`/`열매 만들기`)으로 당긴다.
  static const stageInterval = Duration(hours: stageHours);

  /// 당일 마감 시각(시). 정오 고정 (#147). `seedTime`과 무관하다.
  static const deadlineHour = 12;

  /// 마감 리마인드 시각(시). 마감 1시간 전 고정 (#147).
  static const reminderHour = 11;

  const Seed({
    required this.id,
    required this.dateKey,
    required this.quoteId,
    required this.status,
    required this.createdAt,
    this.theme = '',
    this.growthStage = 0,
    required this.plantedAt,
  });

  /// 날짜키 (`'YYYY-MM-DD'`). 문서 ID로도 사용한다.
  static String dateKeyFor(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  bool get isLocked => status == SeedStatus.locked;
  bool get isOpened => status == SeedStatus.opened;

  factory Seed.fromMap(Map<String, dynamic> map) {
    final createdAt =
        (map['createdAt'] as dynamic).toDate() ?? DateTime.now();
    return Seed(
      id: map['id'] ?? '',
      dateKey: map['dateKey'] ?? '',
      quoteId: map['quoteId'] ?? '',
      status: map['status'] ?? SeedStatus.locked,
      createdAt: createdAt,
      theme: map['theme'] ?? '',
      growthStage: map['growthStage'] ?? 0,
      plantedAt:
          (map['plantedAt'] as dynamic)?.toDate() ?? createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateKey': dateKey,
      'quoteId': quoteId,
      'status': status,
      'createdAt': createdAt,
      'theme': theme,
      'growthStage': growthStage,
      'plantedAt': plantedAt,
    };
  }

  Seed copyWith({
    String? id,
    String? dateKey,
    String? quoteId,
    String? status,
    DateTime? createdAt,
    String? theme,
    int? growthStage,
    DateTime? plantedAt,
  }) {
    return Seed(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      quoteId: quoteId ?? this.quoteId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      theme: theme ?? this.theme,
      growthStage: growthStage ?? this.growthStage,
      plantedAt: plantedAt ?? this.plantedAt,
    );
  }

  bool get isGrowing => status == SeedStatus.growing;
  bool get isComplete => status == SeedStatus.complete;

  /// [now] 기준 성장 단계. `growing`이 아니면 저장된 단계 그대로.
  int growthStageAt(DateTime now) {
    if (!isGrowing) return growthStage;
    final elapsed =
        now.difference(plantedAt).inSeconds ~/ stageInterval.inSeconds;
    return elapsed.clamp(0, Seed.maxGrowthStage);
  }

  /// 당일 정오를 넘겨 심을 수 없게 된 `locked` 씨앗인지 (#147).
  /// `growing`·`complete` 등에는 해당 없고, 자정 만료와 별개다.
  /// 정오 정각까지는 심을 수 있고, 그 이후는 마감이다.
  /// 저장소는 마감된 당일 씨앗을 `expired`로 전환한다.
  bool isMissed(DateTime now) {
    if (!isLocked) return false;
    if (dateKey != dateKeyFor(now)) return false;
    final noon = DateTime(now.year, now.month, now.day, deadlineHour);
    return now.isAfter(noon);
  }

  /// [date] 당일 리마인드 시각(11:00) (#147).
  static DateTime reminderAt(DateTime date) =>
      DateTime(date.year, date.month, date.day, reminderHour);

  /// 다음 성장 단계까지 남은 시간 (#138).
  /// `growing`이 아니면 `Duration.zero`를 돌려준다.
  /// 최종 단계에 도달했으면 완성 임박으로 보고 `Duration.zero`
  /// (남은시간 대신 완성 표시를 보여준다).
  Duration timeUntilNextStage(DateTime now) {
    if (!isGrowing) return Duration.zero;
    if (growthStageAt(now) >= maxGrowthStage) return Duration.zero;
    final elapsed = now.difference(plantedAt);
    if (elapsed.isNegative) return stageInterval;
    return Duration(
        seconds: stageInterval.inSeconds -
            (elapsed.inSeconds % stageInterval.inSeconds));
  }
}

/// `Seed.status` 값. enum 대신 문자열 상수로 둔다 (Firestore 직렬화 단순화).
abstract class SeedStatus {
  static const locked = 'locked';

  /// 심김. 2시간 간격으로 `growthStage`가 오른다.
  static const growing = 'growing';

  /// 성장 완료 (열매). quoteId 확정, 수확 대상.
  static const complete = 'complete';
  static const opened = 'opened';
  static const expired = 'expired';
}
