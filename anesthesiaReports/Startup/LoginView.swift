import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var session: AuthSession
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var healthStatus: HealthStatus = .loading
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                
                // Logo ou Ícone
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.bottom, 40)
                HStack(spacing: 8) {
                    Circle()
                        .fill(healthStatus.color)
                        .frame(width: 10, height: 10)
                    Text(healthStatus.text)
                        .font(.caption)
                        .foregroundColor(healthStatus.color)
                }
                Form {
                    Section{
                        
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                        
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
                                    .foregroundStyle(showPassword ? .primary : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                    Section {
                        Button(action: {
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
                        }) {
                            Text("Entrar")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.blue)
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: 230)
                
                NavigationLink("Criar conta") {
                    RegisterView()
                }
                .padding(.top, 20)
                
                Spacer()
                Spacer()
                
            }
            .padding()
            .task {
                let api = HealthAPI()
                healthStatus = await api.check()
            }
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

#Preview {
    NavigationStack {
        LoginView()
    }
}
