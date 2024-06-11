import EventKit

enum PermissionStatus: String {
    case authorized = "authorized"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case restricted = "restricted"
    case unknown = "unknown"
    case fullAccess = "fullAccess"
    case writeOnly = "writeOnly"

    init(status: EKAuthorizationStatus) {
        switch status {
        case .authorized:
            self = .authorized
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        default:
            // Handle the new cases specific to iOS 17 and macOS 14
            if #available(iOS 17.0, macOS 14.0, *) {
                switch status {
                case .fullAccess:
                    self = .fullAccess
                case .writeOnly:
                    self = .writeOnly
                default:
                    self = .unknown
                }
            } else {
                self = .unknown
            }
        }
    }
}

// MARK: - Permission Handling
class PermissionManager {
    private static let eventStore = EKEventStore()

    static func getPermissionStatus() -> PermissionStatus {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        return PermissionStatus(status: status)
    }
}
