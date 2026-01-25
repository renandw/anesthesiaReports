//
//  LoginView.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//

import SwiftUI

struct LoginView: View {

    @SwiftUI.Environment(AuthSession.self) private var authSession

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Text("Login")
                    .font(.largeTitle)
                    .bold()

                VStack(spacing: 12) {

                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Senha", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button {
                    Task {
                        await login()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Entrar")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                NavigationLink("Criar conta") {
                    RegisterView()
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func login() async {
        errorMessage = nil
        isLoading = true

        do {
            await authSession.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            // sucesso → AuthSession.state muda → StartupView troca a tela
        } catch let error as AuthError {
            errorMessage = message(for: error)
        } catch {
            errorMessage = "Erro inesperado. Tente novamente."
        }

        isLoading = false
    }

    private func message(for error: AuthError) -> String {
        switch error {
        case .sessionExpired:
            return "Sua sessão expirou. Entre novamente."
        case .invalidCredentials:
            return "Email ou senha incorretos."
        case .userInactive:
            return "Conta desativada."
        case .userDeleted:
            return "Conta removida."
        case .networkError:
            return "Sem conexão com a internet."
        default:
            return "Não foi possível entrar."
        }
    }
}
