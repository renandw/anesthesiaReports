//
//  anesthesiaReportsApp.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//

import SwiftUI
import SwiftData

@main
struct anesthesiaReportsApp: App {

    // MARK: - SwiftData

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: User.self, SyncState.self)
        } catch {
            fatalError("Erro ao criar ModelContainer: \(error)")
        }
    }()

    // MARK: - Session

    @State private var authSession: AuthSession

    init() {
        let context = modelContainer.mainContext
        _authSession = State(initialValue: AuthSession(modelContext: context))
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            StartupView()
                .environment(authSession)
                .modelContainer(modelContainer)
        }
    }
}
