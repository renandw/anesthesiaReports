import Foundation

// MARK: - Patient DTOs

struct PatientDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let sex: Sex
    let dateOfBirth: String
    let fingerprint: String
    let cns: String
    let myPermission: String?
    let myRole: PatientRole?
    let createdBy: String
    let createdByName: String
    let createdAt: Date
    let updatedBy: String?
    let updatedByName: String?
    let updatedAt: Date
    let lastActivityAt: Date?
    let lastActivityBy: String?
    let lastActivityByName: String?
    let deletedAt: Date?
    let deletedBy: String?
    let deletedByName: String?
    let isDeleted: Bool
    let version: Int
    let syncStatus: String
    let lastSyncAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "patient_id"
        case name = "patient_name"
        case sex
        case dateOfBirth = "date_of_birth"
        case fingerprint
        case cns
        case myPermission = "my_permission"
        case myRole = "my_role"
        case createdBy = "created_by"
        case createdByName = "created_by_name"
        case createdAt = "created_at"
        case updatedBy = "updated_by"
        case updatedByName = "updated_by_name"
        case updatedAt = "updated_at"
        case lastActivityAt = "last_activity_at"
        case lastActivityBy = "last_activity_by"
        case lastActivityByName = "last_activity_by_name"
        case deletedAt = "deleted_at"
        case deletedBy = "deleted_by"
        case deletedByName = "deleted_by_name"
        case isDeleted = "is_deleted"
        case version
        case syncStatus = "sync_status"
        case lastSyncAt = "last_sync_at"
    }
}

enum PatientRole: String, Codable, Hashable {
    case owner
    case editor
    case shared
    case unknown
}

extension PatientDTO {
    var resolvedPermission: PatientPermission {
        PatientPermission(rawValue: myPermission ?? "") ?? .unknown
    }

    var resolvedRole: PatientRole {
        myRole ?? .unknown
    }
}

struct PatientResponse: Decodable {
    let patient: PatientDTO
}

struct PatientsResponse: Decodable {
    let patients: [PatientDTO]
}

struct CreatePatientInput: Encodable {
    let patient_name: String
    let sex: Sex
    let date_of_birth: String
    let cns: String
}

struct UpdatePatientInput: Encodable {
    let patient_name: String?
    let sex: Sex?
    let date_of_birth: String?
    let cns: String?
}

// MARK: - Sharing DTOs

struct PatientShareDTO: Decodable, Identifiable {
    let userId: String
    let userName: String?
    let permission: PatientPermission
    let grantedBy: String
    let grantedAt: Date

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case permission
        case grantedBy = "granted_by"
        case grantedAt = "granted_at"
    }
}

struct PatientSharesResponse: Decodable {
    let shares: [PatientShareDTO]
}

struct SharePatientInput: Encodable {
    let user_id: String
    let permission: String
}

// MARK: - Dedup DTOs

struct PrecheckMatchDTO: Decodable, Identifiable {
    let patientId: String
    let name: String
    let sex: Sex
    let dateOfBirth: String
    let cns: String
    let createdBy: String
    let createdByName: String
    let fingerprintMatch: Bool
    let matchLevel: String

    var id: String { patientId }

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case name = "patient_name"
        case sex
        case dateOfBirth = "date_of_birth"
        case cns
        case createdBy = "created_by"
        case createdByName = "created_by_name"
        case fingerprintMatch = "fingerprint_match"
        case matchLevel = "match_level"
    }
}

struct PrecheckPatientsResponse: Decodable {
    let matches: [PrecheckMatchDTO]
}


protocol PatientSummary {
    var name: String { get }
    var sex: Sex { get }
    var dateOfBirth: String { get }
    var cns: String { get }
}

extension PatientDTO: PatientSummary {}

extension PrecheckMatchDTO: PatientSummary {}
