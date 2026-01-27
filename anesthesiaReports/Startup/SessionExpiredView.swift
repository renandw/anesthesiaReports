import SwiftUI

struct SessionExpiredView: View {

    @EnvironmentObject private var session: AuthSession

    var body: some View {
        VStack(spacing: 16) {

            Text("Sessão expirada")
                .font(.headline)

            Text("Por favor, autentique-se novamente.")
                .multilineTextAlignment(.center)

            Button("Ir para login") {
                session.acknowledgeSessionExpired()
            }

            Button("Logout") {
                Task {
                    await session.logout()
                }
            }
        }
        .padding()
    }
}
