import SwiftUI

struct RegisterView: View {

    @EnvironmentObject private var session: AuthSession
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var crm = ""
    @State private var rqe = ""
    @State private var phone = ""
    @State private var companyText = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {

            TextField("Nome", text: $name)
                .textInputAutocapitalization(.words)
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            SecureField("Senha", text: $password)
            TextField("CRM", text: $crm)
                .textInputAutocapitalization(.never)
            TextField("RQE (opcional)", text: $rqe)
            TextField("Telefone", text: $phone)
                .keyboardType(.numberPad)

            TextField("Empresas (separadas por vírgula)", text: $companyText)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button("Criar conta") {
                Task {
                    errorMessage = nil
                    do {
                        try await session.register(
                            RegisterInput(
                                user_name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                password: password,
                                crm_number_uf: crm.trimmingCharacters(in: .whitespacesAndNewlines),
                                rqe: rqe.isEmpty ? nil : rqe,
                                phone: phone,
                                company: companyText
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespaces) }
                                    .filter { !$0.isEmpty }
                            )
                        )
                        dismiss() // volta para LoginView
                    } catch let authError as AuthError {
                        errorMessage = authError.userMessage
                    } catch {
                        errorMessage = "Erro de rede"
                    }
                }
            }
        }
        .padding()
    }
}
