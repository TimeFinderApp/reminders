import Flutter
import EventKit

public class iOSRemindersPlugin: NSObject, FlutterPlugin {
    
    let reminderManager = ReminderManager(eventStore: EKEventStore())
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "reminders", binaryMessenger: registrar.messenger())
        let instance = iOSRemindersPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            
        case "getPlatformVersion":
            result(reminderManager.getPlatformVersion())
            
        case "requestPermission":
            PermissionManager.requestPermission { permissionResult in
                switch permissionResult {
                case .success(let status):
                    result(status == .fullAccess || status == .authorized)
                case .failure(let error):
                    result(FlutterError(code: "PERMISSION_DENIED", message: "Permission request denied", details: error.localizedDescription))
                }
            }
            
        case "getPermissionStatus":
            let status = PermissionManager.getPermissionStatus()
            result(status.rawValue)
            
        case "getDefaultListId":
            reminderManager.getDefaultListId { defaultListId in
                result(defaultListId)
            }
            
        case "getRemindersForListId":
            guard let arguments = call.arguments as? [String: Any], let listId = arguments["listId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing listId", details: nil))
                return
            }
            reminderManager.getRemindersForListId(listId) { reminders in
                result(reminders.map { $0.toDictionary() })
            }
            
        case "createReminder":
            if let args = call.arguments as? [String: Any], let reminderDict = args["reminder"] as? [String: Any] {
                if let reminder = self.parseReminder(from: reminderDict) {
                    reminderManager.createReminder(reminder) { createResult in
                        switch createResult {
                        case .success:
                            let successMessage = "Reminder successfully created."
                            result(["success": true, "message": successMessage])
                        case .failure(let error):
                            result(self.errorMessage(from: error))
                        }
                    }
                } else {
                    result(FlutterError(code: "PARSE_ERROR", message: "Failed to parse reminder", details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for creating a reminder", details: nil))
            }

        case "updateReminder":
            if let args = call.arguments as? [String: Any], let id = args["id"] as? String, let reminderDict = args["reminder"] as? [String: Any] {
                if let reminder = self.parseReminder(from: reminderDict) {
                    reminderManager.updateReminder(withId: id, updates: reminder) { updateResult in
                        switch updateResult {
                        case .success:
                            let successMessage = "Reminder successfully updated."
                            result(["success": true, "message": successMessage])
                        case .failure(let error):
                            result(self.errorMessage(from: error))
                        }
                    }
                } else {
                    result(FlutterError(code: "PARSE_ERROR", message: "Failed to parse reminder", details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updating a reminder", details: nil))
            }
            
            
        case "deleteReminder":
            if let args = call.arguments as? [String: String], let id = args["id"] {
                reminderManager.deleteReminder(withId: id) { deleteResult in
                    switch deleteResult {
                    case .success:
                        result(["success": true])
                    case .failure(let error):
                        result(self.errorMessage(from: error))
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for deleting a reminder", details: nil))
            }
            
        case "getLists":
            reminderManager.getLists { lists in
                result(lists.map { $0.toDictionary() })
            }
            
        case "createList":
            if let args = call.arguments as? [String: String], let title = args["title"] {
                reminderManager.createList(withTitle: title) { createResult in
                    switch createResult {
                    case .success(let listId):
                        result(listId)
                    case .failure(let error):
                        result(self.errorMessage(from: error))
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for creating a list", details: nil))
            }
            
        case "updateList":
            if let args = call.arguments as? [String: String], let id = args["id"], let newTitle = args["newTitle"] {
                reminderManager.updateList(withId: id, newTitle: newTitle) { updateResult in
                    switch updateResult {
                    case .success:
                        result(nil)
                    case .failure(let error):
                        result(self.errorMessage(from: error))
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updating a list", details: nil))
            }
            
        case "deleteList":
            if let args = call.arguments as? [String: String], let id = args["id"] {
                reminderManager.deleteList(withId: id) { deleteResult in
                    switch deleteResult {
                    case .success:
                        result(nil)
                    case .failure(let error):
                        result(self.errorMessage(from: error))
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for deleting a list", details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func errorMessage(from error: ReminderError) -> [String: Any] {
        let code: String
        let message: String

        switch error {
        case .invalidCalendarID:
            code = "INVALID_CALENDAR_ID"
            message = "Invalid calendar ID."
        case .reminderNotFound:
            code = "REMINDER_NOT_FOUND"
            message = "Reminder not found."
        case .eventStoreError(let underlyingError):
            code = "EVENT_STORE_ERROR"
            message = "Event store error: \(underlyingError.localizedDescription)"
        case .encodingError(let errorMessage):
            code = "ENCODING_ERROR"
            message = "Encoding error: \(errorMessage)"
        case .invalidDateComponents:
            code = "INVALID_DATE_COMPONENTS"
            message = "Invalid date components."
        case .unknownError:
            code = "UNKNOWN_ERROR"
            message = "An unknown error occurred."
        }
        return ["code": code, "message": message]
    }
    
    func parseReminder(from dictionary: [String: Any]) -> Reminder? {
        guard let listId = dictionary["listId"] as? String,
              let title = dictionary["title"] as? String,
              let priority = dictionary["priority"] as? Int,
              let isCompleted = dictionary["isCompleted"] as? Bool else {
            return nil
        }
        
        let list = List(title: "", id: listId) // Assuming you fetch or have the title somewhere
        let id = dictionary["id"] as? String ?? UUID().uuidString // Generate new ID if not present
        let dueDate = dictionary["dueDate"] as? DateComponents
        let notes = dictionary["notes"] as? String
        
        return Reminder(list: list, id: id, title: title, dueDate: dueDate, priority: priority, isCompleted: isCompleted, notes: notes)
    }
}
