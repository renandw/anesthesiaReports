import SwiftUI

protocol DomainCode: RawRepresentable, CaseIterable, Hashable where RawValue == String {
    var displayName: String { get }
    static var customCase: Self { get }
}

struct DomainCodeOption: Hashable {
    let rawValue: String
    let displayName: String
}

extension DomainCode {
    var option: DomainCodeOption {
        DomainCodeOption(rawValue: rawValue, displayName: displayName)
    }
}

struct DomainSectionConfig: Identifiable {
    let id: String
    let title: String
    let domain: PreanesthesiaItemDomain
    let category: String
    let codes: [DomainCodeOption]
    let customCodeRawValue: String
    let footer: String
    let customLabelPlaceholder: String
}

struct DomainSection: View {
    let config: DomainSectionConfig
    @Binding var items: [PreanesthesiaItemInput]

    @State private var customLabel = ""
    @State private var customDetails = ""
    @State private var showOptions = false

    var body: some View {
        Toggle(isOn: categoryToggle) {
            Text(config.title)
                .bold()
        }

        if showCategorySection {
            ForEach(config.codes, id: \.self) { code in
                Button {
                    toggleStandard(code)
                } label: {
                    VStack {
                        HStack {
                            Text(code.displayName)
                                .font(.subheadline)
                            Spacer()
                            if isSelected(code) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        if isSelected(code) {
                            TextField("Detalhes", text: detailBinding(for: code))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .textInputAutocapitalization(.sentences)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if !customItems.isEmpty {
                ForEach(customItems.indices, id: \.self) { index in
                    let item = customItems[index]
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.custom_label ?? "Custom")
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

            TextField(config.customLabelPlaceholder, text: $customLabel)
                .font(.subheadline)
                .textInputAutocapitalization(.sentences)
            if !customLabel.isEmpty {
                TextField("Detalhes", text: $customDetails)
                    .font(.subheadline)
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
            .disabled(customLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var categoryToggle: Binding<Bool> {
        Binding(
            get: { showCategorySection },
            set: { enabled in
                if !enabled {
                    items.removeAll { isCategoryItem($0) }
                    showOptions = false
                } else {
                    showOptions = true
                }
            }
        )
    }

    private var showCategorySection: Bool {
        showOptions || !standardItems.isEmpty || !customItems.isEmpty
    }

    private var standardItems: [PreanesthesiaItemInput] {
        items.filter { isCategoryItem($0) && !$0.is_custom }
    }

    private var customItems: [PreanesthesiaItemInput] {
        items.filter { isCategoryItem($0) && $0.is_custom }
    }

    private func isCategoryItem(_ item: PreanesthesiaItemInput) -> Bool {
        item.domain == config.domain.rawValue &&
        item.category == config.category
    }

    private func isSelected(_ code: DomainCodeOption) -> Bool {
        items.contains {
            $0.domain == config.domain.rawValue &&
            $0.category == config.category &&
            $0.code == code.rawValue &&
            !$0.is_custom
        }
    }

    private func toggleStandard(_ code: DomainCodeOption) {
        if let index = items.firstIndex(where: {
            $0.domain == config.domain.rawValue &&
            $0.category == config.category &&
            $0.code == code.rawValue &&
            !$0.is_custom
        }) {
            items.remove(at: index)
        } else {
            items.append(
                PreanesthesiaItemInput(
                    domain: config.domain.rawValue,
                    category: config.category,
                    code: code.rawValue,
                    is_custom: false,
                    custom_label: nil,
                    details: nil
                )
            )
        }
    }

    private func detailBinding(for code: DomainCodeOption) -> Binding<String> {
        Binding(
            get: {
                items.first(where: {
                    $0.domain == config.domain.rawValue &&
                    $0.category == config.category &&
                    $0.code == code.rawValue &&
                    !$0.is_custom
                })?.details ?? ""
            },
            set: { newValue in
                guard let index = items.firstIndex(where: {
                    $0.domain == config.domain.rawValue &&
                    $0.category == config.category &&
                    $0.code == code.rawValue &&
                    !$0.is_custom
                }) else { return }
                items[index] = PreanesthesiaItemInput(
                    domain: items[index].domain,
                    category: items[index].category,
                    code: items[index].code,
                    is_custom: items[index].is_custom,
                    custom_label: items[index].custom_label,
                    details: newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue
                )
            }
        )
    }

    private func addCustom() {
        let trimmedLabel = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty else { return }
        let trimmedDetails = customDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        items.append(
            PreanesthesiaItemInput(
                domain: config.domain.rawValue,
                category: config.category,
                code: config.customCodeRawValue,
                is_custom: true,
                custom_label: trimmedLabel,
                details: trimmedDetails.isEmpty ? nil : trimmedDetails
            )
        )
        customLabel = ""
        customDetails = ""
    }

    private func removeCustom(at index: Int) {
        let customList = customItems
        guard index < customList.count else { return }
        if let realIndex = items.firstIndex(where: { $0 == customList[index] }) {
            items.remove(at: realIndex)
        }
    }
}
