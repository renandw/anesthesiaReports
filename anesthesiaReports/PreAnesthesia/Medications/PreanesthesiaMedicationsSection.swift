import SwiftUI

struct PreanesthesiaMedicationsSection: View {
    @Binding var items: [PreanesthesiaItemInput]

    @State private var allergyInput = ""
    @State private var dailyInput = ""

    var body: some View {
        Section {
            medicationList(for: .allergy)
            inputRow(
                title: "Alergia",
                placeholder: "Digite a alergia",
                text: $allergyInput,
                category: .allergy
            )
        } header: {
            Text("Alergias")
        } footer: {
            Text("Liste alergias medicamentosas ou outras relevantes.")
        }

        Section {
            medicationList(for: .dailymeds)
            inputRow(
                title: "Uso diário",
                placeholder: "Digite o medicamento",
                text: $dailyInput,
                category: .dailymeds
            )
        } header: {
            Text("Uso Diário")
        } footer: {
            Text("Liste medicações de uso contínuo.")
        }
    }

    @ViewBuilder
    private func medicationList(for category: MedicationsCategory) -> some View {
        let list = items.filter { matchesCategory($0, category: category) }
        if list.isEmpty {
            Text("Nenhum item")
                .foregroundStyle(.secondary)
        } else {
            ForEach(list.indices, id: \.self) { index in
                let item = list[index]
                HStack {
                    Text(item.custom_label ?? item.code)
                        .font(.subheadline)
                    Spacer()
                    Button {
                        remove(item)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    private func inputRow(
        title: String,
        placeholder: String,
        text: Binding<String>,
        category: MedicationsCategory
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.sentences)
            Button {
                addMedication(text.wrappedValue, category: category)
                text.wrappedValue = ""
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.subheadline)
                    Text("Adicionar \(title)")
                        .font(.subheadline)
                }
            }
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func addMedication(_ raw: String, category: MedicationsCategory) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(
            PreanesthesiaItemInput(
                domain: PreanesthesiaItemDomain.medications.rawValue,
                category: category.rawValue,
                code: trimmed,
                is_custom: true,
                custom_label: trimmed,
                details: nil
            )
        )
    }

    private func remove(_ item: PreanesthesiaItemInput) {
        if let index = items.firstIndex(where: { $0 == item }) {
            items.remove(at: index)
        }
    }

    private func matchesCategory(_ item: PreanesthesiaItemInput, category: MedicationsCategory) -> Bool {
        item.domain == PreanesthesiaItemDomain.medications.rawValue &&
        item.category == category.rawValue
    }
}

#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaMedicationsSection(items: $items)
    }
}
