//
//  PreanesthesiaSocialAndEnvironmentSection.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//

//
//  PreanesthesiaAirwaySection.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//


import SwiftUI

struct PreanesthesiaSocialAndEnvironmentSection: View {
    @Binding var items: [PreanesthesiaItemInput]

    var body: some View {
        Section {
            Picker("Capacidade Funcional", selection: funcionalSelection) {
                ForEach(funcionalSelectionOptions, id: \.self) { option in
                    Text(option.displayName)
                        .tag(Optional(option))
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Capacidade Funcional")
        } footer: {
            Text("Selecione uma classificação.")
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
    }

    private var sectionConfigs: [DomainSectionConfig] {
        let footer = "..."
        return [
            DomainSectionConfig(
                id: "social-\(SocialAndEnvironmentCategory.tobacco.rawValue)",
                title: "Tabagismo",
                domain: .environment,
                category: SocialAndEnvironmentCategory.tobacco.rawValue,
                codes: SmokingCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: SmokingCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "carga tabágica"
            ),
            DomainSectionConfig(
                id: "social-\(SocialAndEnvironmentCategory.alcohol.rawValue)",
                title: "Consumo de Álcool",
                domain: .environment,
                category: SocialAndEnvironmentCategory.alcohol.rawValue,
                codes: AlcoholCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: AlcoholCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "consumo de álcool"
            ),
            DomainSectionConfig(
                id: "social-\(SocialAndEnvironmentCategory.drugs.rawValue)",
                title: "Uso de Drogas",
                domain: .environment,
                category: SocialAndEnvironmentCategory.drugs.rawValue,
                codes: IllicitDrugCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: IllicitDrugCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Outra Droga"
            ),
            DomainSectionConfig(
                id: "social-\(SocialAndEnvironmentCategory.environment.rawValue)",
                title: "Ambiente e Exposição",
                domain: .environment,
                category: SocialAndEnvironmentCategory.environment.rawValue,
                codes: RespiratoryExposureCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: RespiratoryExposureCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Outros"
            ),
            
            
            
        ]
    }

    private var funcionalSelectionOptions: [FunctionalCapacityCode] {
        FunctionalCapacityCode.allCases.filter { $0 != .custom }
    }

    private var funcionalSelection: Binding<FunctionalCapacityCode?> {
        Binding(
            get: {
                guard let item = items.first(where: { isFunctionalItem($0) }),
                      let code = FunctionalCapacityCode(rawValue: item.code) else {
                    return nil
                }
                return code
            },
            set: { newValue in
                items.removeAll { isFunctionalItem($0) }
                guard let code = newValue else { return }
                items.append(
                    PreanesthesiaItemInput(
                        domain: PreanesthesiaItemDomain.environment.rawValue,
                        category: SocialAndEnvironmentCategory.funcionalcapacity.rawValue,
                        code: code.rawValue,
                        is_custom: false,
                        custom_label: nil,
                        details: nil
                    )
                )
            }
        )
    }

    private func isFunctionalItem(_ item: PreanesthesiaItemInput) -> Bool {
        item.domain == PreanesthesiaItemDomain.environment.rawValue &&
        item.category == SocialAndEnvironmentCategory.funcionalcapacity.rawValue
    }
}

#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaSocialAndEnvironmentSection(items: $items)
    }
}
