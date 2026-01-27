import SwiftUI

struct DashboardView: View {

    @EnvironmentObject private var session: AuthSession

    var body: some View {
        VStack(spacing: 16) {

            if let user = session.user {
                Text("Bem-vindo, \(user.name)")
                    .font(.headline)

                Text(user.email)
                    .foregroundColor(.secondary)
                let rqe = user.rqe ?? ""
                Text(rqe)
            }

            Button("Logout") {
                Task {
                    await session.logout()
                }
            }
            NavigationLink("Editar Usuário") {
                EditUserView()
            }
            NavigationLink("Compartilhar com") {
                CanShareWithView()
            }
        }
        .padding()
    }
}
