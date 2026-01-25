//
//  AuthSession.swift
//  anesthesiaReports
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
    }

    private(set) var state: State = .loading

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
            await handle(error)
        }
    }

    // MARK: - Actions

    func login(email: String, password: String) async {
        state = .loading

        do {
            try await authService.login(email: email, password: password)
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
        await authService.logout()
        state = .unauthenticated
    }

    // MARK: - Error handling

    private func handle(_ error: Error) async {

        let authError = error as? AuthError

        switch authError {

        // 🔐 Sessão inválida → logout silencioso
        case .notAuthenticated,
             .tokenInvalid,
             .userDeleted:
            await authService.logout()
            state = .unauthenticated

        // 👤 Conta bloqueada
        case .userInactive:
            await authService.logout()
            state = .unauthenticated

        // 🔑 Credenciais inválidas (login)
        case .invalidCredentials:
            state = .unauthenticated

        // 🌐 Infra / desconhecido
        default:
            state = .unauthenticated
        }
    }
}