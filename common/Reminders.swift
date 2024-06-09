import EventKit

class Reminders {
    let eventStore: EKEventStore = EKEventStore()
    var hasAccess: Bool = true
    let defaultList: EKCalendar?

    init() {
        print("Initializing Reminders class")
        defaultList = eventStore.defaultCalendarForNewReminders()
        if let defaultList = defaultList {
            print("Default list initialized: \(defaultList.title)")
        } else {
            print("Default list initialization failed")
        }
    }

    func getDefaultList() -> String? {
        print("Fetching default list")
        if let defaultList = defaultList {
            print("Default list fetched: \(defaultList.title)")
            return List(list: defaultList).toJson()
        }
        print("Default list not found")
        return nil
    }

    func getDefaultListId() -> String? {
        print("Fetching default list ID")
        if let defaultList = defaultList {
            print("Default list ID fetched: \(defaultList.calendarIdentifier)")
            return defaultList.calendarIdentifier
        }
        print("Default list ID not found")
        return nil
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        print("Requesting permission for reminders")
        if #available(iOS 17.0, macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { (success, error) in
                if let error = error {
                    print("Error requesting full access: \(error.localizedDescription)")
                }
                self.hasAccess = success
                print("Permission request success: \(success)")
                completion(success)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { (success, error) in
                if let error = error {
                    print("Error requesting access: \(error.localizedDescription)")
                }
                self.hasAccess = success
                print("Permission request success: \(success)")
                completion(success)
            }
        }
    }

    func getAllLists(completion: @escaping (String?) -> Void) {
        print("Fetching all reminder lists")
        let lists = eventStore.calendars(for: .reminder)
        let jsonData = try? JSONEncoder().encode(lists.map { List(list: $0) })
        if let jsonData = jsonData {
            print("All lists fetched successfully")
            completion(String(data: jsonData, encoding: .utf8))
        } else {
            print("Failed to fetch lists")
            completion(nil)
        }
    }

    func getReminders(_ id: String?, completion: @escaping (String?) -> Void) {
        print("Fetching reminders for list ID: \(id ?? "default")")
        var calendar: [EKCalendar]? = nil
        if let id = id {
            calendar = [eventStore.calendar(withIdentifier: id) ?? EKCalendar()]
        }
        let predicate: NSPredicate? = eventStore.predicateForReminders(in: calendar)
        if let predicate = predicate {
            eventStore.fetchReminders(matching: predicate) { reminders in
                let rems = reminders ?? []
                let result = rems.map { Reminder(reminder: $0) }
                let json = try? JSONEncoder().encode(result)
                print("Reminders fetched successfully")
                completion(String(data: json ?? Data(), encoding: .utf8))
            }
        } else {
            print("Failed to create predicate for reminders")
            completion(nil)
        }
    }

    func saveReminder(_ json: [String: Any], completion: @escaping (String?) -> Void) {
        print("Saving reminder with data: \(json)")
        let reminder: EKReminder

        guard let calendarID = json["list"] as? String,
              let list = eventStore.calendar(withIdentifier: calendarID) else {
            print("Invalid calendarID: \(json["list"] ?? "nil")")
            return completion("Invalid calendarID")
        }

        if let reminderID = json["id"] as? String,
           let existingReminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder {
            reminder = existingReminder
        } else {
            reminder = EKReminder(eventStore: eventStore)
        }

        reminder.calendar = list
        reminder.title = json["title"] as? String ?? ""
        reminder.priority = json["priority"] as? Int ?? 0
        reminder.isCompleted = json["isCompleted"] as? Bool ?? false
        reminder.notes = json["notes"] as? String
        if let date = json["dueDate"] as? [String: Int] {
            reminder.dueDateComponents = DateComponents(year: date["year"], month: date["month"], day: date["day"])
        } else {
            reminder.dueDateComponents = nil
        }

        do {
            try eventStore.save(reminder, commit: true)
            print("Reminder saved successfully with ID: \(reminder.calendarItemIdentifier)")
            completion(reminder.calendarItemIdentifier)
        } catch {
            print("Error saving reminder: \(error.localizedDescription)")
            completion(error.localizedDescription)
        }
    }

    func deleteReminder(_ id: String, completion: @escaping (String?) -> Void) {
        print("Deleting reminder with ID: \(id)")
        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            print("Cannot find reminder with ID: \(id)")
            completion("Cannot find reminder with ID: \(id)")
            return
        }

        do {
            try eventStore.remove(reminder, commit: true)
            print("Reminder deleted successfully")
            completion(nil)
        } catch {
            print("Error deleting reminder: \(error.localizedDescription)")
            completion(error.localizedDescription)
        }
    }
}

struct Reminder: Codable {
    let list: List
    let id: String
    let title: String
    let dueDate: DateComponents?
    let priority: Int
    let isCompleted: Bool
    let notes: String?

    init(reminder: EKReminder) {
        self.list = List(list: reminder.calendar)
        self.id = reminder.calendarItemIdentifier
        self.title = reminder.title
        self.dueDate = reminder.dueDateComponents
        self.priority = reminder.priority
        self.isCompleted = reminder.isCompleted
        self.notes = reminder.notes
    }

    func toJson() -> String? {
        let jsonData = try? JSONEncoder().encode(self)
        return String(data: jsonData ?? Data(), encoding: .utf8)
    }
}

struct List: Codable {
    let title: String
    let id: String

    init(list: EKCalendar) {
        self.title = list.title
        self.id = list.calendarIdentifier
    }

    func toJson() -> String? {
        let jsonData = try? JSONEncoder().encode(self)
        return String(data: jsonData ?? Data(), encoding: .utf8)
    }
}

// MARK: - Permission Handling
class PermissionManager {
    private static let eventStore = EKEventStore()

    static func getPermissionStatus() -> String {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .fullAccess:
            return "fullAccess"
        case .writeOnly:
            return "writeOnly"
        @unknown default:
            return "unknown"
        }
    }
}
