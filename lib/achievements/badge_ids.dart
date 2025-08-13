class BadgeIds {
  // Session counts
  static const String firstSession = 'first_session';
  static const String fiveSessions = 'five_sessions';
  static const String twentySessions = 'twenty_sessions';
  static const String hundredSessions = 'hundred_sessions';

  // Total time milestones
  static const String firstHourTotal = 'first_hour_total';
  static const String tenHoursTotal = 'ten_hours_total';
  static const String hundredHoursTotal = 'hundred_hours_total';

  // Streak achievements
  static const String firstStreak3 = 'first_streak_3';
  static const String streak7 = 'streak_7';
  static const String streak30 = 'streak_30';

  // Long session durations
  static const String longSession25m = 'long_session_25m';
  static const String longSession60m = 'long_session_60m';
  static const String longSession120m = 'long_session_120m';

  // Tag mastery
  static const String tagMastery10 = 'tag_mastery_10';

  // Coach reflections
  static const String reflection10 = 'reflection_10';

  // Weekly goals
  static const String weekGoal3 = 'week_goal_3';

  // Time-based achievements (use foundation/clock.dart)
  static const String earlyRiser = 'early_riser'; // Sessions before 8 AM
  static const String nightOwl = 'night_owl'; // Sessions after 10 PM  
  static const String consistentWeek = 'consistent_week'; // Sessions 5+ days in a week
  static const String monthlyMilestone = 'monthly_milestone'; // 30+ sessions in a month

  // Animal check-in badges (threshold: 1, 7, 30, 100)
  static const String animalRabbit1 = 'animal.rabbit.1';
  static const String animalRabbit7 = 'animal.rabbit.7';
  static const String animalRabbit30 = 'animal.rabbit.30';
  static const String animalRabbit100 = 'animal.rabbit.100';

  static const String animalTurtle1 = 'animal.turtle.1';
  static const String animalTurtle7 = 'animal.turtle.7';
  static const String animalTurtle30 = 'animal.turtle.30';
  static const String animalTurtle100 = 'animal.turtle.100';

  static const String animalCat1 = 'animal.cat.1';
  static const String animalCat7 = 'animal.cat.7';
  static const String animalCat30 = 'animal.cat.30';
  static const String animalCat100 = 'animal.cat.100';

  static const String animalOwl1 = 'animal.owl.1';
  static const String animalOwl7 = 'animal.owl.7';
  static const String animalOwl30 = 'animal.owl.30';
  static const String animalOwl100 = 'animal.owl.100';

  static const String animalDolphin1 = 'animal.dolphin.1';
  static const String animalDolphin7 = 'animal.dolphin.7';
  static const String animalDolphin30 = 'animal.dolphin.30';
  static const String animalDolphin100 = 'animal.dolphin.100';

  static const String animalDeer1 = 'animal.deer.1';
  static const String animalDeer7 = 'animal.deer.7';
  static const String animalDeer30 = 'animal.deer.30';
  static const String animalDeer100 = 'animal.deer.100';

  // All badge IDs for iteration (maintain order for consistency)
  static const List<String> all = [
    firstSession,
    fiveSessions,
    twentySessions,
    hundredSessions,
    firstHourTotal,
    tenHoursTotal,
    hundredHoursTotal,
    firstStreak3,
    streak7,
    streak30,
    longSession25m,
    longSession60m,
    longSession120m,
    tagMastery10,
    reflection10,
    weekGoal3,
    earlyRiser,
    nightOwl,
    consistentWeek,
    monthlyMilestone,
  ];

  // Prevent instantiation
  BadgeIds._();
}