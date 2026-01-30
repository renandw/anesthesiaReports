import SwiftUI

struct DashboardView: View {

    @EnvironmentObject private var session: AuthSession
    @EnvironmentObject private var userSession: UserSession

    var body: some View {
        ScrollView {
            if let user = userSession.user {
                VStack{
                    VStack(alignment: .center, spacing: 16) {
                        
                        Text("Bem-vindo, \(user.name)")
                            .font(.headline)
                        
                        Text(user.email)
                            .foregroundColor(.secondary)
                        
                        Text(user.rqe ?? "")
                        
                        NavigationLink("Detalhes do Usuário") {
                            UserDetailsView()
                        }
                        
                        NavigationLink("Lista de Pacientes") {
                            PatientsListView()
                        }
                        
                        NavigationLink("Editar Usuário") {
                            EditUserView()
                        }
                        
                        
                    }
                    .padding()
                    .background(.white)
                    .navigationTitle("Olá, \(user.name)")
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    Button("Logout") {
                        Task {
                            await session.logout()
                        }
                    }
                    .padding()
                    .buttonStyle(.glassProminent)
                }
            }
            
            
        }
        .background(Color(.tertiarySystemGroupedBackground))
    }
}
