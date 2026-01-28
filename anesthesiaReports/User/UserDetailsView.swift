import SwiftUI

struct UserDetailsView: View {
    
    @EnvironmentObject private var session: AuthSession
    @EnvironmentObject private var userSession: UserSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    
    // Estados para edição
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var crm: String = ""
    @State private var rqe: String = ""
    @State private var phone: String = ""
    @State private var selectedCompanies: [Company] = []
    
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        Form {
            if let user = userSession.user {
                Section {
                    if isEditing {
                        EditRow(label: "Nome", value: $name)
                        EditRow(label: "e-mail", value: $email)
                        EditRow(label: "CRM", value: $crm)
                        EditRow(label: "RQE", value: $rqe)
                        EditRow(label: "Telefone", value: $phone)
                        NavigationLink {
                            CompanySelectionView(selectedCompanies: $selectedCompanies)
                        } label: {
                            HStack {
                                Text("Empresas")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(selectedCompanies.displayJoined.isEmpty ? "Nenhuma" : selectedCompanies.displayJoined)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        DetailRow(label: "Nome", value: user.name)
                        DetailRow(label: "e-mail", value: user.email)
                        DetailRow(label: "CRM", value: user.crm)
                        DetailRow(label: "RQE", value: user.rqe ?? "")
                        DetailRow(label: "Telefone", value: user.phone)
                        DetailRow(label: "Empresas", value: user.company.displayJoined)
                    }
                } header: {
                    if isEditing {
                        Text("Editando Dados")
                    } else {
                        Text("Dados")
                    }
                }
                if !isEditing {
                    Section {
                        DetailRow(label: "Role", value: user.role.displayName)
                        DetailRow(
                            label: "Criado em",
                            value: user.createdAt.formatted(date: .numeric, time: .shortened)
                        )
                        DetailRow(
                            label: "Atualizado em",
                            value: user.updatedAt.formatted(date: .numeric, time: .shortened)
                        )
                    } header: {
                        Text("Metadados")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button {
                        Task {
                            if await deleteUser() {
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isEditing {
                        Task {
                            await updateUser()
                        }
                    } else {
                        loadInitialData()
                    }
                    isEditing.toggle()
                } label: {
                    if isEditing {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    } else {
                        Text("Editar")
                    }
                }
            }
            
        }
        .navigationTitle("Detalhes do Usuário")
    }
    
    private func loadInitialData() {
        guard let user = userSession.user else { return }
        name = user.name
        email = user.email
        crm = user.crm
        rqe = user.rqe ?? ""
        phone = user.phone
        selectedCompanies = user.company
    }

    private func updateUser() async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("➡️ Atualizando usuário (PATCH /users/me)...")
            try await userSession.updateUser(
                UpdateUserInput(
                    user_name: name,
                    email: email,
                    crm_number_uf: crm,
                    rqe: rqe.isEmpty ? nil : rqe,
                    phone: phone.isEmpty ? nil : phone,
                    company: selectedCompanies
                )
            )
            print("✅ Usuário atualizado com sucesso")
            errorMessage = nil
            successMessage = "Salvo com sucesso"
        } catch let authError as AuthError {
            print("❌ AuthError no updateUser:", authError)
            successMessage = nil
            if authError.isFatalSessionError {
                return
            }
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
            try await userSession.deleteUser()
            await session.logout()
            return true
        } catch {
            errorMessage = "Erro ao excluir conta"
            return false
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}


