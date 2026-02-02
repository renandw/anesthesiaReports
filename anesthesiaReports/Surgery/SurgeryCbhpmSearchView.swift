//
//  SurgeryCbhpmSearchView.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 01/02/26.
//


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