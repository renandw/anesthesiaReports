import Foundation
import Combine

@MainActor
final class FinancialService: ObservableObject {
    @Published private(set) var financial: SurgeryFinancialDetailsDTO?

    private let authSession: AuthSession
    private let api: FinancialAPI

    init(authSession: AuthSession, api: FinancialAPI? = nil) {
        self.authSession = authSession
        self.api = api ?? FinancialAPI()
    }

    func get(surgeryId: String) async throws -> SurgeryFinancialDetailsDTO {
        do {
            let dto = try await api.get(surgeryId: surgeryId)
            self.financial = dto
            return dto
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func update(
        surgeryId: String,
        input: UpdateSurgeryFinancialInput
    ) async throws -> SurgeryFinancialDetailsDTO {
        do {
            let dto = try await api.update(surgeryId: surgeryId, input: input)
            self.financial = dto
            return dto
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func delete(surgeryId: String) async throws {
        do {
            try await api.delete(surgeryId: surgeryId)
            self.financial = nil
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }
}
