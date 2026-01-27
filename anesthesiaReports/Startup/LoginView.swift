import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var session: AuthSession
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var healthStatus: HealthStatus = .loading
    
    var body: some View {
        
        VStack(spacing: 16) {

            HStack(spacing: 8) {
                Circle()
                    .fill(healthStatus.color)
                    .frame(width: 10, height: 10)
                Text(healthStatus.text)
                    .font(.caption)
                    .foregroundColor(healthStatus.color)
            }
            
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            HStack {
                Group {
                    if showPassword {
                        TextField("Senha", text: $password)
                    } else {
                        SecureField("Senha", text: $password)
                    }
                }
                .textInputAutocapitalization(.never)
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button("Entrar") {
                Task {
                    do {
                        print("➡️ Tentando login com email:", email)
                        try await session.login(
                            email: email,
                            password: password
                        )
                        print("✅ Login concluído com sucesso")
                    } catch let authError as AuthError {
                        print("❌ AuthError recebido:", authError)
                        errorMessage = authError.userMessage
                    } catch {
                        print("❌ Erro genérico recebido:", error)
                        errorMessage = "Erro de rede"
                    }
                }
            }
            
            NavigationLink("Criar conta") {
                RegisterView()
            }
        }
        .padding()
        .task {
            let api = HealthAPI()
            healthStatus = await api.check()
        }
        
    }
}

private extension HealthStatus {
    var text: String {
        switch self {
        case .loading:
            return "Verificando sistema..."
        case .healthy:
            return "Sistema online"
        case .unhealthy:
            return "Sistema indisponível"
        }
    }

    var color: Color {
        switch self {
        case .loading:
            return .secondary
        case .healthy:
            return .green
        case .unhealthy:
            return .red
        }
    }
}
