//
//  SurgeryCbhpmSearchView.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 01/02/26.
//
import SwiftUI
struct SurgeryCbhpmSearchView: View {
    @State private var searchText = ""
    @State private var selectedItems: [String: Int] = [:] // code: quantity
    let items: [SurgeryCbhpmDTO]
    
    var filtered: [SurgeryCbhpmDTO] {
        items.filter { item in
            searchText.isEmpty ||
            item.code.localizedCaseInsensitiveContains(searchText) ||
            item.procedure.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            TextField("Buscar por código ou procedimento", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            // List
            List(filtered, id: \.code) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.code).font(.caption).foregroundColor(.secondary)
                        Text(item.procedure)
                        Text(item.port).font(.caption)
                    }
                    
                    Spacer()
                    
                    if let qty = selectedItems[item.code] {
                        // Stepper quando selecionado
                        HStack {
                            Button("-") {
                                if qty > 1 {
                                    selectedItems[item.code] = qty - 1
                                } else {
                                    selectedItems.removeValue(forKey: item.code)
                                }
                            }
                            Text("\(qty)")
                                .frame(minWidth: 30)
                            Button("+") {
                                selectedItems[item.code] = qty + 1
                            }
                        }
                    } else {
                        // Botão adicionar
                        Button("Adicionar") {
                            selectedItems[item.code] = 1
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText) // iOS 15+
    }
}

struct SurgeryCbhpmSearchView_Previews: PreviewProvider {
    static var previews: some View {
        SurgeryCbhpmSearchView(
            items: [
                SurgeryCbhpmDTO(
                    code: "31001019",
                    procedure: "Apendicectomia",
                    port: "2A"
                ),
                SurgeryCbhpmDTO(
                    code: "31001027",
                    procedure: "Colecistectomia videolaparoscópica",
                    port: "3A"
                ),
                SurgeryCbhpmDTO(
                    code: "31001035",
                    procedure: "Herniorrafia inguinal unilateral",
                    port: "2B"
                ),
                SurgeryCbhpmDTO(
                    code: "31001043",
                    procedure: "Laparotomia exploradora",
                    port: "3B"
                ),
                SurgeryCbhpmDTO(
                    code: "31001051",
                    procedure: "Ressecção de tumor de cólon",
                    port: "4A"
                )
            ]
        )
    }
}
