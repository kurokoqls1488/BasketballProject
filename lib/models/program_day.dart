class ProgramDay {
  final int id;
  final int programId;
  final int dayNumber;

  ProgramDay({
    required this.id,
    required this.programId,
    required this.dayNumber,
  });

  factory ProgramDay.fromJson(Map<String, dynamic> json) {
    return ProgramDay(
      id: json['id'] as int? ?? 0,
      programId: json['id_program'] as int? ?? 0,
      dayNumber: json['day_number'] as int? ?? 0,
    );
  }
}

class DayWithWorkout {
  final ProgramDay programDay;
  final int? workoutId;
  final String workoutName;

  DayWithWorkout({
    required this.programDay,
    this.workoutId,
    this.workoutName = 'Workout',
  });
}
