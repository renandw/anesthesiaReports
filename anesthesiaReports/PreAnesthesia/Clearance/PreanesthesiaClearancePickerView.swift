import SwiftUI

struct PreanesthesiaClearancePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var status: ClearanceStatus
    @State private var selectedItems: Set<String>

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
                            Label(status.displayName, systemImage: status.icon)
                                .foregroundStyle(status.color)
                                .tag(status)
                        }
                    }
                } header: {
                    Text("Status")
                }

                Section {
                    ForEach(status.availableItems, id: \.rawValue) { item in
                        Button {
                            toggle(item.rawValue)
                        } label: {
                            HStack {
                                Text(item.displayName)
                                Spacer()
                                if selectedItems.contains(item.rawValue) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(status.sectionTitle)
                }
            }
            .navigationTitle("Clearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        onSave(status, Array(selectedItems))
                        dismiss()
                    }
                }
            }
            .onChange(of: status) { _ in
                selectedItems.removeAll()
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
}

#Preview {
    PreanesthesiaClearancePickerView(status: .able, selectedItems: ["adaptedFasting"]) { _, _ in }
}
