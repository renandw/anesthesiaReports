import SwiftUI

struct PreanesthesiaClearancePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var status: ClearanceStatus
    @State private var selectedItems: Set<String>
    @State private var customItem = ""

    let onSave: (ClearanceStatus, [String]) -> Void

    init(
        status: ClearanceStatus,
        selectedItems: [String],
        onSave: @escaping (ClearanceStatus, [String]) -> Void
    ) {
        _status = State(initialValue: status)
        _selectedItems = State(initialValue: Set(selectedItems))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Status", selection: $status) {
                        ForEach(ClearanceStatus.allCases, id: \.self) { status in
                            Text(status.displayName)
                                .foregroundStyle(status.color)
                                .tag(status)
                        }
                    }
                } header: {
                    Text("Status")
                }

                Section {
                    ForEach(allItems, id: \.self) { raw in
                        Button {
                            toggle(raw)
                        } label: {
                            HStack {
                                Text(displayName(for: raw))
                                Spacer()
                                if selectedItems.contains(raw) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    HStack{
                        TextField("Adicionar Recomendação", text: $customItem)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                            .onSubmit { addCustomItem() }
                        Spacer()
                        Button{
                            addCustomItem()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(customItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text(status.sectionTitle)
                }
            }
            .navigationTitle("Avaliação")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancelar", systemImage: "xmark") { dismiss() }
//                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        onSave(status, Array(selectedItems))
                        dismiss()
                    }
                }
            }
            .onChange(of: status) { _, _ in
                selectedItems.removeAll()
                customItem = ""
            }
        }
    }

    private func toggle(_ raw: String) {
        if selectedItems.contains(raw) {
            selectedItems.remove(raw)
        } else {
            selectedItems.insert(raw)
        }
    }

    private func displayName(for raw: String) -> String {
        if let item = status.availableItems.first(where: { $0.rawValue == raw }) {
            return item.displayName
        }
        return raw
    }

    private var allItems: [String] {
        let predefined = status.availableItems.map(\.rawValue)
        let custom = selectedItems.filter { !predefined.contains($0) }
        return predefined + custom.sorted()
    }

    private func addCustomItem() {
        let trimmed = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = trimmed.lowercased()
        let existing = selectedItems.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        guard !existing.contains(normalized) else {
            customItem = ""
            return
        }
        selectedItems.insert(trimmed)
        customItem = ""
    }
}

#Preview {
    PreanesthesiaClearancePickerView(status: .able, selectedItems: ["adaptedFasting"]) { _, _ in }
}
