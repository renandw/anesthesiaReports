import Foundation
import Combine

@MainActor
final class AuthSession: ObservableObject {

    enum State {
        case loading
        case unauthenticated
        case authenticated
        case sessionExpired
    }

    @Published private(set) var state: State = .loading

    private let tokenManager = TokenManager.shared
    private var userSession: UserSession?
    private let api = AuthAPI()

    init() {}

    func attachUserSession(_ userSession: UserSession) {
        self.userSession = userSession
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard tokenManager.refreshToken() != nil else {
            state = .unauthenticated
            return
        }

        do {
            _ = try await tokenManager.refresh()
            guard let userSession else {
                state = .unauthenticated
                return
            }
            try await userSession.loadUser()
            state = .authenticated
        } catch {
            tokenManager.clear()
            userSession?.clear()
            state = .sessionExpired
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        let response = try await api.login(email: email, password: password)

        tokenManager.saveTokens(
            access: response.access_token,
            refresh: response.refresh_token
        )
        guard let userSession else {
            state = .unauthenticated
            return
        }
        try await userSession.loadUser()
        state = .authenticated
    }

    // MARK: - Register

    func register(_ input: RegisterInput) async throws {
        _ = try await api.register(input)
    }
    
    // MARK: - Expired
    
    func acknowledgeSessionExpired() {
        state = .unauthenticated
    }

    // MARK: - Fatal auth errors

    func handleFatalAuthError(_ error: AuthError) {
        guard error.isFatalSessionError else { return }
        tokenManager.clear()
        userSession?.clear()
        state = .sessionExpired
    }

    // MARK: - Logout

    func logout() async {
        tokenManager.clear()
        userSession?.clear()
        state = .unauthenticated
    }

#if DEBUG
    func setStateForPreview(_ state: State) {
        self.state = state
    }
#endif
}
