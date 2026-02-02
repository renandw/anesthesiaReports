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
    @State private var selectedCompanies: [Company] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showValidationErrors = false
    @State private var touchedFields: Set<Field> = []

    private enum Field: Hashable {
        case name
        case email
        case crm
        case rqe
        case phone
        case password
        case company
    }

    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    Text("Criar conta")
                        .font(.title2.weight(.semibold))
                }

                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            EditRow(label: "Nome", value: $name)
                                .focused($focusedField, equals: .name)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                            if shouldShowError(for: .name), let message = nameError {
                                Text(message).foregroundColor(.red).font(.caption)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            EditRow(label: "CRM", value: $crm)
                                .focused($focusedField, equals: .crm)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                            if shouldShowError(for: .crm), let message = crmError {
                                Text(message).foregroundColor(.red).font(.caption)
                            }
                        }

                        EditRow(label: "RQE", value: $rqe)
                            .focused($focusedField, equals: .rqe)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))

                        VStack(alignment: .leading, spacing: 4) {
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))

                            if shouldShowError(for: .phone), let message = phoneError {
                                Text(message).foregroundColor(.red).font(.caption)
                            }
                        }

                        NavigationLink {
                            CompanySelectionView(selectedCompanies: $selectedCompanies)
                        } label: {
                            HStack {
                                Text("Empresas")
                                    .fontWeight(.bold)
                                Spacer()
                                if selectedCompanies.displayJoined.isEmpty {
                                    Text("Nenhuma")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(selectedCompanies.displayJoined)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .textContentType(.emailAddress)
                            .background(Color(.secondarySystemBackground))
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            touchedFields.insert(.company)
                        })
                        if shouldShowError(for: .company), let message = companyError {
                            Text(message).foregroundColor(.red).font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            EditRow(label: "e-mail", value: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .textContentType(.emailAddress)
                                .background(Color(.secondarySystemBackground))
                            if shouldShowError(for: .email), let message = emailError {
                                Text(message).foregroundColor(.red).font(.caption)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            PasswordEditRow(label: "Senha", value: $password)
                                .focused($focusedField, equals: .password)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                            if shouldShowError(for: .password), let message = passwordError {
                                Text(message).foregroundColor(.red).font(.caption)
                            }
                        }

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
                            showValidationErrors = true
                            touchedFields = Set([.name, .email, .crm, .rqe, .phone, .password, .company])
                            guard isValid else { return }
                            isLoading = true
                            defer { isLoading = false }
                            errorMessage = nil
                            do {
                                try await session.register(
                                    RegisterInput(
                                        user_name: NameFormatHelper.normalizeTitleCase(name),
                                        email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                                        password: password,
                                        crm_number_uf: crm.trimmingCharacters(in: .whitespacesAndNewlines),
                                        rqe: rqe.isEmpty ? nil : rqe,
                                        phone: PhoneFormatHelper.digitsOnly(phone),
                                        company: selectedCompanies
                                    )
                                )
                                dismiss()
                            } catch let authError as AuthError {
                                errorMessage = authError.userMessage
                            } catch {
                                errorMessage = "Erro de rede"
                            }
                        }
                    }) {
                        Text("Criar conta")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                    }
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isLoading || !isValid)
                }

                Spacer()
            }
            .padding()
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
        .navigationTitle("Registrar Novo Usuário")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isValid: Bool {
        let hasName = isValidFullName(name)
        let hasEmail = isValidEmail(email)
        let hasPassword = password.count >= 8
        let hasCrm = isValidCrm(crm)
        let phoneDigits = PhoneFormatHelper.digitsOnly(phone)
        let hasPhone = phoneDigits.count == 11
        let hasCompany = !selectedCompanies.isEmpty
        return hasName && hasEmail && hasPassword && hasCrm && hasPhone && hasCompany
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

    private var passwordError: String? {
        if password.isEmpty {
            return "Senha obrigatória"
        }
        if password.count < 8 {
            return "Senha mínima de 8 caracteres"
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
        let pattern = #"^\d{1,6}-[A-Z]{2}$"#
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

#Preview {
    NavigationStack{
        RegisterView()
    }
}
