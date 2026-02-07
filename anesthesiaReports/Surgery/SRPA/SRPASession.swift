import Foundation
import Combine

@MainActor
final class SRPASession: ObservableObject {
    @Published private(set) var srpa: SurgerySRPADetailsDTO?

    private let authSession: AuthSession
    private let api: SRPAAPI

    init(authSession: AuthSession, api: SRPAAPI) {
        self.authSession = authSession
        self.api = api
    }

    func create(input: CreateSRPAInput) async throws -> SurgerySRPADetailsDTO {
        do {
            let response = try await api.create(input: input)
            self.srpa = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func get(srpaId: String) async throws -> SurgerySRPADetailsDTO {
        do {
            let response = try await api.get(srpaId: srpaId)
            self.srpa = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func getBySurgery(surgeryId: String) async throws -> SurgerySRPADetailsDTO {
        do {
            let response = try await api.getBySurgery(surgeryId: surgeryId)
            self.srpa = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func update(srpaId: String, input: UpdateSRPAInput) async throws -> SurgerySRPADetailsDTO {
        do {
            let response = try await api.update(srpaId: srpaId, input: input)
            self.srpa = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func delete(srpaId: String) async throws {
        do {
            try await api.delete(srpaId: srpaId)
            self.srpa = nil
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }
}
