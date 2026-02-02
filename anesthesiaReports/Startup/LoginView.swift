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
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(healthStatus.color)
                        .frame(width: 8, height: 8)
                    Text(healthStatus.text)
                        .font(.caption)
                        .foregroundColor(healthStatus.color)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(healthStatus.color.opacity(0.12))
                .clipShape(Capsule())

                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.blue)

                    Text("Entrar")
                        .font(.title2.weight(.semibold))
                }

                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
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
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(showPassword ? .primary : .secondary)
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

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
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                    }
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                NavigationLink {
                    RegisterView()
                } label: {
                    Text("Criar conta")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                }

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
