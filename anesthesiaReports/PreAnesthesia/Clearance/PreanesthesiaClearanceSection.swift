import SwiftUI

struct PreanesthesiaClearanceSection: View {
    let clearance: PreanesthesiaClearanceDTO?
    let onEdit: () -> Void

    var body: some View {
        Section {
            if let clearance {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(clearance.status.capitalized)
                        .foregroundStyle(.secondary)
                }

                if clearance.items.isEmpty {
                    Text("Sem itens cadastrados")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(clearance.items, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemValue)
                            Text(item.itemType.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("Sem clearance cadastrado")
                    .foregroundStyle(.secondary)
            }

            Button("Editar clearance") {
                onEdit()
            }
        } header: {
            Text("Liberação para Procedimento")
        }
    }
}

#Preview {
    List {
        PreanesthesiaClearanceSection(clearance: PreanesthesiaClearanceDTO(
            clearanceId: "clearance",
            preanesthesiaId: "pre",
            status: "able",
            items: [
                PreanesthesiaClearanceItemDTO(itemType: "recommendation", itemValue: "Jejum 8h"),
                PreanesthesiaClearanceItemDTO(itemType: "able_recommendation", itemValue: "Hidratar bem")
            ],
            createdAt: Date(),
            updatedAt: Date()
        ), onEdit: {})
    }
}
