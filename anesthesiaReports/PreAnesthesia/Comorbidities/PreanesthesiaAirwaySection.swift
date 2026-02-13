//
//  PreanesthesiaAirwaySection.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//


import SwiftUI

struct PreanesthesiaAirwaySection: View {
    @Binding var items: [PreanesthesiaItemInput]

    var body: some View {
        Section {
            Picker("Mallampati", selection: mallampatiSelection) {
                ForEach(mallampatiOptions, id: \.self) { option in
                    Text(option.displayName)
                        .tag(Optional(option))
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Mallampati")
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
                id: "airway-\(AirWayCategory.predictors.rawValue)",
                title: "Preditores Via Aérea Difícil",
                domain: .airway,
                category: AirWayCategory.predictors.rawValue,
                codes: PredictorsAirWayCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: PredictorsAirWayCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Preditores"
            ),
            
        ]
    }

    private var mallampatiOptions: [MallampatiCode] {
        MallampatiCode.allCases.filter { $0 != .custom }
    }

    private var mallampatiSelection: Binding<MallampatiCode?> {
        Binding(
            get: {
                guard let item = items.first(where: { isMallampatiItem($0) }),
                      let code = MallampatiCode(rawValue: item.code) else {
                    return nil
                }
                return code
            },
            set: { newValue in
                items.removeAll { isMallampatiItem($0) }
                guard let code = newValue else { return }
                items.append(
                    PreanesthesiaItemInput(
                        domain: PreanesthesiaItemDomain.airway.rawValue,
                        category: AirWayCategory.mallampati.rawValue,
                        code: code.rawValue,
                        is_custom: false,
                        custom_label: nil,
                        details: nil
                    )
                )
            }
        )
    }

    private func isMallampatiItem(_ item: PreanesthesiaItemInput) -> Bool {
        item.domain == PreanesthesiaItemDomain.airway.rawValue &&
        item.category == AirWayCategory.mallampati.rawValue
    }
}

#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaAirwaySection(items: $items)
    }
}
