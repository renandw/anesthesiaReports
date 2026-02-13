//
//  PreanesthesiaSurgeryHistorySection 2.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 10/02/26.
//


import SwiftUI

struct PreanesthesiaAnesthesiaHistorySection: View {
    @Binding var items: [PreanesthesiaItemInput]

    var body: some View {
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
                id: "anesthesia-history-\(AnesthesiaHistoryCategory.complications.rawValue)",
                title: "Complicações Anestésicas",
                domain: .anesthesiaHistory,
                category: AnesthesiaHistoryCategory.complications.rawValue,
                codes: AnesthesiaComplicationsHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: AnesthesiaComplicationsHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Complicações"
            ),
            
        ]
    }
}

#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaAnesthesiaHistorySection(items: $items)
    }
}
