class SM2Result {
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final DateTime nextReviewAt;

  const SM2Result({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitionCount,
    required this.nextReviewAt,
  });
}

class SM2Service {
  /// [q] — chất lượng trả lời (0-5)
  SM2Result calculate({
    required int q,
    required double easeFactor,
    required int intervalDays,
    required int repetitionCount,
  }) {
    assert(q >= 0 && q <= 5, 'q phải từ 0 đến 5');

    // Tính easeFactor mới
    double newEF = easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEF < 1.3) newEF = 1.3;

    int newInterval;
    int newRepetition;

    if (q < 3) {
      // Trả lời sai → reset
      newInterval = 1;
      newRepetition = 0;
    } else {
      // Trả lời đúng
      if (repetitionCount == 0) {
        newInterval = 1;
      } else if (repetitionCount == 1) {
        newInterval = 6;
      } else {
        newInterval = (intervalDays * newEF).round();
      }
      newRepetition = repetitionCount + 1;
    }

    final nextReviewAt = DateTime.now().add(Duration(days: newInterval));

    return SM2Result(
      easeFactor: newEF,
      intervalDays: newInterval,
      repetitionCount: newRepetition,
      nextReviewAt: nextReviewAt,
    );
  }
}
