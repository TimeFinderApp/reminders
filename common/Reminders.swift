import EventKit
import UIKit

// MARK: - Models
struct Reminder {
    let list: List
    let id: String
    let title: String
    let dueDate: DateComponents?
    let priority: Int
    let isCompleted: Bool
    let notes: String?
}

struct List {
    let title: String
    let id: String
}

// MARK: - Error Handling
enum ReminderError: Error {
    case invalidCalendarID
    case reminderNotFound
    case eventStoreError(Error)
    case encodingError(String)
    case invalidDateComponents
    case unknownError
}

// MARK: - Reminder Management
class ReminderManager {
    private let eventStore: EKEventStore
    private let queue = DispatchQueue(label: "com.reminderManager.queue", attributes: .concurrent)
    
    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }
}


// MARK: CRUD Operations for Reminders
extension ReminderManager {
    func getLists(completion: @escaping ([List]) -> Void) {
        queue.async {
            let reminderLists = self.eventStore.calendars(for: .reminder)
            let lists = reminderLists.map { List(title: $0.title, id: $0.calendarIdentifier) }
            DispatchQueue.main.async {
                completion(lists)
            }
        }
    }
    
    func getRemindersForListId(_ listId: String, completion: @escaping ([Reminder]) -> Void) {
        queue.async {
            guard let calendar = self.eventStore.calendar(withIdentifier: listId) else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            let predicate = self.eventStore.predicateForReminders(in: [calendar])
            self.eventStore.fetchReminders(matching: predicate) { ekReminders in
                let reminders = ekReminders?.compactMap { ekReminder -> Reminder? in
                    guard let list = self.eventStore.calendar(withIdentifier: ekReminder.calendarItemIdentifier) else {
                        return nil
                    }
                    return Reminder(
                        list: List(title: list.title, id: list.calendarIdentifier),
                        id: ekReminder.calendarItemIdentifier,
                        title: ekReminder.title,
                        dueDate: ekReminder.dueDateComponents,
                        priority: ekReminder.priority,
                        isCompleted: ekReminder.isCompleted,
                        notes: ekReminder.notes
                    )
                } ?? []
                DispatchQueue.main.async {
                    completion(reminders)
                }
            }
        }
    }
    
    func createReminder(_ reminder: Reminder, completion: @escaping (Result<String, ReminderError>) -> Void) {
        queue.async(flags: .barrier) {
            let newReminder = EKReminder(eventStore: self.eventStore)
            newReminder.title = reminder.title
            newReminder.priority = reminder.priority
            newReminder.isCompleted = reminder.isCompleted
            newReminder.notes = reminder.notes
            newReminder.dueDateComponents = reminder.dueDate
            
            guard let list = self.eventStore.calendar(withIdentifier: reminder.list.id) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidCalendarID))
                }
                return
            }
            newReminder.calendar = list
            
            do {
                try self.eventStore.save(newReminder, commit: true)
                DispatchQueue.main.async {
                    completion(.success(newReminder.calendarItemIdentifier))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.eventStoreError(error)))
                }
            }
        }
    }
    
    
    func updateReminder(withId id: String, updates: Reminder, completion: @escaping (Result<Void, ReminderError>) -> Void) {
        queue.async(flags: .barrier) {
            guard let reminder = self.eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
                DispatchQueue.main.async {
                    completion(.failure(.reminderNotFound))
                }
                return
            }
            
            reminder.title = updates.title
            reminder.priority = updates.priority
            reminder.isCompleted = updates.isCompleted
            reminder.notes = updates.notes
            reminder.dueDateComponents = updates.dueDate
            
            do {
                try self.eventStore.save(reminder, commit: true)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.eventStoreError(error)))
                }
            }
        }
    }
    
    func deleteReminder(withId id: String, completion: @escaping (Result<Void, ReminderError>) -> Void) {
        queue.async(flags: .barrier) {
            guard let reminder = self.eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
                DispatchQueue.main.async {
                    completion(.failure(.reminderNotFound))
                }
                return
            }
            
            do {
                try self.eventStore.remove(reminder, commit: true)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.eventStoreError(error)))
                }
            }
        }
    }
}

// MARK: List Operations
extension ReminderManager {
    func getDefaultListId(completion: @escaping (String?) -> Void) {
        queue.async {
            let defaultList = self.eventStore.defaultCalendarForNewReminders()
            DispatchQueue.main.async {
                completion(defaultList?.calendarIdentifier)
            }
        }
    }
    
    
    func createList(withTitle title: String, completion: @escaping (Result<String, ReminderError>) -> Void) {
        queue.async(flags: .barrier) {
            let newList = EKCalendar(for: .reminder, eventStore: self.eventStore)
            newList.title = title
            guard let source = self.eventStore.defaultCalendarForNewReminders()?.source else {
                DispatchQueue.main.async {
                    completion(.failure(.unknownError))
                }
                return
            }
            newList.source = source
            
            do {
                try self.eventStore.saveCalendar(newList, commit: true)
                DispatchQueue.main.async {
                    completion(.success(newList.calendarIdentifier))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.eventStoreError(error)))
                }
            }
        }
    }
    
    func updateList(withId id: String, newTitle: String, completion: @escaping (Result<Void, ReminderError>) -> Void) {
        queue.async(flags: .barrier) {
            guard let list = self.eventStore.calendar(withIdentifier: id) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidCalendarID))
                }
                return
            }
            
            list.title = newTitle
            
            do {
                try self.eventStore.saveCalendar(list, commit: true)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.eventStoreError(error)))
                }
            }
        }
    }
    
    func deleteList(withId id: String, completion: @escaping (Result<Void, ReminderError>) -> Void) {
        queue.async(flags: .barrier) {
            guard let list = self.eventStore.calendar(withIdentifier: id) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidCalendarID))
                }
                return
            }
            
            do {
                try self.eventStore.removeCalendar(list, commit: true)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.eventStoreError(error)))
                }
            }
        }
    }
}

// MARK: Platform Information
extension ReminderManager {
    func getPlatformVersion() -> String? {
        return UIDevice.current.systemVersion
    }
}

extension List {
    func toDictionary() -> [String: Any] {
        return ["title": title, "id": id]
    }
}

extension Reminder {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "listId": list.id,
            "id": id,
            "title": title,
            "priority": priority,
            "isCompleted": isCompleted
        ]
        if let dueDate = dueDate {
            dict["dueDate"] = dueDate
        }
        if let notes = notes {
            dict["notes"] = notes
        }
        return dict
    }
}
