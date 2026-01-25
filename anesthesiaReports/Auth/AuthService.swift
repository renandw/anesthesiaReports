//
//  AuthService.swift
//  anesthesiaReports
//

import Foundation
import SwiftData

final class AuthService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        let response = try await AuthAPI.login(
            email: email,
            password: password
        )

        await TokenManager.shared.saveTokens(
            accessToken: response.access_token,
            refreshToken: response.refresh_token
        )

        try await loadUserState()
    }

    // MARK: - User State

    /// ÚNICA fonte de verdade do User local
    func loadUserState() async throws {
        let dto = try await AuthAPI.fetchMe()
        try handleUserResponse(dto)
    }

    private func handleUserResponse(_ dto: UserDTO) throws {

        let users = try modelContext.fetch(FetchDescriptor<User>())
        let existingUser = users.first { $0.userId == dto.user_id }

        if let user = existingUser {
            user.update(from: dto)
        } else {
            let user = User.from(dto: dto)
            modelContext.insert(user)
        }

        updateUserSyncState(from: dto)
    }

    // MARK: - SyncState

    private func updateUserSyncState(from dto: UserDTO) {
        let syncState = fetchOrCreateSyncState(scope: .user)
        syncState.lastStatusChangedAt = dto.status_changed_at
    }

    // MARK: - Register

    func register(
        userName: String,
        email: String,
        password: String,
        crmNumberUf: String,
        rqe: String?
    ) async throws {

        let request = RegisterRequest(
            user_name: userName,
            email: email,
            password: password,
            crm_number_uf: crmNumberUf,
            rqe: rqe
        )

        _ = try await AuthAPI.register(requestBody: request)
    }

    // MARK: - Logout

    // Fase 1 — sessão expirada (não destrutivo)
    func invalidateSession() async {
        await TokenManager.shared.clearAccessToken()
        // refresh token é mantido para possível reautenticação
    }

    // Logout explícito (fase 2) — destrutivo
    func logout() async {
        try? await AuthAPI.logout()
        await finalizeLogout()
    }

    // Encerramento definitivo da sessão (wipe local)
    func finalizeLogout() async {
        await TokenManager.shared.clearSession()
        try? clearLocalData()
    }

    // MARK: - Local persistence

    private func fetchOrCreateSyncState(scope: SyncScope) -> SyncState {

        let scopeValue = scope.rawValue

        let descriptor = FetchDescriptor<SyncState>(
            predicate: #Predicate { $0.scopeRawValue == scopeValue }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let syncState = SyncState(scope: scope)
        modelContext.insert(syncState)
        return syncState
    }

    private func clearLocalData() throws {

        let users = try modelContext.fetch(FetchDescriptor<User>())
        users.forEach { modelContext.delete($0) }

        // outros domínios entram aqui futuramente
    }
    
    func hasPendingLocalChanges() throws -> Bool {
        let descriptor = FetchDescriptor<LocalChangeLog>(
            sortBy: [.init(\.createdAt)]
        )
        
        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }
}
