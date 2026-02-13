import SwiftUI

struct PreanesthesiaPhysicalExamSection: View {
    @Binding var items: [PreanesthesiaItemInput]

    var body: some View {
        Section {
            ForEach(PhysicalExamCategory.allCases, id: \.self) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("Descrição do exame", text: detailBinding(for: category), axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(2, reservesSpace: true)
                }
            }
        } header: {
            Text("Exame Físico")
        } footer: {
            Text("Descreva achados relevantes por sistema.")
        }
    }

    private func detailBinding(for category: PhysicalExamCategory) -> Binding<String> {
        Binding(
            get: {
                items.first(where: { isCategoryItem($0, category: category) })?.details ?? ""
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    items.removeAll { isCategoryItem($0, category: category) }
                    return
                }

                if let index = items.firstIndex(where: { isCategoryItem($0, category: category) }) {
                    let existingCode = items[index].code.trimmingCharacters(in: .whitespacesAndNewlines)
                    items[index] = PreanesthesiaItemInput(
                        domain: items[index].domain,
                        category: items[index].category,
                        code: existingCode.isEmpty ? category.rawValue : items[index].code,
                        is_custom: items[index].is_custom,
                        custom_label: items[index].custom_label,
                        details: trimmed
                    )
                } else {
                    items.append(
                        PreanesthesiaItemInput(
                            domain: PreanesthesiaItemDomain.physicalexam.rawValue,
                            category: category.rawValue,
                            code: category.rawValue,
                            is_custom: false,
                            custom_label: nil,
                            details: trimmed
                        )
                    )
                }
            }
        )
    }

    private func isCategoryItem(_ item: PreanesthesiaItemInput, category: PhysicalExamCategory) -> Bool {
        item.domain == PreanesthesiaItemDomain.physicalexam.rawValue &&
        item.category == category.rawValue
    }

    static func defaultText(for category: PhysicalExamCategory) -> String {
        switch category {
        case .general: return "Bom estado geral, corado e hidratado"
        case .brain: return "Consiciente e orientado."
        case .heart: return "Bulhas normofonéticas, ritmo regular em dois tempos"
        case .lungs: return "Murmúrios vesiculares presentes global e bilateralmente"
        case .abdome: return "Abdome flácido, sem massas palpáveis"
        case .limbs: return "Bem perfundidos, sem sinais de cianose"
        }
    }

    static func applyingDefaultTexts(to items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        var updatedItems = items
        for category in PhysicalExamCategory.allCases {
            let existingIndex = updatedItems.firstIndex(where: {
                $0.domain == PreanesthesiaItemDomain.physicalexam.rawValue &&
                $0.category == category.rawValue
            })
            let defaultValue = defaultText(for: category)
            if let index = existingIndex {
                let currentDetails = updatedItems[index].details?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let existingCode = updatedItems[index].code.trimmingCharacters(in: .whitespacesAndNewlines)
                if currentDetails.isEmpty {
                    updatedItems[index] = PreanesthesiaItemInput(
                        domain: updatedItems[index].domain,
                        category: updatedItems[index].category,
                        code: existingCode.isEmpty ? category.rawValue : updatedItems[index].code,
                        is_custom: updatedItems[index].is_custom,
                        custom_label: updatedItems[index].custom_label,
                        details: defaultValue
                    )
                }
            } else {
                updatedItems.append(
                    PreanesthesiaItemInput(
                        domain: PreanesthesiaItemDomain.physicalexam.rawValue,
                        category: category.rawValue,
                        code: category.rawValue,
                        is_custom: false,
                        custom_label: nil,
                        details: defaultValue
                    )
                )
            }
        }
        return updatedItems
    }
}

#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaPhysicalExamSection(items: $items)
    }
}
