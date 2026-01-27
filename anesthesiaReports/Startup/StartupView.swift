import SwiftUI
import SwiftData

struct StartupView: View {

    @EnvironmentObject private var session: AuthSession
    @State private var healthStatus: HealthStatus = .loading
    @State private var didCheckHealth = false
    @State private var didBootstrap = false

    var body: some View {
        NavigationStack {
            Group {
                switch session.state {
                case .loading:
                    ProgressView()
                    
                case .unauthenticated:
                    switch healthStatus {
                    case .loading:
                        ProgressView()
                    case .healthy:
                        LoginView()
                    case .unhealthy:
                        SystemUnavailableView()
                    }
                    
                case .authenticated:
                    DashboardView()
                    
                case .sessionExpired:
                    SessionExpiredView()
                }
            }
            .task {
                if !didCheckHealth {
                    didCheckHealth = true
                    healthStatus = await HealthAPI().check()
                }
                if healthStatus == .unhealthy {
                    await pollHealthUntilRecovered()
                }
                if session.state == .loading,
                   healthStatus == .healthy,
                   !didBootstrap {
                    didBootstrap = true
                    await session.bootstrap()
                }
            }
        }
    }

    private func pollHealthUntilRecovered() async {
        // If we later need global monitoring, extract this to a shared HealthMonitor
        // that pushes state changes to all views (login, dashboard, etc).
        while healthStatus == .unhealthy {
            try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
            let newStatus = await HealthAPI().check()
            healthStatus = newStatus
        }
    }
}

private struct SystemUnavailableView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Sistema indisponível")
                .font(.headline)
            Text("Aguardando o serviço voltar...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
