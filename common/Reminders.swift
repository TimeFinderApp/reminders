import EventKit

class Reminders {
    let eventStore: EKEventStore = EKEventStore()
    let defaultList: EKCalendar?

    init() {
        defaultList = eventStore.defaultCalendarForNewReminders()
    }

    var hasAccess: Bool {
        return hasReminderPermission()
    }

    func getDefaultList() -> String? {
        if let defaultList = defaultList {
            return List(list: defaultList).toJson()
        }
        return nil
    }

    func getDefaultListId() -> String? {
        if let defaultList = defaultList {
            return defaultList.calendarIdentifier
        }
        return nil
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        if hasReminderPermission() {
            completion(true)
            return
        }

        if #available(iOS 17.0, macOS 14.0, *) {
            Task {
                do {
                    try await eventStore.requestFullAccessToReminders()
                    DispatchQueue.main.async {
                        let newStatus = EKEventStore.authorizationStatus(for: .reminder)
                        let accessGranted = (newStatus == .fullAccess)
                        completion(accessGranted)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { (accessGranted: Bool, error: Error?) in
                DispatchQueue.main.async {
                    completion(accessGranted)
                }
            }
        }
    }

    private func hasReminderPermission() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(iOS 17.0, macOS 14.0, *) {
            return status == .authorized || status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    func getAllLists(completion: @escaping (String?) -> Void) {
        let lists = eventStore.calendars(for: .reminder)
        let jsonData = try? JSONEncoder().encode(lists.map { List(list: $0) })
        if let jsonData = jsonData {
            completion(String(data: jsonData, encoding: .utf8))
        } else {
            completion(nil)
        }
    }

    func getReminders(_ id: String?, completion: @escaping (String?) -> Void) {
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
                completion(String(data: json ?? Data(), encoding: .utf8))
            }
        } else {
            completion(nil)
        }
    }

    func saveReminder(_ json: [String: Any], completion: @escaping (String?) -> Void) {
        let reminder: EKReminder

        guard let calendarID = json["list"] as? String,
              let list = eventStore.calendar(withIdentifier: calendarID) else {
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
            completion(reminder.calendarItemIdentifier)
        } catch {
            completion(error.localizedDescription)
        }
    }

    func deleteReminder(_ id: String, completion: @escaping (String?) -> Void) {
        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            completion("Cannot find reminder with ID: \(id)")
            return
        }

        do {
            try eventStore.remove(reminder, commit: true)
            completion(nil)
        } catch {
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
