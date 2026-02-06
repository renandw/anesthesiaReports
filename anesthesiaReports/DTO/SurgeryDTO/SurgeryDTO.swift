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
    let cbhpms: [SurgeryCbhpmDTO]
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
        case cbhpms
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
        case deletedByName = "deleted_by_name"
        case isDeleted = "is_deleted"
        case version
        case syncStatus = "sync_status"
        case lastSyncAt = "last_sync_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        lastDigits = try container.decode(String.self, forKey: .lastDigits)
        patientId = try container.decode(String.self, forKey: .patientId)
        date = try container.decode(String.self, forKey: .date)
        startAt = try container.decodeIfPresent(Date.self, forKey: .startAt)
        endAt = try container.decodeIfPresent(Date.self, forKey: .endAt)
        insuranceName = try container.decode(String.self, forKey: .insuranceName)
        insuranceNumber = try container.decode(String.self, forKey: .insuranceNumber)
        mainSurgeon = try container.decode(String.self, forKey: .mainSurgeon)
        auxiliarySurgeons = try container.decodeIfPresent([String].self, forKey: .auxiliarySurgeons)
        hospital = try container.decode(String.self, forKey: .hospital)
        weight = try container.decode(String.self, forKey: .weight)
        proposedProcedure = try container.decode(String.self, forKey: .proposedProcedure)
        completeProcedure = try container.decodeIfPresent(String.self, forKey: .completeProcedure)
        status = try container.decode(String.self, forKey: .status)
        type = try container.decode(String.self, forKey: .type)
        myPermission = try container.decode(String.self, forKey: .myPermission)
        financial = try container.decodeIfPresent(SurgeryFinancialDTO.self, forKey: .financial)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdByName = try container.decode(String.self, forKey: .createdByName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        updatedByName = try container.decodeIfPresent(String.self, forKey: .updatedByName)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        lastActivityAt = try container.decodeIfPresent(Date.self, forKey: .lastActivityAt)
        lastActivityBy = try container.decodeIfPresent(String.self, forKey: .lastActivityBy)
        lastActivityByName = try container.decodeIfPresent(String.self, forKey: .lastActivityByName)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        deletedBy = try container.decodeIfPresent(String.self, forKey: .deletedBy)
        deletedByName = try container.decodeIfPresent(String.self, forKey: .deletedByName)
        isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        version = try container.decode(Int.self, forKey: .version)
        syncStatus = try container.decode(String.self, forKey: .syncStatus)
        lastSyncAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncAt)

        cbhpms = try container.decodeIfPresent([SurgeryCbhpmDTO].self, forKey: .cbhpms) ?? []
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

    enum CodingKeys: String, CodingKey {
        case code
        case procedure
        case port
        case codigo
        case procedimento
        case porte_anestesico
    }

    init(code: String, procedure: String, port: String) {
        self.code = code
        self.procedure = procedure
        self.port = port
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code =
            try container.decodeIfPresent(String.self, forKey: .code) ??
            container.decode(String.self, forKey: .codigo)
        self.procedure =
            try container.decodeIfPresent(String.self, forKey: .procedure) ??
            container.decode(String.self, forKey: .procedimento)
        self.port =
            try container.decodeIfPresent(String.self, forKey: .port) ??
            container.decode(String.self, forKey: .porte_anestesico)
    }
}

struct SurgeryFinancialDTO: Decodable {
    // Postgres NUMERIC pode chegar como string.
    let valueAnesthesia: String?

    enum CodingKeys: String, CodingKey {
        case valueAnesthesia = "value_anesthesia"
    }
}

