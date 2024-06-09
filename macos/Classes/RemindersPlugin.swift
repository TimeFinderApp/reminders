import Cocoa
import FlutterMacOS

public class RemindersPlugin: NSObject, FlutterPlugin {

  let reminders = Reminders()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "reminders", binaryMessenger: registrar.messenger)
    let instance = RemindersPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)

    case "hasAccess": 
      result(self.reminders.hasAccess)

    case "getPermissionStatus":
      let permissionStatus = PermissionManager.getPermissionStatus()
      result(permissionStatus.rawValue)
        
    case "requestPermissions":
      self.reminders.requestPermissions { success in
        result(success)
      }

    case "getDefaultListId":
      result(self.reminders.getDefaultListId())

    case "getDefaultList":
      result(self.reminders.getDefaultList())

    case "getAllLists":
      self.reminders.getAllLists { lists in
          result(lists)
      }

    case "getReminders":
      if let args = call.arguments as? [String: String?] {
        if let id = args["id"] {
          self.reminders.getReminders(id) { (reminders) in 
            result(reminders)
          }
        }
      }

    case "saveReminder":
      if let args = call.arguments as? [String: Any] {
        if let reminder = args["reminder"] as? [String: Any] {
          self.reminders.saveReminder(reminder) { (error) in
            result(error)
          }
        }
      }

    case "deleteReminder":
      if let args = call.arguments as? [String: String] {
        if let id = args["id"] {
          self.reminders.deleteReminder(id) { (error) in 
            result(error)
          }
        }
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
