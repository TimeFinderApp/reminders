import EventKit

enum PermissionStatus: String {
    case authorized = "authorized"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case restricted = "restricted"
    case unknown = "unknown"
    case fullAccess = "fullAccess"
    case writeOnly = "writeOnly"

    // Existing initializer for cases up to iOS 16
    init(status: EKAuthorizationStatus) {
        switch status {
        case .authorized: self = .authorized
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        @unknown default: self = .unknown
        }
    }

    // iOS 17 specific initializer
    @available(iOS 17.0, *)
    init(ios17Status status: EKAuthorizationStatus) {
        switch status {
        case .authorized: self = .fullAccess // Assuming fullAccess is equivalent to .authorized in iOS 17
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        // Handle the new cases specific to iOS 17
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
        if #available(iOS 17.0, *) {
            return PermissionStatus(ios17Status: status)
        } else {
            return PermissionStatus(status: status)
        }
    }
}
