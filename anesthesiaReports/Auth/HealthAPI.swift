import Foundation

struct HealthAPI {
    private let baseURL = URL(string: "https://fichasanestesicas.bomsucessoserver.com")!

    func check(timeoutSeconds: UInt64 = 5) async -> HealthStatus {
        var request = URLRequest(url: baseURL.appendingPathComponent("/health"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return await withTaskGroup(of: HealthStatus.self) { group in
            group.addTask {
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    // If the device is offline, this request fails and we return .unhealthy.
                    // A future HealthMonitorGlobal can call this on a schedule and publish app-wide state.
                    guard let http = response as? HTTPURLResponse,
                          (200...299).contains(http.statusCode) else {
                        return .unhealthy
                    }

                    let decoder = JSONDecoder()
                    let decoded = try await MainActor.run {
                        try decoder.decode(HealthResponse.self, from: data)
                    }
                    if decoded.status == "ok",
                       decoded.services.api == "up",
                       decoded.services.db == "up" {
                        return .healthy
                    }
                    return .unhealthy
                } catch {
                    return .unhealthy
                }
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                return .unhealthy
            }

            let result = await group.next() ?? .unhealthy
            group.cancelAll()
            return result
        }
    }
}

enum HealthStatus {
    case loading
    case healthy
    case unhealthy
}

private struct HealthResponse: Decodable {
    let status: String
    let services: Services

    struct Services: Decodable {
        let api: String
        let db: String
    }
}
