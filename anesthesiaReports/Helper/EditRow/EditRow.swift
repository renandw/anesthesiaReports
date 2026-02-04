//
//  EditRow.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 28/01/26.
//
import SwiftUI

struct EditRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            TextField(label, text: $value)
                .multilineTextAlignment(.trailing)
            if !value.isEmpty {
                Button {
                    value = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpar \(label)")
            }
        }
    }
}

struct EditRowArray: View {
    let label: String
    @Binding var values: [String]
    @State private var newItem: String = ""
    @State private var isExpanded: Bool = false
    
    var body: some View {
        Section {
            if values.count == 0 {
                // Quando vazio: TextField inline direto
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    TextField("Adicionar \(label)", text: $newItem)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            addItem()
                        }
                    if !newItem.isEmpty {
                        Button {
                            addItem()
                            isExpanded = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Adicionar \(label)")
                    }
                }
            } else {
                // Quando tem itens: botão expansível
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(values.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .onAppear{
                    isExpanded = true
            }
                
                if isExpanded {
                    ForEach(values.indices, id: \.self) { index in
                        HStack {
                            Text(values[index])
                            Spacer()
                            Button {
                                values.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remover \(values[index])")
                        }
                    }
                    
                    HStack {
                        TextField("Adicionar", text: $newItem)
                            .onSubmit {
                                addItem()
                            }
                        
                        if !newItem.isEmpty {
                            Button {
                                addItem()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Adicionar \(label)")
                        }
                    }
                }
            }
        }
    }
    
    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            values.append(trimmed)
            newItem = ""
        }
    }
}

#Preview("EditRowForm") {
    EditRowArrayPreview()
}

struct EditRowArrayPreview: View {
    @State var times: [String] = ["Corinthians", "Botafogo", "Flamengo"]
    @State var jogadores: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                EditRowArray(label: "Times", values: $times)
                EditRowArray(label: "Jogadores", values: $jogadores)
            }
            .navigationTitle("EditRowForm")
        }
    }
}


struct PasswordEditRow: View {
    let label: String
    @Binding var value: String
    @State private var showPassword = false

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.bold)
            Spacer()
            Group {
                if showPassword {
                    TextField(label, text: $value)
                } else {
                    SecureField(label, text: $value)
                }
            }
            .multilineTextAlignment(.trailing)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(showPassword ? .primary : .secondary)
            }
            .buttonStyle(.plain)
        }

    }
}
#Preview("PasswordEditRow") {
    struct PasswordEditRowPreviewWrapper: View {
        @State var label: String = "Senha"
        @State var value: String = ""

        var body: some View {
            NavigationStack {
                Form {
                    PasswordEditRow(label: label, value: $value)
                }
                .navigationTitle("PasswordEditRow Preview")
            }
        }
    }

    return PasswordEditRowPreviewWrapper()
}

struct EditRowWithOptions: View {
    let label: String
    @Binding var value: String
    let options: [String]
    
    @State private var showingPicker = false
    @State private var searchText = ""
    
    private var filteredOptions: [String] {
        if searchText.isEmpty {
            return options
        }
        return options.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        Button {
            searchText = value
            showingPicker = true
        } label: {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value.isEmpty ? "Selecionar" : value)
                    .foregroundStyle(value.isEmpty ? .secondary : .primary)
                    .multilineTextAlignment(.trailing)
                if !value.isEmpty {
                    Button {
                       value = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Limpar \(label)")
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                List {
                    // Opção de usar o texto digitado (se não existe nas opções)
                    if !searchText.isEmpty && !options.contains(where: { $0.lowercased() == searchText.lowercased() }) {
                        Button {
                            value = searchText
                            showingPicker = false
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Adicionar \"\(searchText)\"")
                            }
                        }
                    }
                    
                    // Opções filtradas
                    ForEach(filteredOptions, id: \.self) { option in
                        Button {
                            value = option
                            showingPicker = false
                        } label: {
                            HStack {
                                Text(option)
                                Spacer()
                                if value == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Buscar ou adicionar")
                .navigationTitle(label)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            showingPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}


struct EditRowWithOptions2: View {
    let label: String
    @Binding var value: String
    let options: [String]
    
    @State private var showingSuggestions = false
    @FocusState private var isFocused: Bool
    
    private var filteredOptions: [String] {
        if value.isEmpty {
            return options
        }
        return options.filter { $0.localizedCaseInsensitiveContains(value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                TextField(label, text: $value)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    .onChange(of: value) { _, newValue in
                        showingSuggestions = !newValue.isEmpty && !filteredOptions.isEmpty
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            showingSuggestions = false
                        }
                    }
                
                if !value.isEmpty {
                    Button {
                        value = ""
                        showingSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Limpar \(label)")
                }
            }
            
            // Sugestões
            if showingSuggestions && isFocused {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredOptions, id: \.self) { option in
                        Button {
                            value = option
                            showingSuggestions = false
                            isFocused = false
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if value.lowercased() == option.lowercased() {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if option != filteredOptions.last {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.top, 4)
            }
        }
    }
}




#Preview("EditRowWithOptions") {
    struct PreviewWrapper: View {
        @State var hospital: String = "Hospital Unimed"
        @State var hospitalp: String = "Hospital Central"
        
        let hospitais = [
            "Hospital Samaritano",
            "Hospital Unimed",
            "Hospital Central",
            "Hospital São Lucas",
            "Hospital Moinhos de Vento"
        ]
        
        let hospitaisp = [
            "Hospital Samaritano",
            "Hospital Unimed",
            "Hospital Central",
            "Hospital São Lucas",
            "Hospital Moinhos de Vento"
        ]
        
        var body: some View {
            NavigationStack {
                Form {
                    EditRowWithOptions(
                        label: "Hospital",
                        value: $hospital,
                        options: hospitais
                    )
                    EditRowWithOptions2(
                        label: "Hospital",
                        value: $hospitalp,
                        options: hospitaisp
                    )
                }
                .navigationTitle("Autocomplete")
            }
        }
    }
    
    return PreviewWrapper()
}
