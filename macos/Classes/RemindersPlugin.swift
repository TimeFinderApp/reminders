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
      result(PermissionManager.getPermissionStatus())
        
    case "requestPermission":
      result(self.reminders.requestPermission())

    case "getDefaultList":
      result(self.reminders.getDefaultList())

    case "getAllLists":
      result(self.reminders.getAllLists())

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

