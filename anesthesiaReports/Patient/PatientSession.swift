import Foundation
import Combine
import Combine

@MainActor
final class PatientSession: ObservableObject {
    @Published private(set) var patients: [PatientDTO] = []

    private let authSession: AuthSession
    private let api: PatientAPI

    init(authSession: AuthSession, api: PatientAPI) {
        self.authSession = authSession
        self.api = api
    }

    func list(search: String? = nil) async throws {
        do {
            let list = try await api.list(search: search)
            self.patients = list
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func listSharedWithMe(search: String? = nil) async throws {
        do {
            let list = try await api.listSharedWithMe(search: search)
            self.patients = list
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func listSharedByMe(search: String? = nil) async throws {
        do {
            let list = try await api.listSharedByMe(search: search)
            self.patients = list
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func getById(_ patientId: String) async throws -> PatientDTO {
        do {
            return try await api.getById(patientId)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func create(_ input: CreatePatientInput) async throws -> PatientDTO {
        do {
            let patient = try await api.create(input)
            patients.insert(patient, at: 0)
            return patient
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func update(patientId: String, input: UpdatePatientInput) async throws -> PatientDTO {
        do {
            let patient = try await api.update(patientId: patientId, input: input)
            if let index = patients.firstIndex(where: { $0.id == patientId }) {
                patients[index] = patient
            }
            return patient
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func delete(patientId: String) async throws {
        do {
            try await api.delete(patientId: patientId)
            patients.removeAll { $0.id == patientId }
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    // MARK: - Dedup

    func precheck(input: CreatePatientInput) async throws -> [PrecheckMatchDTO] {
        do {
            return try await api.precheck(input: input)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func claim(patientId: String) async throws {
        do {
            try await api.claim(patientId: patientId)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func listShares(patientId: String) async throws -> [PatientShareDTO] {
        do {
            return try await api.listShares(patientId: patientId)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func share(patientId: String, input: SharePatientInput) async throws {
        do {
            try await api.share(patientId: patientId, input: input)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }

    func revokeShare(patientId: String, userId: String) async throws {
        do {
            try await api.revoke(patientId: patientId, userId: userId)
        } catch let authError as AuthError {
            authSession.handleFatalAuthError(authError)
            throw authError
        }
    }
}
