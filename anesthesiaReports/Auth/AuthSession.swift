//
//  AuthSession.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AuthSession {

    enum State: Equatable {
        case loading
        case unauthenticated
        case authenticated
        case sessionExpired
    }

    private(set) var state: State = .loading
    private(set) var hasPendingChanges: Bool = false
    private let authService: AuthService

    init(modelContext: ModelContext) {
        self.authService = AuthService(modelContext: modelContext)
    }

    // MARK: - Bootstrap

    /// Chamado na inicialização do app
    func bootstrap() async {
        state = .loading

        do {
            try await authService.loadUserState()
            state = .authenticated
        } catch {
            await handleBootstrapError(error)
        }
    }

    private func handleBootstrapError(_ error: Error) async {
        let authError = error as? AuthError

        switch authError {
        case .notAuthenticated,
             .sessionExpired:
            // Sessão expirada: dados preservados
            state = .sessionExpired

        case .userDeleted,
             .userInactive:
            // Invalidação definitiva
            await authService.logout()
            state = .unauthenticated

        default:
            state = .unauthenticated
        }
    }

    // MARK: - Actions

    func login(email: String, password: String) async {
        state = .loading

        do {
            try await authService.login(email: email, password: password)
            await updatePendingChanges()
            state = .authenticated
        } catch {
            await handle(error)
        }
    }

    func register(
        userName: String,
        email: String,
        password: String,
        crmNumberUf: String,
        rqe: String?
    ) async throws {
        try await authService.register(
            userName: userName,
            email: email,
            password: password,
            crmNumberUf: crmNumberUf,
            rqe: rqe
        )
    }

    func logout() async {
        // Logout explícito: encerra sessão e apaga dados locais
        await authService.logout()
        state = .unauthenticated
    }

    // MARK: - Error handling

    private func handle(_ error: Error) async {

        let authError = error as? AuthError

        switch authError {

        case .notAuthenticated,
             .sessionExpired:
            // Sessão expirada durante uso normal
            state = .sessionExpired

        case .userDeleted,
             .userInactive:
            // Backend invalidou definitivamente
            await authService.logout()
            state = .unauthenticated

        case .invalidCredentials:
            state = .unauthenticated

        default:
            state = .unauthenticated
        }
    }

    private func updatePendingChanges() async {
        do {
            hasPendingChanges = try authService.hasPendingLocalChanges()
        } catch {
            hasPendingChanges = false
        }
    }
}
