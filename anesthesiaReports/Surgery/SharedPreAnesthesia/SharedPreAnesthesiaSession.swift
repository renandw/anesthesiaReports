import Foundation
import Combine

@MainActor
final class SharedPreAnesthesiaSession: ObservableObject {
    @Published private(set) var sharedPreAnesthesia: SharedPreAnesthesiaDTO?

    private let authSession: AuthSession
    private let api: SharedPreAnesthesiaAPI

    init(authSession: AuthSession, api: SharedPreAnesthesiaAPI? = nil) {
        self.authSession = authSession
        self.api = api ?? SharedPreAnesthesiaAPI()
    }

    func getBySurgery(surgeryId: String) async throws -> SharedPreAnesthesiaDTO {
        do {
            let response = try await api.getBySurgery(surgeryId: surgeryId)
            self.sharedPreAnesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }
}
