//
//  AuthService.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//


import Foundation
import SwiftData

final class AuthService {

    private let api: AuthAPI
    private let modelContext: ModelContext

    init(api: AuthAPI, modelContext: ModelContext) {
        self.api = api
        self.modelContext = modelContext
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        let response = try await api.login(
            email: email,
            password: password
        )

        // tokens → Keychain (fora daqui)
        saveTokens(response)

        try await loadUserState()
    }

    // MARK: - Refresh

    func refreshSession() async throws {
        let response = try await api.refresh()
        saveTokens(response)

        try await loadUserState()
    }

    // MARK: - User State

    private func loadUserState() async throws {
        let dto = try await api.fetchMe()
        try handleUserResponse(dto)
    }

    private func handleUserResponse(_ dto: UserDTO) throws {

        // buscar usuário local
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.userId == dto.user_id }
        )

        let users = try modelContext.fetch(descriptor)

        if let user = users.first {
            // atualização
            user.update(from: dto)
        } else {
            // criação
            let user = User.from(dto: dto)
            modelContext.insert(user)
        }

        // atualizar SyncState (scope: user)
        updateUserSyncState(from: dto)
    }

    // MARK: - SyncState

    private func updateUserSyncState(from dto: UserDTO) {
        let syncState = fetchOrCreateSyncState(scope: .user)
        syncState.lastStatusChangedAt = dto.status_changed_at
    }

    // MARK: - Logout

    func logout() throws {
        clearTokens()
        try clearLocalData()
    }
}