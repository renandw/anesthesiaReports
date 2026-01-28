import SwiftUI

struct CompanySelectionView: View {
    @Binding var selectedCompanies: [Company]
    @State private var newCompanyText = ""

    var body: some View {
        Form {
            Section("Empresas conhecidas") {
                ForEach(Array(KnownCompany.allCases.enumerated()), id: \.offset) { _, company in
                    let value = Company.known(company)
                    Button {
                        toggle(value)
                    } label: {
                        HStack {
                            Text(company.displayName)
                            Spacer()
                            if selectedCompanies.contains(value) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section("Empresas personalizadas") {
                HStack {
                    TextField("Adicionar empresa", text: $newCompanyText)
                        .textInputAutocapitalization(.never)
                    Button("Adicionar") {
                        addCustomCompany()
                    }
                    .disabled(newCompanyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if customCompanies.isEmpty {
                    Text("Nenhuma empresa personalizada")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(customCompanies, id: \.id) { company in
                        Text(company.displayName)
                    }
                    .onDelete(perform: deleteCustomCompany)
                }
            }
        }
        .navigationTitle("Empresas")
    }

    private var customCompanies: [Company] {
        selectedCompanies.filter {
            if case .custom = $0 { return true }
            return false
        }
    }

    private func toggle(_ company: Company) {
        if let index = selectedCompanies.firstIndex(of: company) {
            selectedCompanies.remove(at: index)
        } else {
            selectedCompanies.append(company)
        }
    }

    private func addCustomCompany() {
        let trimmed = newCompanyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let company = Company.fromInput(trimmed)
        if !selectedCompanies.contains(company) {
            selectedCompanies.append(company)
        }
        newCompanyText = ""
    }

    private func deleteCustomCompany(at offsets: IndexSet) {
        let items = customCompanies
        for index in offsets {
            let company = items[index]
            if let removeIndex = selectedCompanies.firstIndex(of: company) {
                selectedCompanies.remove(at: removeIndex)
            }
        }
    }
}
