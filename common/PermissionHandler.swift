import EventKit

enum PermissionStatus: String {
    case authorized = "authorized"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case restricted = "restricted"
    case unknown = "unknown"
    case fullAccess = "fullAccess"
    case writeOnly = "writeOnly"

    // Existing initializer for cases up to iOS 16 and macOS 13
    init(status: EKAuthorizationStatus) {
        switch status {
        case .authorized: self = .authorized
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        @unknown default: self = .unknown
        }
    }

    // iOS 17 and macOS 14 specific initializer
    @available(iOS 17.0, macOS 14.0, *)
    init(newStatus status: EKAuthorizationStatus) {
        switch status {
        case .authorized: self = .authorized
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        // Handle the new cases specific to iOS 17 and macOS 14
        case .fullAccess: self = .fullAccess
        case .writeOnly: self = .writeOnly
        @unknown default: self = .unknown
        }
    }
}

// MARK: - Permission Handling
class PermissionManager {
    private static let eventStore = EKEventStore()

    static func getPermissionStatus() -> PermissionStatus {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(iOS 17.0, macOS 14.0, *) {
            return PermissionStatus(newStatus: status)
        } else {
            return PermissionStatus(status: status)
        }
    }
}
