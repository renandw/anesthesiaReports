//
//  StartupView.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//


import SwiftUI

struct StartupView: View {

    @SwiftUI.Environment(AuthSession.self) private var authSession

    var body: some View {
        Group {
            switch authSession.state {
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Carregando…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            case .unauthenticated:
                LoginView()

            case .authenticated:
                DashboardView()
                
            case .sessionExpired:
                SessionExpiredView()
            }
        }
        .task {
            await authSession.bootstrap()
        }
    }
}

