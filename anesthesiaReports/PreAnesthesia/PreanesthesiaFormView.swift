import SwiftUI

struct PreanesthesiaFormView: View {
    enum Mode {
        case standalone
        case wizard
    }

    private enum SubmitVisualState {
        case idle
        case submitting
        case success
        case failure
    }

    private enum DeleteVisualState {
        case idle
        case deleting
        case success
        case failure
    }
    private enum LoadingScope: Hashable {
        case sharedPre
    }

    let surgeryId: String
    let initialPreanesthesia: SurgeryPreanesthesiaDetailsDTO?
    let mode: Mode
    var onSaved: ((SurgeryPreanesthesiaDetailsDTO) -> Void)?

    @EnvironmentObject private var preanesthesiaSession: PreanesthesiaSession
    @EnvironmentObject private var sharedPreSession: SharedPreAnesthesiaSession

    @Environment(\.dismiss) private var dismiss

    @State private var status = "in_progress_pre"
    @State private var asaSelection: ASAClassification?
    @State private var anesthesiaTechniques: [AnesthesiaTechniqueDTO] = []
    @State private var showingTechniqueSheet = false
    @State private var clearanceStatus: ClearanceStatus?
    @State private var clearanceItems: [String] = []
    @State private var showClearanceSheet = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var deleteVisualState: DeleteVisualState = .idle
    @State private var showDeleteConfirm = false
    @State private var submitVisualState: SubmitVisualState = .idle
    @State private var hasAttemptedSubmit = false
    @State private var loadingScopes: Set<LoadingScope> = []
    @State private var hasLoadedShared = false
    @State private var didLoadInitial = false

    private var isEditing: Bool { initialPreanesthesia != nil }

