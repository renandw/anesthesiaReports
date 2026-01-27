import SwiftUI

struct EditUserView: View {

    @EnvironmentObject private var session: AuthSession
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var crm: String = ""
    @State private var rqe: String = ""
    @State private var phone: String = ""
    @State private var companyText: String = ""

    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {

            Text("Editar perfil")
                .font(.headline)

            TextField("Nome", text: $name)
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            TextField("CRM", text: $crm)
            TextField("RQE (opcional)", text: $rqe)

            TextField("Telefone", text: $phone)
                .keyboardType(.numberPad)

            TextField("Empresas (separadas por vírgula)", text: $companyText)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            if let successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
            }

            if isLoading {
                ProgressView()
            }

            Button("Salvar alterações") {
                Task {
                    await updateUser()
                    dismiss()
                }
            }
            .disabled(isLoading)

            Divider()

            Button("Excluir conta", role: .destructive) {
                Task {
                    if await deleteUser() {
                        dismiss()
                    }
                }
            }

        }
        .padding()
        .onAppear {
            loadInitialData()
        }
    }

    // MARK: - Helpers

    private func loadInitialData() {
        guard let user = session.user else { return }
        name = user.name
        email = user.email
        crm = user.crm
        rqe = user.rqe ?? ""
        phone = user.phone
        companyText = user.company.joined(separator: ", ")
    }

    private func updateUser() async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("➡️ Atualizando usuário (PATCH /users/me)...")
            try await session.updateUser(
                UpdateUserInput(
                    user_name: name,
                    email: email,
                    crm_number_uf: crm,
                    rqe: rqe.isEmpty ? nil : rqe,
                    phone: phone.isEmpty ? nil : phone,
                    company: companyText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                )
            )
            print("✅ Usuário atualizado com sucesso")
            errorMessage = nil
            successMessage = "Salvo com sucesso"
        } catch let authError as AuthError {
            print("❌ AuthError no updateUser:", authError)
            successMessage = nil
            switch authError {
            case .invalidPayload:
                errorMessage = "Dados inválidos"
            case .sessionExpired:
                errorMessage = "Sessão expirada"
            default:
                errorMessage = "Erro ao atualizar perfil"
            }
        } catch {
            print("❌ Erro genérico no updateUser:", error)
            successMessage = nil
            errorMessage = "Erro de rede"
        }
    }

    private func deleteUser() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await session.deleteUser()
            return true
        } catch {
            errorMessage = "Erro ao excluir conta"
            return false
        }
    }
}
