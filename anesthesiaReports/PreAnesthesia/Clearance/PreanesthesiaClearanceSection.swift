import SwiftUI

struct PreanesthesiaClearanceSection: View {
    let status: ClearanceStatus?
    let items: [String]
    let onEdit: (ClearanceStatus, [String]) -> Void

    var body: some View {
        
        Section {
            if let status {
                NavigationLink {
                    PreanesthesiaClearancePickerView(
                        status: status,
                        selectedItems: items,
                        onSave: onEdit
                    )
                } label: {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(status.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
//
//                if items.isEmpty {
//                    Text("Sem itens cadastrados")
//                        .foregroundStyle(.secondary)
//                } else {
//                    ForEach(displayItems, id: \.self) { item in
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(item)
//                            Text(status.sectionTitle)
//                                .font(.caption)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
            } else {
                NavigationLink {
                    PreanesthesiaClearancePickerView(
                        status: .able,
                        selectedItems: items,
                        onSave: onEdit
                    )
                } label: {
                    HStack{
                        Text("Status")
                        Spacer()
                        Text("Selecione")
                            .foregroundStyle(.secondary)
                    }
                }
            }

        } header: {
            Text("Liberação para Procedimento")
        }
    }

    private var displayItems: [String] {
        items.compactMap { raw in
            if let item = status?.availableItems.first(where: { $0.rawValue == raw }) {
                return item.displayName
            }
            return raw
        }
    }
}

#Preview {
    List {
        PreanesthesiaClearanceSection(
            status: nil,
            items: ["adaptedFasting", "Hidratar bem"],
            onEdit: { _, _ in }
        )
    }
}