    var body: some View {
        Form {
            PreanesthesiaClearanceSection(
                status: clearanceStatus,
                items: clearanceItems,
                onEdit: { status, items in
                    clearanceStatus = status
                    clearanceItems = items
                }
            )
            Section {
                NavigationLink {
                    AsaPickerView(selection: $asaSelection)
                } label: {
                    HStack {
                        Text("ASA")
                        Spacer()
                        if let asaSelection {
                            asaSelection.badgeView
                        } else {
                            Text("Selecionar")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Classificação ASA")
            }

            Section {
                if !hasLoadedShared {
                    techniquesShimmer
                } else if anesthesiaTechniques.isEmpty {
                    Text("Nenhuma técnica adicionada")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(anesthesiaTechniques, id: \.self) { technique in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(techniqueSummary(technique))
                                    .font(.subheadline)
                                if let region = technique.regionRaw {
                                    Text(regionDisplayName(region))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .onDelete(perform: removeTechnique)
                }

                Button{
                    showingTechniqueSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Adicionar técnica")
                        
                    }
                }
            } header: {
                Text("Técnicas Anestésicas")
            }

            

            Section {
                if let inlineValidationMessage {
                    Text(inlineValidationMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    Text(submitButtonTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                }
                .listRowBackground(submitButtonColor)
                .disabled(isSubmitting)
            }

            if isEditing {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text(deleteButtonTitle)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(deleteButtonColor)
                    .disabled(isSubmitting || isDeleting)
                }
            }
        }
        .navigationTitle(isEditing ? "Editar APA" : "Criar APA")
        .task {
            await loadInitial()
        }
        .alert("Excluir pré-anestesia?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir", role: .destructive) {
                Task { await deletePreanesthesia() }
            }
        } message: {
            Text("Essa ação remove a pré-anestesia e não pode ser desfeita.")
        }
        .sheet(isPresented: $showingTechniqueSheet) {
            AnesthesiaTechniquePickerView { technique in
                anesthesiaTechniques.append(technique)
            }
        }
    }

    private var isSubmitting: Bool {
        isSaving || submitVisualState == .submitting
    }

    private var submitButtonTitle: String {
        switch submitVisualState {
        case .idle:
            return "Salvar APA"
        case .submitting:
            return "Enviando..."
        case .success:
            return "Sucesso"
        case .failure:
            return "Falha"
        }
    }

    private var submitButtonColor: Color {
        switch submitVisualState {
        case .idle, .submitting:
            return .blue
        case .success:
            return .green
        case .failure:
            return .red
        }
    }

    private var deleteButtonTitle: String {
        switch deleteVisualState {
        case .idle:
            return "Excluir pré-anestesia"
        case .deleting:
            return "Excluindo..."
        case .success:
            return "Excluída"
        case .failure:
            return "Falha"
        }
    }

    private var deleteButtonColor: Color {
        switch deleteVisualState {
        case .idle, .deleting:
            return .red
        case .success:
            return .green
        case .failure:
            return .red
        }
    }

    private var inlineValidationMessage: String? {
        guard hasAttemptedSubmit else { return nil }
        if asaSelection == nil {
            return "Selecione o ASA"
        }
        if anesthesiaTechniques.isEmpty {
            return "Selecione ao menos uma técnica"
        }
        return nil
    }

    private func failSubmit(_ message: String, authError: AuthError?) async {
        errorMessage = message
        submitVisualState = .failure
        let cooldownNs: UInt64
        if let authError, case .rateLimited = authError {
            cooldownNs = 5_000_000_000
        } else {
            cooldownNs = 1_500_000_000
        }
        try? await Task.sleep(nanoseconds: cooldownNs)
        submitVisualState = .idle
    }

    private func loadInitial() async {
        guard !didLoadInitial else { return }
        didLoadInitial = true
        if let initialPreanesthesia {
            status = initialPreanesthesia.status
            asaSelection = parseASA(initialPreanesthesia.asaRaw)
            anesthesiaTechniques = initialPreanesthesia.anesthesiaTechniques
            if let clearance = initialPreanesthesia.clearance {
                clearanceStatus = ClearanceStatus(rawValue: clearance.status)
                clearanceItems = clearance.items.map { $0.itemValue }
            }
            hasLoadedShared = true
            return
        }

        await loadSharedPre()
    }

    private func loadSharedPre(trackLoading: Bool = true) async {
        hasLoadedShared = false
        if trackLoading { loadingScopes.insert(.sharedPre) }
        defer {
            if trackLoading { loadingScopes.remove(.sharedPre) }
            hasLoadedShared = true
        }

        do {
            let shared = try await sharedPreSession.getBySurgery(surgeryId: surgeryId)
            asaSelection = parseASA(shared.asaRaw)
            anesthesiaTechniques = shared.anesthesiaTechniques
        } catch {
            // ignore if no shared_pre_anesthesia
        }
    }

    private func clearanceStatusOrDefault() -> ClearanceStatus {
        clearanceStatus ?? .able
    }

    private func save() async {
        hasAttemptedSubmit = true
        if let validationMessage = inlineValidationMessage {
            errorMessage = validationMessage
            return
        }

        errorMessage = nil
        submitVisualState = .submitting
        isSaving = true
        defer { isSaving = false }

        do {
            if let existing = initialPreanesthesia {
                let response = try await preanesthesiaSession.update(
                    preanesthesiaId: existing.preanesthesiaId,
                    input: UpdatePreanesthesiaInput(
                        status: status,
                        asa_raw: asaSelection?.displayName ?? "",
                        anesthesia_techniques: anesthesiaTechniques.map { mapTechniqueInput($0) },
                        clearance: clearanceInput()
                    )
                )
                onSaved?(response)
            } else {
                let response = try await preanesthesiaSession.create(
                    input: CreatePreanesthesiaInput(
                        surgery_id: surgeryId,
                        status: status,
                        asa_raw: asaSelection?.displayName ?? "",
                        anesthesia_techniques: anesthesiaTechniques.map { mapTechniqueInput($0) },
                        clearance: clearanceInput()
                    )
                )
                onSaved?(response)
            }

            submitVisualState = .success
            errorMessage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                submitVisualState = .idle
            }
            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            await failSubmit(authError.userMessage, authError: authError)
        } catch {
            await failSubmit("Erro de rede", authError: nil)
        }
    }

    private func deletePreanesthesia() async {
        guard let existing = initialPreanesthesia else { return }
        isDeleting = true
        deleteVisualState = .deleting
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await preanesthesiaSession.delete(preanesthesiaId: existing.preanesthesiaId)
            deleteVisualState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                deleteVisualState = .idle
            }
            if mode == .standalone { dismiss() }
        } catch let authError as AuthError {
            deleteVisualState = .failure
            await failSubmit(authError.userMessage, authError: authError)
        } catch {
            deleteVisualState = .failure
            await failSubmit("Erro de rede", authError: nil)
        }
    }

    private func removeTechnique(at offsets: IndexSet) {
        anesthesiaTechniques.remove(atOffsets: offsets)
    }

    private func mapTechniqueInput(_ technique: AnesthesiaTechniqueDTO) -> AnesthesiaTechniqueInput {
        AnesthesiaTechniqueInput(
            categoryRaw: technique.categoryRaw,
            type: technique.type,
            regionRaw: technique.regionRaw
        )
    }
    
    private func techniqueSummary(_ technique: AnesthesiaTechniqueDTO) -> String {
        let categoryName = categoryDisplayName(technique.categoryRaw)
        let typeName = typeDisplayName(technique.type)
        return "\(categoryName) · \(typeName)"
    }

    private func categoryDisplayName(_ raw: String) -> String {
        AnesthesiaTechniqueCategory(rawValue: raw)?.displayName ?? raw
    }

    private func typeDisplayName(_ raw: String) -> String {
        AnesthesiaTechniqueType(rawValue: raw)?.displayName ?? raw
    }

    private func regionDisplayName(_ raw: String) -> String {
        AnesthesiaTechniqueRegion(rawValue: raw)?.displayName ?? raw
    }


    private func parseASA(_ rawValue: String?) -> ASAClassification? {
        guard let rawValue else { return nil }
        let normalized = rawValue
            .replacingOccurrences(of: "ASA", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLower = normalized.lowercased()

        if let match = ASAClassification.allCases.first(where: { $0.rawValue.lowercased() == normalizedLower }) {
            return match
        }

        let lowered = rawValue.lowercased()
        return ASAClassification.allCases.first(where: { $0.displayName.lowercased() == lowered })
    }

    private var techniquesShimmer: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.25))
                .frame(height: 18)
                .shimmering()
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.25))
                .frame(height: 18)
                .shimmering()
        }
        .padding(.vertical, 4)
    }

    private func clearanceInput() -> UpsertPreanesthesiaClearanceInput? {
        guard let status = clearanceStatus else { return nil }
        return UpsertPreanesthesiaClearanceInput(
            status: status.rawValue,
            items: clearanceItems.map {
                PreanesthesiaClearanceItemInput(
                    item_type: status.itemType,
                    item_value: $0
                )
            }
        )
    }
}

#Preview {
    NavigationStack {
        PreanesthesiaFormView(surgeryId: "surgery", initialPreanesthesia: nil, mode: .standalone)
            .environmentObject(AuthSession())
            .environmentObject(SharedPreAnesthesiaSession(authSession: AuthSession()))
            .environmentObject(PreanesthesiaSession(authSession: AuthSession(), api: PreanesthesiaAPI()))
    }
}
