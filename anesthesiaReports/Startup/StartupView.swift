import SwiftUI
import SwiftData

struct StartupView: View {

    @EnvironmentObject private var session: AuthSession
    @State private var healthStatus: HealthStatus = .loading
    @State private var didCheckHealth = false
    @State private var didBootstrap = false
    @State private var isCheckingHealthNow = false
    @State private var lastHealthCheckAt: Date?
    @State private var healthPollingTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                switch session.state {
                case .loading:
                    switch healthStatus {
                    case .loading:
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Conectando com o servidor...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    case .healthy:
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Verificando sessão...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    case .unhealthy:
                        SystemUnavailableView(
                            lastCheckedAt: lastHealthCheckAt,
                            isRetrying: isCheckingHealthNow,
                            onRetry: { await retryHealthNow() }
                        )
                    }
                    
                case .unauthenticated:
                    switch healthStatus {
                    case .loading:
                        ProgressView()
                    case .healthy:
                        LoginView()
                    case .unhealthy:
                        SystemUnavailableView(
                            lastCheckedAt: lastHealthCheckAt,
                            isRetrying: isCheckingHealthNow,
                            onRetry: { await retryHealthNow() }
                        )
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
                    await refreshHealthStatus()
                }
                await bootstrapIfPossible()
            }
            .onChange(of: healthStatus) { _, newValue in
                if newValue == .unhealthy {
                    startHealthPollingIfNeeded()
                } else {
                    stopHealthPolling()
                }
            }
            .onDisappear {
                stopHealthPolling()
            }
        }
    }

    @MainActor
    private func refreshHealthStatus() async {
        isCheckingHealthNow = true
        let newStatus = await HealthAPI().check()
        healthStatus = newStatus
        lastHealthCheckAt = Date()
        isCheckingHealthNow = false
    }

    @MainActor
    private func retryHealthNow() async {
        await refreshHealthStatus()
        await bootstrapIfPossible()
    }

    @MainActor
    private func bootstrapIfPossible() async {
        if session.state == .loading,
           healthStatus == .healthy,
           !didBootstrap {
            didBootstrap = true
            await session.bootstrap()
        }
    }

    @MainActor
    private func startHealthPollingIfNeeded() {
        guard healthPollingTask == nil else { return }

        healthPollingTask = Task {
            var attempt = 0
            while !Task.isCancelled {
                attempt += 1
                let intervalSeconds: UInt64
                if attempt <= 3 {
                    intervalSeconds = 5
                } else if attempt <= 8 {
                    intervalSeconds = 10
                } else {
                    intervalSeconds = 15
                }

                try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
                if Task.isCancelled { break }
                let shouldContinue = await MainActor.run { healthStatus == .unhealthy }
                if !shouldContinue { break }

                let newStatus = await HealthAPI().check()
                await MainActor.run {
                    healthStatus = newStatus
                    lastHealthCheckAt = Date()
                }

                if newStatus == .healthy {
                    await bootstrapIfPossible()
                    break
                }
            }

            await MainActor.run {
                healthPollingTask = nil
            }
        }
    }

    @MainActor
    private func stopHealthPolling() {
        healthPollingTask?.cancel()
        healthPollingTask = nil
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
    let lastCheckedAt: Date?
    let isRetrying: Bool
    let onRetry: () async -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Servidor indisponível")
                .font(.headline)
            Text("Reconectando...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let lastCheckedAt {
                Text("Última verificação: \(DateFormatterHelper.format(lastCheckedAt, dateStyle: .none, timeStyle: .medium))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await onRetry() }
            } label: {
                HStack(spacing: 8) {
                    if isRetrying {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(isRetrying ? "Verificando..." : "Tentar novamente agora")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
        }
        .padding()
    }
}

#Preview("Sistema Indisponível") {
    SystemUnavailableView(
        lastCheckedAt: Date(),
        isRetrying: false,
        onRetry: {}
    )
}
