import SwiftUI

struct LoginView: View {
    private enum LoginFeedbackState {
        case idle
        case authenticating
        case success
        case failure

        var title: String {
            switch self {
            case .idle:
                return "Entrar"
            case .authenticating:
                return "Autenticando..."
            case .success:
                return "Sucesso"
            case .failure:
                return "Falha no login"
            }
        }

        var color: Color {
            switch self {
            case .idle, .authenticating:
                return .blue
            case .success:
                return .green
            case .failure:
                return .red
            }
        }
    }
    
    @EnvironmentObject private var session: AuthSession
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var healthStatus: HealthStatus = .loading
    @State private var loginFeedbackState: LoginFeedbackState = .idle
    
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
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 18, height: 18)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 18, height: 18)
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
                        Task { await performLogin() }
                    }) {
                        Text(loginFeedbackState.title)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                    }
                    .background(loginFeedbackState.color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isLoginButtonDisabled)
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

    private var isLoginButtonDisabled: Bool {
        if case .authenticating = loginFeedbackState { return true }
        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty
    }

    private func performLogin() async {
        if case .authenticating = loginFeedbackState { return }

        errorMessage = nil
        loginFeedbackState = .authenticating

        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedPassword = password
            .trimmingCharacters(in: .newlines)

        email = normalizedEmail
        password = normalizedPassword

        do {
            try await session.login(
                email: normalizedEmail,
                password: normalizedPassword
            )
            loginFeedbackState = .success
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
            loginFeedbackState = .failure

            let cooldownNanos: UInt64
            let shouldClearEmail: Bool
            switch authError {
            case .rateLimited:
                cooldownNanos = 5_000_000_000
                shouldClearEmail = false
            case .userNotRegistered:
                cooldownNanos = 1_500_000_000
                shouldClearEmail = true
            default:
                cooldownNanos = 1_500_000_000
                shouldClearEmail = false
            }
            try? await Task.sleep(nanoseconds: cooldownNanos)

            if shouldClearEmail {
                email = ""
            }
            password = ""
            loginFeedbackState = .idle
        } catch {
            errorMessage = AuthError.network.userMessage
            loginFeedbackState = .failure

            try? await Task.sleep(nanoseconds: 1_500_000_000)
            password = ""
            loginFeedbackState = .idle
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
