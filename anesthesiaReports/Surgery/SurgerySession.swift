import Foundation
import Combine

@MainActor
final class SurgerySession: ObservableObject {
    @Published private(set) var surgeries: [SurgeryDTO] = []

    private let authSession: AuthSession
    private let api: SurgeryAPI

    init(authSession: AuthSession, api: SurgeryAPI) {
        self.authSession = authSession
        self.api = api
    }

    func list(search: String? = nil) async throws {
        do {
            let list = try await api.list(search: search)
            self.surgeries = list
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func listByPatient(patientId: String) async throws -> [SurgeryDTO] {
        do {
            let list = try await api.listByPatient(patientId: patientId)
            self.surgeries = list
            return list
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func getById(_ surgeryId: String) async throws -> SurgeryDTO {
        do {
            return try await api.getById(surgeryId)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func create(_ input: CreateSurgeryInput) async throws -> SurgeryDTO {
        do {
            let surgery = try await api.create(input)
            surgeries.insert(surgery, at: 0)
            return surgery
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func update(surgeryId: String, input: UpdateSurgeryInput) async throws -> SurgeryDTO {
        do {
            let surgery = try await api.update(surgeryId: surgeryId, input: input)
            if let index = surgeries.firstIndex(where: { $0.id == surgeryId }) {
                surgeries[index] = surgery
            }
            return surgery
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    // MARK: - Sharing

    func listShares(surgeryId: String) async throws -> [SurgeryShareDTO] {
        do {
            return try await api.listShares(surgeryId: surgeryId)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func share(surgeryId: String, input: ShareSurgeryInput) async throws {
        do {
            try await api.share(surgeryId: surgeryId, input: input)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func revoke(surgeryId: String, userId: String) async throws {
        do {
            try await api.revoke(surgeryId: surgeryId, userId: userId)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }
}
