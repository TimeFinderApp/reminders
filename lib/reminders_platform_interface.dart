import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:reminders/reminders_permission_status.dart';

import 'reminder.dart';
import 'reminders_list.dart';
import 'reminders_method_channel.dart';

abstract class RemindersPlatformInterface extends PlatformInterface {
  /// Constructs a RemindersPlatform.
  RemindersPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static RemindersPlatformInterface _instance = RemindersMethodChannel();

  /// The default instance of [RemindersPlatformInterface] to use.
  ///
  /// Defaults to [RemindersMethodChannel].
  static RemindersPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RemindersPlatformInterface] when
  /// they register themselves.
  static set instance(RemindersPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion();

  Future<bool> requestPermission();

  Future<PermissionStatus> getPermissionStatus();

  Future<String> getDefaultListId();

  Future<List<RemList>> getLists();

  Future<List<Reminder>> getRemindersForListId(String listId);

  Future<String> createList(String title);

  Future<void> updateList(String id, String newTitle);

  Future<void> deleteList(String id);

  Future<String> createReminder(Reminder reminder);

  Future<void> updateReminder(String id, Reminder reminder);

  Future<void> deleteReminder(String id);
}
