//
//  RegisterView.swift
//  anesthesiaReports
//

import SwiftUI

struct RegisterView: View {

    @SwiftUI.Environment(AuthSession.self) private var authSession
    @Environment(\.dismiss) private var dismiss

    @State private var userName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var crmNumberUf = ""
    @State private var rqe = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {

            Section("Dados pessoais") {
                TextField("Nome", text: $userName)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            Section("Credenciais") {
                SecureField("Senha", text: $password)
            }

            Section("Registro profissional") {
                TextField("CRM / UF", text: $crmNumberUf)
                TextField("RQE (opcional)", text: $rqe)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if let successMessage {
                Section {
                    Text(successMessage)
                        .foregroundStyle(.green)
                }
            }

            Section {
                Button {
                    Task { await register() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Cadastrar")
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Criar conta")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func register() async {
        errorMessage = nil
        successMessage = nil
        isLoading = true

        do {
            try await authSession.register(
                userName: userName,
                email: email,
                password: password,
                crmNumberUf: crmNumberUf,
                rqe: rqe.isEmpty ? nil : rqe
            )

            successMessage = "Conta criada com sucesso."
            
            // Pequeno delay só para UX (opcional)
            try? await Task.sleep(for: .seconds(1))
            dismiss()

        } catch {
            errorMessage = "Não foi possível criar a conta."
        }

        isLoading = false
    }
}