import Foundation

struct PatientAPI {
    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    // MARK: - Patients

    func list(search: String? = nil) async throws -> [PatientDTO] {
        let decoded: PatientsResponse = try await client.request(
            path: "/patients",
            method: "GET",
            queryItems: queryItems(search: search),
            requiresAuth: true
        )
        return decoded.patients
    }

    func listSharedWithMe(search: String? = nil) async throws -> [PatientDTO] {
        let decoded: PatientsResponse = try await client.request(
            path: "/patients/shared-with-me",
            method: "GET",
            queryItems: queryItems(search: search),
            requiresAuth: true
        )
        return decoded.patients
    }

    func listSharedByMe(search: String? = nil) async throws -> [PatientDTO] {
        let decoded: PatientsResponse = try await client.request(
            path: "/patients/shared-by-me",
            method: "GET",
            queryItems: queryItems(search: search),
            requiresAuth: true
        )
        return decoded.patients
    }

    func getById(_ patientId: String) async throws -> PatientDTO {
        let decoded: PatientResponse = try await client.request(
            path: "/patients/\(patientId)",
            method: "GET",
            requiresAuth: true
        )
        return decoded.patient
    }

    func create(_ input: CreatePatientInput) async throws -> PatientDTO {
        let decoded: PatientResponse = try await client.request(
            path: "/patients",
            method: "POST",
            body: input,
            requiresAuth: true
        )
        return decoded.patient
    }

    func update(patientId: String, input: UpdatePatientInput) async throws -> PatientDTO {
        let decoded: PatientResponse = try await client.request(
            path: "/patients/\(patientId)",
            method: "PATCH",
            body: input,
            requiresAuth: true
        )
        return decoded.patient
    }

    func delete(patientId: String) async throws {
        _ = try await client.request(
            path: "/patients/\(patientId)",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }

    // MARK: - Dedup

    func precheck(input: CreatePatientInput) async throws -> [PrecheckMatchDTO] {
        let decoded: PrecheckPatientsResponse = try await client.request(
            path: "/patients/precheck",
            method: "POST",
            body: input,
            requiresAuth: true
        )
        return decoded.matches
    }

    func claim(patientId: String) async throws {
        _ = try await client.request(
            path: "/patients/\(patientId)/claim",
            method: "POST",
            requiresAuth: true
        ) as EmptyResponse
    }

    // MARK: - Sharing

    func listShares(patientId: String) async throws -> [PatientShareDTO] {
        let decoded: PatientSharesResponse = try await client.request(
            path: "/patients/\(patientId)/share",
            method: "GET",
            requiresAuth: true
        )
        return decoded.shares
    }

    func share(patientId: String, input: SharePatientInput) async throws {
        _ = try await client.request(
            path: "/patients/\(patientId)/share",
            method: "POST",
            body: input,
            requiresAuth: true
        ) as EmptyResponse
    }

    func revoke(patientId: String, userId: String) async throws {
        _ = try await client.request(
            path: "/patients/\(patientId)/share/\(userId)",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }

    private func queryItems(search: String?) -> [URLQueryItem]? {
        let trimmed = search?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty { return nil }
        return [URLQueryItem(name: "search", value: trimmed)]
    }
}
