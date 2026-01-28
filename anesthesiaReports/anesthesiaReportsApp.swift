//
//  anesthesiaReportsApp.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//

import SwiftUI

@main
struct anesthesiaReportsApp: App {
    init() {
        let storage = AuthStorage()
        let authSession = AuthSession()
        let userSession = UserSession(storage: storage, authSession: authSession)
        authSession.attachUserSession(userSession)
        self.authSession = authSession
        self.userSession = userSession
    }

    var body: some Scene {
        WindowGroup {
            StartupView()
                .environmentObject(authSession)
                .environmentObject(userSession)
        }
    }
    
    // MARK: - Sessions

    private let userSession: UserSession
    private let authSession: AuthSession
}
