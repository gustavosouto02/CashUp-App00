import Foundation

enum BiometricKind: Equatable {
    case none, touchID, faceID, opticID

    var nome: String {
        switch self {
        case .none: return "código do iPhone"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        }
    }

    var icone: String {
        switch self {
        case .none: return "lock.fill"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        case .opticID: return "opticid"
        }
    }
}

protocol BiometricAuthServiceProtocol {
    var kind: BiometricKind { get }
    var isAvailable: Bool { get }
    func authenticate(reason: String) async throws -> Bool
}
