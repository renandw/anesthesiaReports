import Foundation

struct PreanesthesiaAPI {
    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    func create(input: CreatePreanesthesiaInput) async throws -> SurgeryPreanesthesiaDetailsDTO {
        let response: SurgeryPreanesthesiaResponse = try await client.request(
            path: "/preanesthesia",
            method: "POST",
            body: input,
            requiresAuth: true
        )
        return response.preanesthesia
    }

    func get(preanesthesiaId: String) async throws -> SurgeryPreanesthesiaDetailsDTO {
        let response: SurgeryPreanesthesiaResponse = try await client.request(
            path: "/preanesthesia/\(preanesthesiaId)",
            method: "GET",
            requiresAuth: true
        )
        return response.preanesthesia
    }

    func getBySurgery(surgeryId: String) async throws -> SurgeryPreanesthesiaDetailsDTO {
        let response: SurgeryPreanesthesiaResponse = try await client.request(
            path: "/preanesthesia/by-surgery/\(surgeryId)",
            method: "GET",
            requiresAuth: true
        )
        return response.preanesthesia
    }

    func update(preanesthesiaId: String, input: UpdatePreanesthesiaInput) async throws -> SurgeryPreanesthesiaDetailsDTO {
        let response: SurgeryPreanesthesiaResponse = try await client.request(
            path: "/preanesthesia/\(preanesthesiaId)",
            method: "PATCH",
            body: input,
            requiresAuth: true
        )
        return response.preanesthesia
    }

    func delete(preanesthesiaId: String) async throws {
        _ = try await client.request(
            path: "/preanesthesia/\(preanesthesiaId)",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }
}
