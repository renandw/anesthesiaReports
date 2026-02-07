import Foundation

struct SharedPreAnesthesiaAPI {
    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    func getBySurgery(surgeryId: String) async throws -> SharedPreAnesthesiaDTO {
        let response: SharedPreAnesthesiaResponse = try await client.request(
            path: "/shared-pre-anesthesia/by-surgery/\(surgeryId)",
            method: "GET",
            requiresAuth: true
        )
        return response.sharedPreAnesthesia
    }
}
