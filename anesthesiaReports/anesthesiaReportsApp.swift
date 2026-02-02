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
        let patientSession = PatientSession(authSession: authSession, api: PatientAPI())
        let surgerySession = SurgerySession(authSession: authSession, api: SurgeryAPI())
        authSession.attachUserSession(userSession)
        self.authSession = authSession
        self.userSession = userSession
        self.patientSession = patientSession
        self.surgerySession = surgerySession
    }

    var body: some Scene {
        WindowGroup {
            StartupView()
                .environmentObject(authSession)
                .environmentObject(userSession)
                .environmentObject(patientSession)
                .environmentObject(surgerySession)
        }
    }
    
    // MARK: - Sessions

    private let userSession: UserSession
    private let authSession: AuthSession
    private let patientSession: PatientSession
    private let surgerySession: SurgerySession
}
