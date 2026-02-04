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
                    switch healthStatus {
                    case .loading:
                        ProgressView()
                    case .healthy:
                        ProgressView()
                    case .unhealthy:
                        SystemUnavailableView()
                    }
                    
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

#if DEBUG
struct StartupView_Previews: PreviewProvider {
    static var previews: some View {
        let authSession = AuthSession()
        let storage = AuthStorage()
        let userSession = UserSession(storage: storage, authSession: authSession)
        authSession.attachUserSession(userSession)

        userSession.setUserForPreview(
            UserDTO(
                id: UUID().uuidString,
                name: "Renan Wrobel",
                email: "renandw@me.com",
                crm: "CRM12345",
                rqe: "123456",
                phone: "69981328798",
                company: [.known(.cma), .known(.clian)],
                role: .admin,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date(),
                statusChangedAt: Date(),
                isDeleted: false
            )
        )
        authSession.setStateForPreview(.authenticated)

        return StartupView()
            .environmentObject(authSession)
            .environmentObject(userSession)
    }
}
#endif

private struct SystemUnavailableView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Servidor indisponível")
                .font(.headline)
            Text("Reconectando...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Sistema Indisponível") {
    SystemUnavailableView()
}
