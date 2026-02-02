import Foundation

// MARK: - Surgery DTOs

struct SurgeryDTO: Decodable, Identifiable {
    let id: String
    let lastDigits: String
    let patientId: String
    let date: String
    let startAt: Date?
    let endAt: Date?
    let insuranceName: String
    let insuranceNumber: String
    let mainSurgeon: String
    let auxiliarySurgeons: [String]?
    let hospital: String
    let weight: String
    let proposedProcedure: String
    let completeProcedure: String?
    let status: String
    let type: String
    let myPermission: String
    let cbhpm: SurgeryCbhpmDTO?
    let financial: SurgeryFinancialDTO?
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
        case id = "surgery_id"
        case lastDigits = "surgery_id_last_digits"
        case patientId = "patient_id"
        case date
        case startAt = "start_at"
        case endAt = "end_at"
        case insuranceName = "insurance_name"
        case insuranceNumber = "insurance_number"
        case mainSurgeon = "main_surgeon"
        case auxiliarySurgeons = "auxiliary_surgeons"
        case hospital
        case weight
        case proposedProcedure = "proposed_procedure"
        case completeProcedure = "complete_procedure"
        case status
        case type
        case myPermission = "my_permission"
        case cbhpm
        case financial
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
        case deletedByName = "deleted_byName"
        case isDeleted = "is_deleted"
        case version
        case syncStatus = "sync_status"
        case lastSyncAt = "last_sync_at"
    }
}

extension SurgeryDTO {
    var weightValue: Double? {
        Double(weight.replacingOccurrences(of: ",", with: "."))
    }
}

extension SurgeryDTO {
    var resolvedPermission: SurgeryPermission {
        SurgeryPermission(rawValue: myPermission) ?? .unknown
    }
}

struct SurgeryCbhpmDTO: Decodable {
    let code: String
    let procedure: String
    let port: String
}

struct SurgeryFinancialDTO: Decodable {
    // Postgres NUMERIC pode chegar como string.
    let valueAnesthesia: String?

    enum CodingKeys: String, CodingKey {
        case valueAnesthesia = "value_anesthesia"
    }
}

struct SurgeryResponse: Decodable {
    let surgery: SurgeryDTO
}

struct SurgeriesResponse: Decodable {
    let surgeries: [SurgeryDTO]
}

// MARK: - Inputs

struct CreateSurgeryInput: Encodable {
    let patient_id: String
    let date: String
    let insurance_name: String
    let insurance_number: String
    let main_surgeon: String
    let auxiliary_surgeons: [String]?
    let hospital: String
    let weight: Double
    let proposed_procedure: String
    let complete_procedure: String?
    let type: String
    let cbhpm: SurgeryCbhpmInput?
    let financial: SurgeryFinancialInput?
}

struct UpdateSurgeryInput: Encodable {
    let date: String?
    let insurance_name: String?
    let insurance_number: String?
    let main_surgeon: String?
    let auxiliary_surgeons: [String]?
    let hospital: String?
    let weight: Double?
    let proposed_procedure: String?
    let complete_procedure: String?
    let type: String?
    let status: String?
    let cbhpm: SurgeryCbhpmInput?
    let financial: SurgeryFinancialInput?
}

struct SurgeryCbhpmInput: Encodable {
    let code: String
    let procedure: String
    let port: String
}

struct SurgeryFinancialInput: Encodable {
    let value_anesthesia: Double?
}

// MARK: - Sharing DTOs

struct SurgeryShareDTO: Decodable, Identifiable {
    let userId: String
    let userName: String?
    let permission: String
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

extension SurgeryShareDTO {
    var resolvedPermission: SurgeryPermission {
        SurgeryPermission(rawValue: permission) ?? .unknown
    }
}

struct SurgerySharesResponse: Decodable {
    let shares: [SurgeryShareDTO]
}

struct ShareSurgeryInput: Encodable {
    let user_id: String
    let permission: String
}
