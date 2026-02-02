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
    @State private var showValidationErrors = false
    @State private var touchedFields: Set<Field> = []

    private enum Field: Hashable {
        case name
        case email
        case crm
        case rqe
        case phone
        case company
    }

    @FocusState private var focusedField: Field?
    
    var body: some View {
        Form {
            if let user = userSession.user {
                Section {
                    if isEditing {
                        EditRow(label: "Nome", value: $name)
                            .focused($focusedField, equals: .name)
                        if shouldShowError(for: .name), let message = nameError {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                        EditRow(label: "e-mail", value: $email)
                            .focused($focusedField, equals: .email)
                        if shouldShowError(for: .email), let message = emailError {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                        EditRow(label: "CRM", value: $crm)
                            .focused($focusedField, equals: .crm)
                        if shouldShowError(for: .crm), let message = crmError {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                        EditRow(label: "RQE", value: $rqe)
                            .focused($focusedField, equals: .rqe)
                            .keyboardType(.numberPad)
                        HStack {
                            Text("Telefone")
                                .fontWeight(.bold)
                            Spacer()
                            TextField("Telefone", text: Binding(
                                get: { PhoneFormatHelper.format(phone) },
                                set: { newValue in
                                    phone = PhoneFormatHelper.digitsOnly(newValue)
                                }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .phone)
                        }
                        if shouldShowError(for: .phone), let message = phoneError {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
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
                        .simultaneousGesture(TapGesture().onEnded {
                            touchedFields.insert(.company)
                        })
                        if shouldShowError(for: .company), let message = companyError {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                    } else {
                        DetailRow(label: "Nome", value: user.name)
                        DetailRow(label: "e-mail", value: user.email)
                        DetailRow(label: "CRM", value: user.crm)
                        DetailRow(label: "RQE", value: user.rqe ?? "")
                        DetailRow(label: "Telefone", value: PhoneFormatHelper.format(user.phone))
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
                            showValidationErrors = true
                            touchedFields = Set([.name, .email, .crm, .rqe, .phone])
                            guard isValid else { return }
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
                .disabled(isEditing && !isValid)
            }
            
        }
        .navigationTitle("Detalhes do Usuário")
        .onChange(of: focusedField) { previous, current in
            if let previous, current != previous {
                touchedFields.insert(previous)
            }
            if previous == .name && current != .name {
                name = NameFormatHelper.normalizeTitleCase(name)
            }
            if previous == .email && current != .email {
                email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            if previous == .crm && current != .crm {
                crm = crm.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            }
        }
        .onChange(of: selectedCompanies) { _, _ in
            touchedFields.insert(.company)
        }
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
                    user_name: NameFormatHelper.normalizeTitleCase(name),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                    crm_number_uf: crm,
                    rqe: rqe.isEmpty ? nil : rqe,
                    phone: phone.isEmpty ? nil : PhoneFormatHelper.digitsOnly(phone),
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

    private var isValid: Bool {
        let hasName = isValidFullName(name)
        let hasEmail = isValidEmail(email)
        let hasCrm = isValidCrm(crm)
        let phoneDigits = PhoneFormatHelper.digitsOnly(phone)
        let hasPhone = phoneDigits.count == 11
        return hasName && hasEmail && hasCrm && hasPhone
    }

    private func shouldShowError(for field: Field) -> Bool {
        touchedFields.contains(field) && focusedField != field
    }

    private var nameError: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Nome obrigatório"
        }
        if !isValidFullName(name) {
            return "Use nome completo"
        }
        return nil
    }

    private var emailError: String? {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "E-mail obrigatório"
        }
        if !isValidEmail(email) {
            return "Formato inválido (ex: nome@dominio.com)"
        }
        return nil
    }

    private var crmError: String? {
        if crm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "CRM obrigatório"
        }
        if !isValidCrm(crm) {
            return "Formato inválido (ex: 1234-UF)"
        }
        return nil
    }

    private var phoneError: String? {
        let digits = PhoneFormatHelper.digitsOnly(phone)
        if digits.isEmpty {
            return "Telefone obrigatório"
        }
        if digits.count != 11 {
            return "Formato inválido (ex: 69981328798)"
        }
        return nil
    }

    private var companyError: String? {
        if selectedCompanies.isEmpty {
            return "Selecione ao menos uma empresa"
        }
        return nil
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    private func isValidCrm(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let pattern = #"^\d{4}-[A-Z]{2}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    private func isValidFullName(_ value: String) -> Bool {
        let parts = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        guard parts.count >= 2 else { return false }
        return parts.allSatisfy { $0.count >= 3 }
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
