import 'package:hive_flutter/hive_flutter.dart';
import 'hive_boxes.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open all necessary boxes
    await Hive.openBox(HiveBoxes.dashboard);
    await Hive.openBox(HiveBoxes.attendance);
    await Hive.openBox(HiveBoxes.attendanceEvents);
    await Hive.openBox(HiveBoxes.leave);
    await Hive.openBox(HiveBoxes.settings);
  }

  // Box getters
  Box get dashboardBox => Hive.box(HiveBoxes.dashboard);
  Box get attendanceBox => Hive.box(HiveBoxes.attendance);
  Box get attendanceEventsBox => Hive.box(HiveBoxes.attendanceEvents);
  Box get leaveBox => Hive.box(HiveBoxes.leave);
  Box get settingsBox => Hive.box(HiveBoxes.settings);

  // Generic methods
  Future<void> put(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  dynamic get(String boxName, String key, {dynamic defaultValue}) {
    final box = Hive.box(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  Future<void> clearAll() async {
    await dashboardBox.clear();
    await attendanceBox.clear();
    await attendanceEventsBox.clear();
    await leaveBox.clear();
    await settingsBox.clear();
  }
}
