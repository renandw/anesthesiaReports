import Foundation

struct FinancialAPI {
    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    func get(surgeryId: String) async throws -> SurgeryFinancialDetailsDTO {
        let decoded: FinancialResponse = try await client.request(
            path: "/surgeries/\(surgeryId)/financial",
            method: "GET",
            requiresAuth: true
        )
        return decoded.financial
    }

    func update(
        surgeryId: String,
        input: UpdateSurgeryFinancialInput
    ) async throws -> SurgeryFinancialDetailsDTO {
        let decoded: FinancialResponse = try await client.request(
            path: "/surgeries/\(surgeryId)/financial",
            method: "PATCH",
            body: input,
            requiresAuth: true
        )
        return decoded.financial
    }

    func delete(surgeryId: String) async throws {
        _ = try await client.request(
            path: "/surgeries/\(surgeryId)/financial",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }
}
