import Foundation

struct SurgeryAPI {
    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    // MARK: - Surgeries

    func list(search: String? = nil) async throws -> [SurgeryDTO] {
        let decoded: SurgeriesResponse = try await client.request(
            path: "/surgeries",
            method: "GET",
            queryItems: queryItems(search: search),
            requiresAuth: true
        )
        return decoded.surgeries
    }

    func listByPatient(patientId: String) async throws -> [SurgeryDTO] {
        let decoded: SurgeriesResponse = try await client.request(
            path: "/patients/\(patientId)/surgeries",
            method: "GET",
            requiresAuth: true
        )
        return decoded.surgeries
    }

    func getById(_ surgeryId: String) async throws -> SurgeryDTO {
        let decoded: SurgeryResponse = try await client.request(
            path: "/surgeries/\(surgeryId)",
            method: "GET",
            requiresAuth: true
        )
        return decoded.surgery
    }

    func create(_ input: CreateSurgeryInput) async throws -> SurgeryDTO {
        let decoded: SurgeryResponse = try await client.request(
            path: "/surgeries",
            method: "POST",
            body: input,
            requiresAuth: true
        )
        return decoded.surgery
    }

    // MARK: - Dedup

    func precheck(input: PrecheckSurgeryInput) async throws -> [PrecheckSurgeryMatchDTO] {
        let decoded: PrecheckSurgeriesResponse = try await client.request(
            path: "/surgeries/precheck",
            method: "POST",
            body: input,
            requiresAuth: true
        )
        return decoded.matches
    }

    func claim(surgeryId: String) async throws {
        _ = try await client.request(
            path: "/surgeries/\(surgeryId)/claim",
            method: "POST",
            requiresAuth: true
        ) as EmptyResponse
    }

    func update(surgeryId: String, input: UpdateSurgeryInput) async throws -> SurgeryDTO {
        let decoded: SurgeryResponse = try await client.request(
            path: "/surgeries/\(surgeryId)",
            method: "PATCH",
            body: input,
            requiresAuth: true
        )
        return decoded.surgery
    }

    func delete(surgeryId: String) async throws {
        _ = try await client.request(
            path: "/surgeries/\(surgeryId)",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }

    // MARK: - Sharing

    func listShares(surgeryId: String) async throws -> [SurgeryShareDTO] {
        let decoded: SurgerySharesResponse = try await client.request(
            path: "/surgeries/\(surgeryId)/share",
            method: "GET",
            requiresAuth: true
        )
        return decoded.shares
    }

    func share(surgeryId: String, input: ShareSurgeryInput) async throws {
        _ = try await client.request(
            path: "/surgeries/\(surgeryId)/share",
            method: "POST",
            body: input,
            requiresAuth: true
        ) as EmptyResponse
    }

    func revoke(surgeryId: String, userId: String) async throws {
        _ = try await client.request(
            path: "/surgeries/\(surgeryId)/share/\(userId)",
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
