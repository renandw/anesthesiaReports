import Foundation

struct AnesthesiaAPI {
    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    func create(input: CreateAnesthesiaInput) async throws -> SurgeryAnesthesiaDetailsDTO {
        let response: SurgeryAnesthesiaResponse = try await client.request(
            path: "/anesthesias",
            method: "POST",
            body: input,
            requiresAuth: true
        )
        return response.anesthesia
    }

    func get(anesthesiaId: String) async throws -> SurgeryAnesthesiaDetailsDTO {
        let response: SurgeryAnesthesiaResponse = try await client.request(
            path: "/anesthesias/\(anesthesiaId)",
            method: "GET",
            requiresAuth: true
        )
        return response.anesthesia
    }

    func getBySurgery(surgeryId: String) async throws -> SurgeryAnesthesiaDetailsDTO {
        let response: SurgeryAnesthesiaResponse = try await client.request(
            path: "/anesthesias/by-surgery/\(surgeryId)",
            method: "GET",
            requiresAuth: true
        )
        return response.anesthesia
    }

    func update(
        anesthesiaId: String,
        input: UpdateAnesthesiaInput
    ) async throws -> SurgeryAnesthesiaDetailsDTO {
        let response: SurgeryAnesthesiaResponse = try await client.request(
            path: "/anesthesias/\(anesthesiaId)",
            method: "PATCH",
            body: input,
            requiresAuth: true
        )
        return response.anesthesia
    }

    func delete(anesthesiaId: String) async throws {
        _ = try await client.request(
            path: "/anesthesias/\(anesthesiaId)",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }
}
