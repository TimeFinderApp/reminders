import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:reminders/reminders_permission_status.dart';
import 'reminders_platform_interface.dart';
import 'reminders_list.dart';
import 'reminder.dart';

const _channelName = 'reminders';

/// An implementation of [RemindersPlatformInterface] that uses method channels.
class RemindersMethodChannel extends RemindersPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(_channelName);

  @override
  Future<String?> getPlatformVersion() async {
    return await invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool> requestPermission() async {
    return await invokeMethod<bool>('requestPermission') ?? false;
  }

  Future<PermissionStatus> getPermissionStatus() async {
    final statusRawValue = await invokeMethod<int>('getPermissionStatus');
    if (statusRawValue == null) {
      throw PlatformException(
        code: 'ERROR_FETCHING_PERMISSION_STATUS',
        message: 'Could not fetch the permission status',
      );
    }
    return PermissionStatus.values[statusRawValue];
  }

  @override
  Future<String> getDefaultListId() async {
    final defaultListId = await invokeMethod<String>('getDefaultListId');
    if (defaultListId == null) {
      throw PlatformException(
        code: 'ERROR_FETCHING_DEFAULT_LIST_ID',
        message: 'Could not fetch the default list ID',
      );
    }
    return defaultListId;
  }

  @override
  Future<List<RemList>> getLists() async {
    final listsJson = await invokeMethod<List<dynamic>>('getLists');
    return listsJson?.map((json) => RemList.fromJson(json)).toList() ?? [];
  }

  @override
  Future<String> createList(String title) async {
    final listId = await invokeMethod<String>(
      'createList',
      {'title': title},
    );
    if (listId == null) {
      throw PlatformException(
        code: 'ERROR_CREATING_LIST',
        message: 'Failed to create the list',
      );
    }
    return listId;
  }

  @override
  Future<void> updateList(String id, String newTitle) async {
    final result = await invokeMethod<Map<String, dynamic>>(
      'updateList',
      {'id': id, 'newTitle': newTitle},
    );
    // Handle the case where the Swift code returns nil on success.
    if (result != null && result['success'] != true) {
      throw PlatformException(
        code: result['code'],
        message: result['message'],
      );
    }
  }

  @override
  Future<void> deleteList(String id) async {
    final result = await invokeMethod<Map<String, dynamic>>(
      'deleteList',
      {'id': id},
    );
    if (result != null && result['success'] != true) {
      throw PlatformException(
        code: result['code'],
        message: result['message'],
      );
    }
  }

  @override
  Future<List<Reminder>> getRemindersForListId(String listId) async {
    final remindersJson = await invokeMethod<List<dynamic>>(
      'getRemindersForListId',
      {'listId': listId},
    );
    return remindersJson?.map((json) => Reminder.fromJson(json)).toList() ?? [];
  }

  @override
  Future<String> createReminder(Reminder reminder) async {
    final result = await invokeMethod<Map<String, dynamic>>(
      'createReminder',
      {'reminder': reminder.toJson()},
    );
    if (result == null || result['success'] != true) {
      throw PlatformException(
        code: result?['code'] ?? 'ERROR_CREATING_REMINDER',
        message: result?['message'] ?? 'Failed to create the reminder',
      );
    }
    return result['message'];
  }

  @override
  Future<void> updateReminder(String id, Reminder reminder) async {
    final result = await invokeMethod<Map<String, dynamic>>(
      'updateReminder',
      {'id': id, 'reminder': reminder.toJson()},
    );
    if (result != null && result['success'] != true) {
      throw PlatformException(
        code: result['code'],
        message: result['message'],
      );
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    final result = await invokeMethod<Map<String, dynamic>>(
      'deleteReminder',
      {'id': id},
    );
    if (result != null && result['success'] != true) {
      throw PlatformException(
        code: result['code'],
        message: result['message'],
      );
    }
  }

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    try {
      final result = await methodChannel.invokeMethod<T>(method, arguments);
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }
}
