import 'reminder.dart';
export 'reminder.dart';
import 'reminders_list.dart';
export 'reminders_list.dart';
import 'reminders_platform_interface.dart';
import 'reminders_permission_status.dart';

class Reminders {
  const Reminders();

  Future<String?> getPlatformVersion() {
    return RemindersPlatformInterface.instance.getPlatformVersion();
  }

  Future<bool> requestPermission() {
    return RemindersPlatformInterface.instance.requestPermission();
  }

  Future<PermissionStatus> getPermissionStatus() {
    return RemindersPlatformInterface.instance.getPermissionStatus();
  }

  Future<String> getDefaultListId() {
    return RemindersPlatformInterface.instance.getDefaultListId();
  }

  Future<List<RemList>> getLists() {
    return RemindersPlatformInterface.instance.getLists();
  }

  Future<List<Reminder>> getRemindersForListId(String listId) {
    return RemindersPlatformInterface.instance.getRemindersForListId(listId);
  }

  Future<String> createList(String title) {
    return RemindersPlatformInterface.instance.createList(title);
  }

  Future<void> updateList(String id, String newTitle) {
    return RemindersPlatformInterface.instance.updateList(id, newTitle);
  }

  Future<void> deleteList(String id) {
    return RemindersPlatformInterface.instance.deleteList(id);
  }

  Future<String> createReminder(Reminder reminder) {
    return RemindersPlatformInterface.instance.createReminder(reminder);
  }

  Future<void> updateReminder(String id, Reminder reminder) {
    return RemindersPlatformInterface.instance.updateReminder(id, reminder);
  }

  Future<void> deleteReminder(String id) {
    return RemindersPlatformInterface.instance.deleteReminder(id);
  }
}
