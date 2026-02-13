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
    @State private var preanesthesiaItems: [PreanesthesiaItemInput] = []
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
            Section {
                NavigationLink {
                    Form {
                        PreanesthesiaComorbiditiesSection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Comorbidades")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Comorbidades")
                        Spacer()
                        Text(comorbiditiesSummary)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Comorbidades")
            }
            Section {
                NavigationLink {
                    Form {
                        PreanesthesiaSurgeryHistorySection(items: $preanesthesiaItems)
                        PreanesthesiaAnesthesiaHistorySection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Histórico Cirúrgico-Anestésico")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Cirúrgico")
                        Spacer()
                        Text(surgerySummary)
                            .foregroundStyle(.secondary)
                    }
                }
                if hasSurgeryHistory {
                    NavigationLink {
                        Form {
                            PreanesthesiaAnesthesiaHistorySection(items: $preanesthesiaItems)
                        }
                        .navigationTitle("Histórico Anestésico")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("Anestésico")
                            Spacer()
                            Text(anesthesiaSummary)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                NavigationLink {
                    Form {
                        PreanesthesiaNVPOSection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Náuseas e Vômitos")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Náuseas e Vômitos")
                        Spacer()
                        Text(nvpoSummary)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Histórico Cirúrgico Anestésico")
            }
            Section {
                NavigationLink {
                    Form {
                        PreanesthesiaAirwaySection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Avaliação Via Aérea")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Avaliação Via Aérea")
                        Spacer()
                        Text(airwaySummary)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    Form {
                        PreanesthesiaSocialAndEnvironmentSection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Hábitos e Ambiente")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Hábitos e Ambiente")
                        Spacer()
                        Text(airwaySummary)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    Form {
                        PreanesthesiaPhysicalExamSection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Exame Físico")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                preanesthesiaItems = PreanesthesiaPhysicalExamSection
                                    .applyingDefaultTexts(to: preanesthesiaItems)
                            } label: {
                                Image(systemName: "wand.and.sparkles.inverse")
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Exame Físico")
                        Spacer()
                        Text(airwaySummary)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    Form {
                        PreanesthesiaLabsAndImageSection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Exames e Imagens")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Exames e Imagens")
                        Spacer()
                        Text(labsAndImageSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    Form {
                        PreanesthesiaMedicationsSection(items: $preanesthesiaItems)
                    }
                    .navigationTitle("Medicações")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Medicações")
                        Spacer()
                        Text(medicationsSummary)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Exame Físico")
            }
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInitial()
        }
        .onChange(of: preanesthesiaItems) { oldValue, newValue in
            let synced = syncNvpoWithAnesthesiaHistory(old: oldValue, new: newValue)
            if synced != newValue {
                preanesthesiaItems = synced
            }
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
                preanesthesiaItems = mapPreanesthesiaItems(initialPreanesthesia.items)
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
                        clearance: clearanceInput(),
                        items: preanesthesiaItems.isEmpty ? nil : preanesthesiaItems
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
                        clearance: clearanceInput(),
                        items: preanesthesiaItems.isEmpty ? nil : preanesthesiaItems
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

    private func mapPreanesthesiaItems(_ items: [PreanesthesiaItemDTO]?) -> [PreanesthesiaItemInput] {
        guard let items else { return [] }
        return items.map {
            PreanesthesiaItemInput(
                domain: $0.domain,
                category: $0.category,
                code: $0.code,
                is_custom: $0.isCustom,
                custom_label: $0.customLabel,
                details: $0.details
            )
        }
    }

    private func syncNvpoWithAnesthesiaHistory(
        old: [PreanesthesiaItemInput],
        new: [PreanesthesiaItemInput]
    ) -> [PreanesthesiaItemInput] {
        var updated = new
        let hadNausea = containsAnesthesiaNausea(in: old)
        let hasNausea = containsAnesthesiaNausea(in: new)
        let hadApfel = containsApfelHistoryPONV(in: old)
        let hasApfel = containsApfelHistoryPONV(in: new)
        let hadSmoking = containsSmokingCurrent(in: old)
        let hasSmoking = containsSmokingCurrent(in: new)
        let hadTobacco = containsApfelTobaccoUse(in: old)
        let hasTobacco = containsApfelTobaccoUse(in: new)

        if hadNausea && !hasNausea && hasApfel {
            updated = removeApfelHistoryPONV(from: updated)
        } else if hadApfel && !hasApfel && hasNausea {
            updated = removeAnesthesiaNausea(from: updated)
        } else if hasNausea && !hasApfel {
            updated = addApfelHistoryPONV(to: updated)
        } else if hasApfel && !hasNausea {
            updated = addAnesthesiaNausea(to: updated)
        }

        if hadSmoking && !hasSmoking && hasTobacco {
            updated = removeApfelTobaccoUse(from: updated)
        } else if hadTobacco && !hasTobacco && hasSmoking {
            updated = removeSmokingCurrent(from: updated)
        } else if hasSmoking && !hasTobacco {
            updated = addApfelTobaccoUse(to: updated)
        } else if hasTobacco && !hasSmoking {
            updated = addSmokingCurrent(to: updated)
        }

        return updated
    }

    private func containsAnesthesiaNausea(in items: [PreanesthesiaItemInput]) -> Bool {
        items.contains {
            $0.domain == PreanesthesiaItemDomain.anesthesiaHistory.rawValue &&
            $0.category == AnesthesiaHistoryCategory.complications.rawValue &&
            $0.code == AnesthesiaComplicationsHistoryCode.nausea.rawValue &&
            !$0.is_custom
        }
    }

    private func containsApfelHistoryPONV(in items: [PreanesthesiaItemInput]) -> Bool {
        items.contains {
            $0.domain == PreanesthesiaItemDomain.nvpo.rawValue &&
            $0.category == NVPOCategory.nvpo.rawValue &&
            $0.code == ApfelScoreCode.historyPONV.rawValue &&
            !$0.is_custom
        }
    }

    private func containsSmokingCurrent(in items: [PreanesthesiaItemInput]) -> Bool {
        items.contains {
            $0.domain == PreanesthesiaItemDomain.environment.rawValue &&
            $0.category == SocialAndEnvironmentCategory.tobacco.rawValue &&
            $0.code == SmokingCode.current.rawValue &&
            !$0.is_custom
        }
    }

    private func containsApfelTobaccoUse(in items: [PreanesthesiaItemInput]) -> Bool {
        items.contains {
            $0.domain == PreanesthesiaItemDomain.nvpo.rawValue &&
            $0.category == NVPOCategory.nvpo.rawValue &&
            $0.code == ApfelScoreCode.tobaccoUse.rawValue &&
            !$0.is_custom
        }
    }

    private func addApfelHistoryPONV(to items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        var updated = items
        updated.append(
            PreanesthesiaItemInput(
                domain: PreanesthesiaItemDomain.nvpo.rawValue,
                category: NVPOCategory.nvpo.rawValue,
                code: ApfelScoreCode.historyPONV.rawValue,
                is_custom: false,
                custom_label: nil,
                details: nil
            )
        )
        return updated
    }

    private func addAnesthesiaNausea(to items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        var updated = items
        updated.append(
            PreanesthesiaItemInput(
                domain: PreanesthesiaItemDomain.anesthesiaHistory.rawValue,
                category: AnesthesiaHistoryCategory.complications.rawValue,
                code: AnesthesiaComplicationsHistoryCode.nausea.rawValue,
                is_custom: false,
                custom_label: nil,
                details: nil
            )
        )
        return updated
    }

    private func addApfelTobaccoUse(to items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        var updated = items
        updated.append(
            PreanesthesiaItemInput(
                domain: PreanesthesiaItemDomain.nvpo.rawValue,
                category: NVPOCategory.nvpo.rawValue,
                code: ApfelScoreCode.tobaccoUse.rawValue,
                is_custom: false,
                custom_label: nil,
                details: nil
            )
        )
        return updated
    }

    private func addSmokingCurrent(to items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        var updated = items
        updated.append(
            PreanesthesiaItemInput(
                domain: PreanesthesiaItemDomain.environment.rawValue,
                category: SocialAndEnvironmentCategory.tobacco.rawValue,
                code: SmokingCode.current.rawValue,
                is_custom: false,
                custom_label: nil,
                details: nil
            )
        )
        return updated
    }

    private func removeApfelHistoryPONV(from items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        items.filter {
            !($0.domain == PreanesthesiaItemDomain.nvpo.rawValue &&
              $0.category == NVPOCategory.nvpo.rawValue &&
              $0.code == ApfelScoreCode.historyPONV.rawValue &&
              !$0.is_custom)
        }
    }

    private func removeAnesthesiaNausea(from items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        items.filter {
            !($0.domain == PreanesthesiaItemDomain.anesthesiaHistory.rawValue &&
              $0.category == AnesthesiaHistoryCategory.complications.rawValue &&
              $0.code == AnesthesiaComplicationsHistoryCode.nausea.rawValue &&
              !$0.is_custom)
        }
    }

    private func removeApfelTobaccoUse(from items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        items.filter {
            !($0.domain == PreanesthesiaItemDomain.nvpo.rawValue &&
              $0.category == NVPOCategory.nvpo.rawValue &&
              $0.code == ApfelScoreCode.tobaccoUse.rawValue &&
              !$0.is_custom)
        }
    }

    private func removeSmokingCurrent(from items: [PreanesthesiaItemInput]) -> [PreanesthesiaItemInput] {
        items.filter {
            !($0.domain == PreanesthesiaItemDomain.environment.rawValue &&
              $0.category == SocialAndEnvironmentCategory.tobacco.rawValue &&
              $0.code == SmokingCode.current.rawValue &&
              !$0.is_custom)
        }
    }

    private var comorbiditiesSummary: String {
        let comorbidityItems = preanesthesiaItems.filter {
            $0.domain == PreanesthesiaItemDomain.comorbidity.rawValue
        }
        let count = comorbidityItems.count
        if count == 0 { return "Sem comorbidades" }
        return count == 1 ? "1 comorbidade" : "\(count) comorbidades"
    }
    private var surgerySummary: String {
        let comorbidityItems = preanesthesiaItems.filter {
            $0.domain == PreanesthesiaItemDomain.surgeryHistory.rawValue
        }
        let count = comorbidityItems.count
        if count == 0 { return "Sem cirurgias prévias" }
        return count == 1 ? "1 cirurgia" : "\(count) cirurgias"
    }
    private var anesthesiaSummary: String {
        let comorbidityItems = preanesthesiaItems.filter {
            $0.domain == PreanesthesiaItemDomain.anesthesiaHistory.rawValue
        }
        let count = comorbidityItems.count
        if count == 0 { return "Sem complicações" }
        return count == 1 ? "1 complicação" : "\(count) complicações"
    }
    private var airwaySummary: String {
        let comorbidityItems = preanesthesiaItems.filter {
            $0.domain == PreanesthesiaItemDomain.airway.rawValue
        }
        let count = comorbidityItems.count
        if count == 0 { return "Sem avaliação" }
        return count == 1 ? "1 ponto" : "\(count) pontos"
    }
    private var nvpoSummary: String {
        let comorbidityItems = preanesthesiaItems.filter {
            $0.domain == PreanesthesiaItemDomain.nvpo.rawValue
        }
        let count = comorbidityItems.count
        if count == 0 { return "Sem fatores" }
        return count == 1 ? "1 fator" : "\(count) fatores"
    }

    private var labsAndImageSummary: String {
        let labsItems = preanesthesiaItems.filter {
            $0.domain == PreanesthesiaItemDomain.labsAndImage.rawValue
        }
        let count = labsItems.count
        if count == 0 { return "Sem exames" }
        return count == 1 ? "1 item" : "\(count) itens"
    }

    private var medicationsSummary: String {
        let medsItems = preanesthesiaItems.filter {
            $0.domain == PreanesthesiaItemDomain.medications.rawValue
        }
        let count = medsItems.count
        if count == 0 { return "Sem medicações" }
        return count == 1 ? "1 item" : "\(count) itens"
    }
    
    private var hasSurgeryHistory: Bool {
        preanesthesiaItems.contains {
            $0.domain == PreanesthesiaItemDomain.surgeryHistory.rawValue
        }
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
