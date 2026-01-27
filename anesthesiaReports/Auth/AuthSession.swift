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
    @Published private(set) var user: UserDTO?

    private let storage = AuthStorage()
    private let api = AuthAPI()
    private let userAPI = UserAPI()

    init() {}

    // MARK: - Bootstrap

    func bootstrap() async {
        guard let refresh = storage.getRefreshToken() else {
            state = .unauthenticated
            return
        }

        do {
            let response = try await api.refresh(refreshToken: refresh)
            storage.save(
                accessToken: response.access_token,
                refreshToken: response.refresh_token
            )
            let user = try await userAPI.getMe(
                accessToken: response.access_token
            )
            self.user = user
            state = .authenticated
        } catch {
            storage.clear()
            self.user = nil
            state = .sessionExpired
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        let response = try await api.login(email: email, password: password)

        storage.save(
            accessToken: response.access_token,
            refreshToken: response.refresh_token
        )
        let user = try await userAPI.getMe(
            accessToken: response.access_token
        )
        self.user = user
        state = .authenticated
    }

    // MARK: - Register

    func register(_ input: RegisterInput) async throws {
        _ = try await api.register(input)
    }
    
    // MARK: - Update User

    func updateUser(_ input: UpdateUserInput) async throws {
        guard let accessToken = storage.getAccessToken() else {
            throw AuthError.sessionExpired
        }

        let updatedUser = try await userAPI.updateMe(
            accessToken: accessToken,
            payload: input
        )

        self.user = updatedUser
    }

    // MARK: - Related users

    func fetchRelatedUsers(
        company: String? = nil,
        search: String? = nil
    ) async throws -> [RelatedUserDTO] {
        guard let accessToken = storage.getAccessToken() else {
            throw AuthError.sessionExpired
        }

        return try await userAPI.getRelatedUsers(
            accessToken: accessToken,
            company: company,
            search: search
        )
    }

    // MARK: - Delete User

    func deleteUser() async throws {
        guard let accessToken = storage.getAccessToken() else {
            throw AuthError.sessionExpired
        }

        try await userAPI.deleteMe(accessToken: accessToken)
        await logout()
    }
    
    // MARK: - Expired
    
    func acknowledgeSessionExpired() {
        state = .unauthenticated
    }

    // MARK: - Logout

    func logout() async {
        storage.clear()
        user = nil
        state = .unauthenticated
    }
}
