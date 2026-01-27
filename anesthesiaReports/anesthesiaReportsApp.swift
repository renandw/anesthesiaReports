//
//  anesthesiaReportsApp.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//

import SwiftUI

@main
struct anesthesiaReportsApp: App {
    var body: some Scene {
        WindowGroup {
            StartupView()
                .environmentObject(authSession)
        }
    }
    
    // MARK: - AuthSession
    
    private let authSession = AuthSession()
}