struct SurgeryFinancialDetailsDTO: Decodable {
    let id: String
    let surgeryId: String
    let valueAnesthesia: String?
    let valuePreAnesthesia: String?
    let baseValue: String?
    let finalSurgeryValue: String?
    let valuePartialPayment: String?
    let remainingValue: String?
    let glosaAnesthesia: Bool?
    let glosaPreanesthesia: Bool?
    let glosaAnesthesiaValue: String?
    let glosaPreanesthesiaValue: String?
    let notes: String?
    let paid: Bool
    let paymentDate: String?
    let taxedValue: String?
    let taxPercentage: String?
    let createdAt: Date
    let updatedBy: String?
    let updatedByName: String?
    let updatedAt: Date?
    let version: Int
    let syncStatus: String
    let lastSyncAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case surgeryId = "surgery_id"
        case valueAnesthesia = "value_anesthesia"
        case valuePreAnesthesia = "value_pre_anesthesia"
        case baseValue = "base_value"
        case finalSurgeryValue = "final_surgery_value"
        case valuePartialPayment = "value_partial_payment"
        case remainingValue = "remaining_value"
        case glosaAnesthesia = "glosa_anesthesia"
        case glosaPreanesthesia = "glosa_preanesthesia"
        case glosaAnesthesiaValue = "glosa_anesthesia_value"
        case glosaPreanesthesiaValue = "glosa_preanesthesia_value"
        case notes
        case paid
        case paymentDate = "payment_date"
        case taxedValue = "taxed_value"
        case taxPercentage = "tax_percentage"
        case createdAt = "created_at"
        case updatedBy = "updated_by"
        case updatedByName = "updated_by_name"
        case updatedAt = "updated_at"
        case version
        case syncStatus = "sync_status"
        case lastSyncAt = "last_sync_at"
    }
}

struct FinancialResponse: Decodable {
    let financial: SurgeryFinancialDetailsDTO
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
    let cbhpms: [SurgeryCbhpmInput]?
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
    let cbhpms: [SurgeryCbhpmInput]?
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

struct UpdateSurgeryFinancialInput: Encodable {
    let value_anesthesia: Double?
    let value_pre_anesthesia: Double?
    let final_surgery_value: Double?
    let value_partial_payment: Double?
    let glosa_anesthesia: Bool?
    let glosa_preanesthesia: Bool?
    let glosa_anesthesia_value: Double?
    let glosa_preanesthesia_value: Double?
    let notes: String?
    let paid: Bool?
    let payment_date: String?
    let taxed_value: Double?
    let tax_percentage: Double?
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

// MARK: - Dedup DTOs

struct PrecheckSurgeryInput: Encodable {
    let patient_id: String
    let date: String
    let type: String
    let insurance_name: String
    let hospital: String
    let main_surgeon: String
    let proposed_procedure: String
}

struct PrecheckSurgeryMatchDTO: Decodable, Identifiable {
    let surgeryId: String
    let surgeryIdLastDigits: String
    let patientId: String
    let date: String
    let type: String
    let insuranceName: String
    let hospital: String
    let mainSurgeon: String
    let proposedProcedure: String
    let matchScore: Int

    var id: String { surgeryId }

    enum CodingKeys: String, CodingKey {
        case surgeryId = "surgery_id"
        case surgeryIdLastDigits = "surgery_id_last_digits"
        case patientId = "patient_id"
        case date
        case type
        case insuranceName = "insurance_name"
        case hospital
        case mainSurgeon = "main_surgeon"
        case proposedProcedure = "proposed_procedure"
        case matchScore = "match_score"
    }
}

struct PrecheckSurgeriesResponse: Decodable {
    let matches: [PrecheckSurgeryMatchDTO]
}

// MARK: - Anesthesia Progress DTOs

struct SurgeryAnesthesiaProgressSurgeryDTO: Decodable {
    let surgeryId: String
    let status: String
    let startAt: Date?
    let endAt: Date?

    enum CodingKeys: String, CodingKey {
        case surgeryId = "surgery_id"
        case status
        case startAt = "start_at"
        case endAt = "end_at"
    }
}

struct SurgeryAnesthesiaProgressAnesthesiaDTO: Decodable {
    let anesthesiaId: String
    let status: String
    let startAt: Date?
    let endAt: Date?

    enum CodingKeys: String, CodingKey {
        case anesthesiaId = "anesthesia_id"
        case status
        case startAt = "start_at"
        case endAt = "end_at"
    }
}

struct SurgeryAnesthesiaProgressSharedPreDTO: Decodable {
    let sharedId: String
    let surgeryId: String
    let asaRaw: String?

    enum CodingKeys: String, CodingKey {
        case sharedId = "shared_id"
        case surgeryId = "surgery_id"
        case asaRaw = "asa_raw"
    }
}

struct SurgeryAnesthesiaProgressResponse: Decodable {
    let surgery: SurgeryAnesthesiaProgressSurgeryDTO
    let anesthesia: SurgeryAnesthesiaProgressAnesthesiaDTO
    let sharedPreAnesthesia: SurgeryAnesthesiaProgressSharedPreDTO

