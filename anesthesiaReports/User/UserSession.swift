import Foundation
import Combine

@MainActor
final class UserSession: ObservableObject {

    @Published private(set) var user: UserDTO?

    private let storage: AuthStorage
    private let authSession: AuthSession
    private let userAPI = UserAPI()

    init(storage: AuthStorage, authSession: AuthSession) {
        self.storage = storage
        self.authSession = authSession
    }

    // MARK: - Load user

    func loadUser() async throws {
        let user = try await userAPI.getMe()
        self.user = user
    }

    // MARK: - Update user

    func updateUser(_ input: UpdateUserInput) async throws {
        guard let accessToken = storage.getAccessToken() else {
            throw AuthError.sessionExpired
        }

        do {
            let updatedUser = try await userAPI.updateMe(payload: input)
            self.user = updatedUser
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    // MARK: - Delete user

    func deleteUser() async throws {
        guard let accessToken = storage.getAccessToken() else {
            throw AuthError.sessionExpired
        }

        do {
            try await userAPI.deleteMe()
            self.user = nil
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    // MARK: - Related users

    func fetchRelatedUsers(
        company: String? = nil,
        search: String? = nil
    ) async throws -> [RelatedUserDTO] {
        guard let accessToken = storage.getAccessToken() else {
            throw AuthError.sessionExpired
        }

        do {
            return try await userAPI.getRelatedUsers(
                company: company,
                search: search
            )
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    // MARK: - Clear

    func clear() {
        user = nil
    }

#if DEBUG
    func setUserForPreview(_ user: UserDTO?) {
        self.user = user
    }
#endif
}
