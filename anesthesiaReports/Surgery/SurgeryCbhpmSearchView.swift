//
//  SurgeryCbhpmSearchView.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 01/02/26.
//
import SwiftUI

struct SelectedCbhpmItem: Identifiable {
    let code: String
    let procedure: String
    let port: String
    let quantity: Int

    var id: String { code }
}

struct SurgeryCbhpmSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedItems: [String: Int] = [:] // code: quantity
    @State private var showAllSelected = false
    let items: [SurgeryCbhpmDTO]
    let onConfirm: (([SelectedCbhpmItem]) -> Void)?

    init(
        items: [SurgeryCbhpmDTO],
        onConfirm: (([SelectedCbhpmItem]) -> Void)? = nil
    ) {
        self.items = items
        self.onConfirm = onConfirm
    }

    static func loadCatalogFromBundle() -> [SurgeryCbhpmDTO] {
        let bundle = Bundle.main
        let candidates: [URL?] = [
            bundle.url(forResource: "cbhpm_codes", withExtension: "json", subdirectory: "Surgery/cbhpm"),
            bundle.url(forResource: "cbhpm_codes", withExtension: "json", subdirectory: "surgery/cbhpm"),
            bundle.url(forResource: "cbhpm_codes", withExtension: "json", subdirectory: "cbhpm"),
            bundle.url(forResource: "cbhpm_codes", withExtension: "json")
        ]

        guard let url = candidates.compactMap({ $0 }).first,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SurgeryCbhpmDTO].self, from: data)
        else {
            return []
        }

        return decoded
    }

    var filtered: [SurgeryCbhpmDTO] {
        let query = normalizedSearch(searchText)
        let codeQuery = normalizedCode(searchText)
        if query.isEmpty { return items }

        return items.filter { item in
            normalizedCode(item.code).contains(codeQuery) ||
            normalizedSearch(item.procedure).contains(query)
        }
    }

    private var selectedRows: [(item: SurgeryCbhpmDTO, qty: Int)] {
        selectedItems
            .compactMap { code, qty in
                guard let item = items.first(where: { $0.code == code }) else { return nil }
                return (item, qty)
            }
            .sorted { $0.item.procedure.localizedCaseInsensitiveCompare($1.item.procedure) == .orderedAscending }
    }

    private var totalSelectedCount: Int {
        selectedItems.values.reduce(0, +)
    }

    private var selectedPayload: [SelectedCbhpmItem] {
        selectedRows.map { row in
            SelectedCbhpmItem(
                code: row.item.code,
                procedure: row.item.procedure,
                port: row.item.port,
                quantity: row.qty
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Nenhum procedimento encontrado")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filtered, id: \.code) { item in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.procedure)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                HStack(spacing: 8) {
                                    Text(item.code)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.primary)
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text("Porte \(item.port)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if let qty = selectedItems[item.code] {
                                HStack(spacing: 10) {
                                    Button {
                                        remove(item.code)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(qty)")
                                        .font(.headline)
                                        .frame(minWidth: 20)

                                    Button {
                                        add(item.code)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                            } else {
                                Button {
                                    add(item.code)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Procedimentos")
            .searchable(text: $searchText, prompt: "Buscar código ou procedimento")
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if selectedRows.isEmpty {
                        HStack {
                            Image(systemName: "tray")
                            Text("Nenhum procedimento selecionado")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(
                                showAllSelected
                                    ? selectedRows
                                    : Array(selectedRows.prefix(3)),
                                id: \.item.code
                            ) { row in
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.item.procedure)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                        Text("\(row.item.code) • Porte \(row.item.port)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("x\(row.qty)")
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Capsule())
                                    Button {
                                        removeAll(of: row.item.code)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.footnote)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedRows.count > 3 {
                                Button(showAllSelected ? "Ver menos" : "Ver todos (\(selectedRows.count))") {
                                    showAllSelected.toggle()
                                }
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    HStack {
                        Text("Selecionados: \(totalSelectedCount)")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button("Limpar") {
                            clearSelection()
                        }
                        .font(.subheadline)
                        .disabled(selectedRows.isEmpty)
                    }

                    HStack(spacing: 10) {
                        Button("Cancelar") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)

                        Button("Confirmar seleção (\(totalSelectedCount))") {
                            onConfirm?(selectedPayload)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedRows.isEmpty)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }

    private func add(_ code: String) {
        selectedItems[code, default: 0] += 1
    }

    private func remove(_ code: String) {
        guard let current = selectedItems[code] else { return }
        if current <= 1 {
            selectedItems.removeValue(forKey: code)
            return
        }
        selectedItems[code] = current - 1
    }

    private func removeAll(of code: String) {
        selectedItems.removeValue(forKey: code)
        if selectedItems.isEmpty {
            showAllSelected = false
        }
    }

    private func clearSelection() {
        selectedItems.removeAll()
        showAllSelected = false
    }

    private func normalizedCode(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    private func normalizedSearch(_ value: String) -> String {
        let folded = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        let space = " ".unicodeScalars.first!
        return String(folded.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == space })
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct SurgeryCbhpmSearchView_Previews: PreviewProvider {
    static var previews: some View {
        let catalog = SurgeryCbhpmSearchView.loadCatalogFromBundle()
        SurgeryCbhpmSearchView(
            items: catalog
        )
    }
}
