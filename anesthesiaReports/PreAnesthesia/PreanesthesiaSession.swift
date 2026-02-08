import Foundation
import Combine

@MainActor
final class PreanesthesiaSession: ObservableObject {
    @Published private(set) var preanesthesia: SurgeryPreanesthesiaDetailsDTO?
    @Published private(set) var clearance: PreanesthesiaClearanceDTO?

    private let authSession: AuthSession
    private let api: PreanesthesiaAPI

    init(authSession: AuthSession, api: PreanesthesiaAPI) {
        self.authSession = authSession
        self.api = api
    }

    func create(input: CreatePreanesthesiaInput) async throws -> SurgeryPreanesthesiaDetailsDTO {
        do {
            let response = try await api.create(input: input)
            self.preanesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func get(preanesthesiaId: String) async throws -> SurgeryPreanesthesiaDetailsDTO {
        do {
            let response = try await api.get(preanesthesiaId: preanesthesiaId)
            self.preanesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func getBySurgery(surgeryId: String) async throws -> SurgeryPreanesthesiaDetailsDTO {
        do {
            let response = try await api.getBySurgery(surgeryId: surgeryId)
            self.preanesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func update(preanesthesiaId: String, input: UpdatePreanesthesiaInput) async throws -> SurgeryPreanesthesiaDetailsDTO {
        do {
            let response = try await api.update(preanesthesiaId: preanesthesiaId, input: input)
            self.preanesthesia = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func delete(preanesthesiaId: String) async throws {
        do {
            try await api.delete(preanesthesiaId: preanesthesiaId)
            self.preanesthesia = nil
            self.clearance = nil
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func getClearance(preanesthesiaId: String) async throws -> PreanesthesiaClearanceDTO {
        do {
            let response = try await api.getClearance(preanesthesiaId: preanesthesiaId)
            self.clearance = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func upsertClearance(preanesthesiaId: String, input: UpsertPreanesthesiaClearanceInput) async throws -> PreanesthesiaClearanceDTO {
        do {
            let response = try await api.upsertClearance(preanesthesiaId: preanesthesiaId, input: input)
            self.clearance = response
            return response
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func deleteClearance(preanesthesiaId: String) async throws {
        do {
            try await api.deleteClearance(preanesthesiaId: preanesthesiaId)
            self.clearance = nil
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }
}
