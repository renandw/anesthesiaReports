import SwiftUI

struct CanShareWithView: View {

    @EnvironmentObject private var session: AuthSession

    @State private var users: [RelatedUserDTO] = []
    @State private var selectedUser: RelatedUserDTO?
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var companyFilter = ""

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                TextField("Buscar por nome", text: $searchText)
                    .textInputAutocapitalization(.words)
                TextField("Filtrar por empresa (opcional)", text: $companyFilter)
                    .textInputAutocapitalization(.never)
                Button("Buscar") {
                    Task { await loadUsers() }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            List(users) { user in
                Button {
                    selectedUser = user
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.crm)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let rqe = user.rqe, !rqe.isEmpty {
                            Text("RQE: \(rqe)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)

            if selectedUser != nil {
                Text("O usuário poderá ser adicionado ao sharedWith quando implementado")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Compartilhar com")
        .task { await loadUsers() }
        .padding()
    }

    private func loadUsers() async {
        errorMessage = nil
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let company = companyFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            users = try await session.fetchRelatedUsers(
                company: company.isEmpty ? nil : company,
                search: search.isEmpty ? nil : search
            )
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
    }
}
