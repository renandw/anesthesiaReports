import Foundation

struct SRPAAPI {
    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    func create(input: CreateSRPAInput) async throws -> SurgerySRPADetailsDTO {
        let response: SurgerySRPAResponse = try await client.request(
            path: "/srpa",
            method: "POST",
            body: input,
            requiresAuth: true
        )
        return response.srpa
    }

    func get(srpaId: String) async throws -> SurgerySRPADetailsDTO {
        let response: SurgerySRPAResponse = try await client.request(
            path: "/srpa/\(srpaId)",
            method: "GET",
            requiresAuth: true
        )
        return response.srpa
    }

    func getBySurgery(surgeryId: String) async throws -> SurgerySRPADetailsDTO {
        let response: SurgerySRPAResponse = try await client.request(
            path: "/srpa/by-surgery/\(surgeryId)",
            method: "GET",
            requiresAuth: true
        )
        return response.srpa
    }

    func update(srpaId: String, input: UpdateSRPAInput) async throws -> SurgerySRPADetailsDTO {
        let response: SurgerySRPAResponse = try await client.request(
            path: "/srpa/\(srpaId)",
            method: "PATCH",
            body: input,
            requiresAuth: true
        )
        return response.srpa
    }

    func delete(srpaId: String) async throws {
        _ = try await client.request(
            path: "/srpa/\(srpaId)",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }
}
