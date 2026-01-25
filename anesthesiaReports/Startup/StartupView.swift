//
//  StartupView.swift
//  anesthesiaReports
//

import SwiftUI

struct StartupView: View {

    @Environment(AuthSession.self) private var authSession

    var body: some View {
        Group {
            switch authSession.state {

            case .loading:
                loadingView

            case .unauthenticated:
                LoginView()

            case .authenticated:
                DashboardView()
            }
        }
        .task {
            // Executado uma única vez quando a view aparece
            await authSession.bootstrap()
        }
    }

    // MARK: - Loading UI

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Carregando…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}