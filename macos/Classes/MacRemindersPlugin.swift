import Cocoa
import FlutterMacOS

public class MacRemindersPlugin: NSObject, FlutterPlugin {

  let reminderManager = ReminderManager(eventStore: EKEventStore())

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "reminders", binaryMessenger: registrar.messenger)
    let instance = MacRemindersPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)

    case "hasAccess":
      let status = PermissionManager.getPermissionStatus
      result(status == .authorized)

    case "getDefaultList":
      result(reminderManager.getDefaultList())

    case "getAllLists":
      result(reminderManager.getAllLists())

    case "getReminders":
      if let args = call.arguments as? [String: String?], let id = args["id"] {
        reminderManager.getReminders(inListWithID: id) { (remindersJson) in
          result(remindersJson)
        }
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for getting reminders", details: nil))
      }

    case "saveReminder":
      if let args = call.arguments as? [String: Any], let reminderJson = args["reminder"] as? [String: Any] {
        reminderManager.saveReminder(reminderJson) { saveResult in
          switch saveResult {
          case .success(let reminderId):
            result(reminderId)
          case .failure(let error):
            result(FlutterError(code: "ERROR_SAVING_REMINDER", message: error.localizedDescription, details: nil))
          }
        }
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for saving reminder", details: nil))
      }

    case "deleteReminder":
      if let args = call.arguments as? [String: String], let id = args["id"] {
        reminderManager.deleteReminder(id) { deleteResult in
          switch deleteResult {
          case .success:
            result(nil)
          case .failure(let error):
            result(FlutterError(code: "ERROR_DELETING_REMINDER", message: error.localizedDescription, details: nil))
          }
        }
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for deleting reminder", details: nil))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
