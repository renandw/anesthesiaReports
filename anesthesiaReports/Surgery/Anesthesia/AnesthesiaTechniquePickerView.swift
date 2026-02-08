import SwiftUI

struct AnesthesiaTechniquePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: AnesthesiaTechniqueCategory = .general
    @State private var selectedType: AnesthesiaTechniqueType = .tiva
    @State private var selectedRegion: AnesthesiaTechniqueRegion?

    let onAdd: (AnesthesiaTechniqueDTO) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Categoria", selection: $selectedCategory) {
                        ForEach(AnesthesiaTechniqueCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section {
                    Picker("Tipo", selection: $selectedType) {
                        ForEach(AnesthesiaTechniqueHelper.types(for: selectedCategory), id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                if shouldShowRegion {
                    Section {
                        Picker("Detalhe", selection: selectedRegionBinding) {
                            ForEach(AnesthesiaTechniqueHelper.regions(for: selectedType), id: \.self) { region in
                                Text(region.displayName).tag(Optional(region))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Técnica")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adicionar") {
                        onAdd(
                            AnesthesiaTechniqueDTO(
                                techniqueId: nil,
                                categoryRaw: selectedCategory.rawValue,
                                type: selectedType.rawValue,
                                regionRaw: selectedRegion?.rawValue
                            )
                        )
                        dismiss()
                    }
                    .disabled(!isValidSelection)
                }
            }
            .onAppear { syncDefaults() }
            .onChange(of: selectedCategory) { _, _ in syncDefaults() }
            .onChange(of: selectedType) { _, _ in syncRegionForType() }
        }
    }

    private var shouldShowRegion: Bool {
        selectedCategory == .block
    }

    private var isValidSelection: Bool {
        if shouldShowRegion {
            return selectedRegion != nil
        }
        return true
    }

    private var selectedRegionBinding: Binding<AnesthesiaTechniqueRegion?> {
        Binding(
            get: { selectedRegion },
            set: { selectedRegion = $0 }
        )
    }

    private func syncDefaults() {
        let availableTypes = AnesthesiaTechniqueHelper.types(for: selectedCategory)
        if !availableTypes.contains(selectedType) {
            selectedType = availableTypes.first ?? .tiva
        }
        syncRegionForType()
    }

    private func syncRegionForType() {
        guard shouldShowRegion else {
            selectedRegion = nil
            return
        }
        let regions = AnesthesiaTechniqueHelper.regions(for: selectedType)
        if !regions.contains(selectedRegion ?? regions.first ?? .axilar) {
            selectedRegion = regions.first
        }
    }
}

#if DEBUG
#Preview {
    AnesthesiaTechniquePickerView { _ in }
}
#endif
