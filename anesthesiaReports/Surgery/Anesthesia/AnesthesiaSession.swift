import Foundation
import Combine

@MainActor
final class AnesthesiaSession: ObservableObject {
    @Published private(set) var anesthesia: SurgeryAnesthesiaDetailsDTO?

    private let authSession: AuthSession
    private let api: AnesthesiaAPI

    init(authSession: AuthSession, api: AnesthesiaAPI) {
        self.authSession = authSession
        self.api = api
    }

    func create(input: CreateAnesthesiaInput) async throws -> SurgeryAnesthesiaDetailsDTO {
        do {
            let response = try await api.create(input: input)
            self.anesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func get(anesthesiaId: String) async throws -> SurgeryAnesthesiaDetailsDTO {
        do {
            let response = try await api.get(anesthesiaId: anesthesiaId)
            self.anesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func getBySurgery(surgeryId: String) async throws -> SurgeryAnesthesiaDetailsDTO {
        do {
            let response = try await api.getBySurgery(surgeryId: surgeryId)
            self.anesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func update(
        anesthesiaId: String,
        input: UpdateAnesthesiaInput
    ) async throws -> SurgeryAnesthesiaDetailsDTO {
        do {
            let response = try await api.update(anesthesiaId: anesthesiaId, input: input)
            self.anesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func delete(anesthesiaId: String) async throws {
        do {
            try await api.delete(anesthesiaId: anesthesiaId)
            self.anesthesia = nil
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }
}
