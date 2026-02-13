import SwiftUI

struct PreanesthesiaLabsAndImageSection: View {
    @Binding var items: [PreanesthesiaItemInput]

    @State private var customExamName = ""
    @State private var customExamResult = ""

    var body: some View {
        Section {
            ForEach(labsOptions, id: \.self) { code in
                HStack {
                    Text(code.displayName)
                        .font(.subheadline)
                    Spacer()
                    TextField("Valor", text: labValueBinding(for: code))
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                }
            }
        } header: {
            Text("Exames Laboratoriais")
        } footer: {
            Text("Informe valores laboratoriais relevantes quando disponíveis.")
        }
        ForEach(sectionConfigs) { config in
            Section {
                DomainSection(config: config, items: $items)
            } header: {
                Text(config.title)
            } footer: {
                Text(config.footer)
            }
        }

        Section {
            if !customItems.isEmpty {
                ForEach(customItems.indices, id: \.self) { index in
                    let item = customItems[index]
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.custom_label ?? "Outro exame")
                                .font(.subheadline)
                            if let details = item.details, !details.isEmpty {
                                Text(details)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            removeCustom(at: index)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            TextField("Outro exame", text: $customExamName)
                .textInputAutocapitalization(.sentences)
            if !customExamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                TextField("Resultado", text: $customExamResult)
                    .textInputAutocapitalization(.sentences)
            }
            Button {
                addCustom()
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.subheadline)
                    Text("Adicionar")
                        .font(.subheadline)
                }
            }
            .disabled(customExamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } header: {
            Text("Outro Exame")
        } footer: {
            Text("Use para exames fora das categorias acima.")
        }
    }
    
    private var sectionConfigs: [DomainSectionConfig] {
        let footer = "..."
        return [
            DomainSectionConfig(
                id: "labsAndImage-\(LabsAndImageCategory.ecg.rawValue)",
                title: "Eletrocardiograma",
                domain: .labsAndImage,
                category: LabsAndImageCategory.ecg.rawValue,
                codes: ECGCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: ECGCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "descrição"
            ),
            DomainSectionConfig(
                id: "labsAndImage-\(LabsAndImageCategory.chestxray.rawValue)",
                title: "Radiografia de Tórax",
                domain: .labsAndImage,
                category: LabsAndImageCategory.chestxray.rawValue,
                codes: ChestXRayCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: ChestXRayCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "descrição"
            ),
            DomainSectionConfig(
                id: "labsAndImage-\(LabsAndImageCategory.eco.rawValue)",
                title: "Ecocardiograma Transtorácico",
                domain: .labsAndImage,
                category: LabsAndImageCategory.eco.rawValue,
                codes: EchocardiogramCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: EchocardiogramCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "descrição"
            ),
            
        ]
    }

    private var labsOptions: [LabsCode] {
        LabsCode.allCases
    }

    private var labsItems: [PreanesthesiaItemInput] {
        items.filter { isLabsItem($0) }
    }

    private var customItems: [PreanesthesiaItemInput] {
        items.filter { isCustomItem($0) }
    }

    private func isLabsItem(_ item: PreanesthesiaItemInput) -> Bool {
        item.domain == PreanesthesiaItemDomain.labsAndImage.rawValue &&
        item.category == LabsAndImageCategory.labs.rawValue
    }

    private func isCustomItem(_ item: PreanesthesiaItemInput) -> Bool {
        item.domain == PreanesthesiaItemDomain.labsAndImage.rawValue &&
        item.category == LabsAndImageCategory.custom.rawValue &&
        item.is_custom
    }

    private func labValueBinding(for code: LabsCode) -> Binding<String> {
        Binding(
            get: {
                labsItems.first(where: { matchesCode($0, code: code) })?.details ?? ""
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    items.removeAll { matchesCode($0, code: code) }
                    return
                }

                if let index = items.firstIndex(where: { matchesCode($0, code: code) }) {
                    let customLabel = code == .custom ? "Outra" : nil
                    items[index] = PreanesthesiaItemInput(
                        domain: items[index].domain,
                        category: items[index].category,
                        code: items[index].code,
                        is_custom: code == .custom,
                        custom_label: customLabel,
                        details: trimmed
                    )
                } else {
                    let customLabel = code == .custom ? "Outra" : nil
                    items.append(
                        PreanesthesiaItemInput(
                            domain: PreanesthesiaItemDomain.labsAndImage.rawValue,
                            category: LabsAndImageCategory.labs.rawValue,
                            code: code.rawValue,
                            is_custom: code == .custom,
                            custom_label: customLabel,
                            details: trimmed
                        )
                    )
                }
            }
        )
    }

    private func matchesCode(_ item: PreanesthesiaItemInput, code: LabsCode) -> Bool {
        item.domain == PreanesthesiaItemDomain.labsAndImage.rawValue &&
        item.category == LabsAndImageCategory.labs.rawValue &&
        item.code == code.rawValue
    }

    private func addCustom() {
        let trimmedName = customExamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedResult = customExamResult.trimmingCharacters(in: .whitespacesAndNewlines)
        items.append(
            PreanesthesiaItemInput(
                domain: PreanesthesiaItemDomain.labsAndImage.rawValue,
                category: LabsAndImageCategory.custom.rawValue,
                code: trimmedName,
                is_custom: true,
                custom_label: trimmedName,
                details: trimmedResult.isEmpty ? nil : trimmedResult
            )
        )
        customExamName = ""
        customExamResult = ""
    }

    private func removeCustom(at index: Int) {
        let list = customItems
        guard index < list.count else { return }
        if let realIndex = items.firstIndex(where: { $0 == list[index] }) {
            items.remove(at: realIndex)
        }
    }
}

#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaLabsAndImageSection(items: $items)
    }
}
