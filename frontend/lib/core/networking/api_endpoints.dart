class ApiEndpoints {
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const profile = '/auth/profile';

  static const plants = '/plants';
  static String plant(int id) => '/plants/$id';
  static String waterPlant(int id) => '/plants/$id/water';
  static String fertilizePlant(int id) => '/plants/$id/fertilize';
  static String rotatePlant(int id) => '/plants/$id/rotate';
  static String plantHistory(int id) => '/plants/$id/care-history';

  static const categories = '/categories';

  static const reminders = '/reminders';
  static const remindersToday = '/reminders/today';
  static const remindersUpcoming = '/reminders/upcoming';
  static String completeReminder(int id) => '/reminders/$id/complete';

  static const careLogs = '/care-logs';

  static const statsDashboard = '/statistics/dashboard';
  static const statsWeekly = '/statistics/weekly-progress';
  static const statsHealth = '/statistics/plant-health';
}