    enum CodingKeys: String, CodingKey {
        case surgery
        case anesthesia
        case sharedPreAnesthesia = "shared_pre_anesthesia"
    }
}

struct SurgeryAnesthesiaDetailsDTO: Decodable {
    let anesthesiaId: String
    let sharedId: String
    let status: String
    let startAt: Date?
    let endAt: Date?
    let surgeryStartAt: Date?
    let surgeryEndAt: Date?
    let surgeryStatus: String?
    let positionRaw: String?
    let asaRaw: String?
    let anesthesiaTechniques: [AnesthesiaTechniqueDTO]
    let createdAt: Date
    let createdBy: String
    let updatedAt: Date?
    let updatedBy: String?
    let lastActivityAt: Date?
    let lastActivityBy: String?
    let version: Int
    let syncStatus: String
    let lastSyncAt: Date?

    enum CodingKeys: String, CodingKey {
        case anesthesiaId = "anesthesia_id"
        case sharedId = "shared_id"
        case status
        case startAt = "start_at"
        case endAt = "end_at"
        case surgeryStartAt = "surgery_start_at"
        case surgeryEndAt = "surgery_end_at"
        case surgeryStatus = "surgery_status"
        case positionRaw = "position_raw"
        case asaRaw = "asa_raw"
        case anesthesiaTechniques = "anesthesia_techniques"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case updatedAt = "updated_at"
        case updatedBy = "updated_by"
        case lastActivityAt = "last_activity_at"
        case lastActivityBy = "last_activity_by"
        case version
        case syncStatus = "sync_status"
        case lastSyncAt = "last_sync_at"
    }
}

struct SurgeryAnesthesiaResponse: Decodable {
    let anesthesia: SurgeryAnesthesiaDetailsDTO
}

struct AnesthesiaTechniqueDTO: Codable, Hashable {
    let techniqueId: String?
    let categoryRaw: String
    let type: String
    let regionRaw: String?

    enum CodingKeys: String, CodingKey {
        case techniqueId = "technique_id"
        case categoryRaw = "category_raw"
        case type
        case regionRaw = "region_raw"
    }
}

struct AnesthesiaTechniqueInput: Encodable, Hashable {
    let categoryRaw: String
    let type: String
    let regionRaw: String?

    enum CodingKeys: String, CodingKey {
        case categoryRaw = "category_raw"
        case type
        case regionRaw = "region_raw"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categoryRaw, forKey: .categoryRaw)
        try container.encode(type, forKey: .type)
        if let regionRaw {
            try container.encode(regionRaw, forKey: .regionRaw)
        } else {
            try container.encodeNil(forKey: .regionRaw)
        }
    }
}

struct CreateAnesthesiaInput: Encodable {
    let surgery_id: String
    let surgery_start_at: String
    let start_at: String
    let end_at: String?
    let position_raw: String?
    let asa_raw: String
    let anesthesia_techniques: [AnesthesiaTechniqueInput]

    init(
        surgery_id: String,
        surgery_start_at: String,
        start_at: String,
        end_at: String?,
        position_raw: String?,
        asa_raw: String,
        anesthesia_techniques: [AnesthesiaTechniqueInput] = []
    ) {
        self.surgery_id = surgery_id
        self.surgery_start_at = surgery_start_at
        self.start_at = start_at
        self.end_at = end_at
        self.position_raw = position_raw
        self.asa_raw = asa_raw
        self.anesthesia_techniques = anesthesia_techniques
    }
}

struct UpdateAnesthesiaInput: Encodable {
    let surgery_start_at: String
    let surgery_end_at: String
    let start_at: String
    let end_at: String
    let position_raw: String?
    let asa_raw: String
    let status: String?
    let anesthesia_techniques: [AnesthesiaTechniqueInput]

    init(
        surgery_start_at: String,
        surgery_end_at: String,
        start_at: String,
        end_at: String,
        position_raw: String?,
        asa_raw: String,
        status: String?,
        anesthesia_techniques: [AnesthesiaTechniqueInput] = []
    ) {
        self.surgery_start_at = surgery_start_at
        self.surgery_end_at = surgery_end_at
        self.start_at = start_at
        self.end_at = end_at
        self.position_raw = position_raw
        self.asa_raw = asa_raw
        self.status = status
        self.anesthesia_techniques = anesthesia_techniques
    }
}
