//
//  SyncManager.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//


import Foundation
import SwiftData

@Observable
final class SyncManager {

    enum State: Equatable {
        case idle                  // sessão válida, nada pendente
        case pending               // há mudanças locais
        case syncing               // sync em andamento
        case blocked               // sessão inválida (sessionExpired / unauthenticated)
        case failed(String)        // falha controlada (mensagem para UI)
    }

    private(set) var state: State = .idle

    private let modelContext: ModelContext
    private let authSession: AuthSession

    init(
        modelContext: ModelContext,
        authSession: AuthSession
    ) {
        self.modelContext = modelContext
        self.authSession = authSession
    }

    private func pendingChangeCount() -> Int {
        let descriptor = FetchDescriptor<LocalChangeLog>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Reavalia o estado do sync com base no contexto atual
    func refreshState() {
        guard authSession.state == .authenticated else {
            state = .blocked
            return
        }

        let count = pendingChangeCount()
        state = count > 0 ? .pending : .idle
    }

    /// Placeholder explícito — não implementado ainda
    func syncNow() async {
        guard authSession.state == .authenticated else {
            state = .blocked
            return
        }

        let count = pendingChangeCount()
        guard count > 0 else {
            state = .idle
            return
        }

        state = .syncing

        // Fase 1 / 2:
        // Aqui futuramente ocorrerá:
        // - push do LocalChangeLog
        // - pull incremental
        // - update do SyncState
        // - limpeza do Change Log
        //
        // Por enquanto, apenas sinalizamos que o fluxo é válido.

        await MainActor.run {
            state = .pending
        }
    }

    var hasPendingChanges: Bool {
        pendingChangeCount() > 0
    }
}