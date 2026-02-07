import SwiftUI

struct SRPAFormView: View {
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

    @EnvironmentObject private var srpaSession: SRPASession
    @EnvironmentObject private var sharedPreSession: SharedPreAnesthesiaSession
    @Environment(\.dismiss) private var dismiss

    var mode: Mode = .standalone
    let surgeryId: String
    let initialSRPA: SurgerySRPADetailsDTO?
    let onComplete: ((SurgerySRPADetailsDTO) -> Void)?

    @State private var srpaStartAt = Date()
    @State private var srpaEndAt = Date()
    @State private var hasSrpaStartAt = false
    @State private var hasSrpaEndAt = false
    @State private var asaSelection: ASAClassification?
    @State private var anesthesiaTechniques: [AnesthesiaTechniqueDTO] = []
    @State private var showingTechniqueSheet = false

    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isDeleting = false
    @State private var submitVisualState: SubmitVisualState = .idle
    @State private var hasAttemptedSubmit = false

    @State private var srpaId: String?
    @State private var existingSRPA: SurgerySRPADetailsDTO?
    @State private var anesthesiaEndAt: Date?
    @State private var surgeryEndAt: Date?
    @State private var hasLoadedExisting = false

    private static let isoDateTimeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    var body: some View {
        Group {
            switch mode {
            case .standalone:
                standaloneBody
            case .wizard:
                formContent
            }
        }
        .onAppear { loadInitialIfNeeded() }
    }

    private var formContent: some View {
        Form {
            Section {
                DetailRow(
                    label: "Fim da cirurgia",
                    value: surgeryEndAt
                        .map { DateFormatterHelper.format($0, dateStyle: .medium, timeStyle: .short) }
                    ?? "Não informado"
                )
                DetailRow(
                    label: "Fim da anestesia",
                    value: anesthesiaEndAt
                        .map { DateFormatterHelper.format($0, dateStyle: .medium, timeStyle: .short) }
                    ?? "Não informado"
                )
            } header: {
                Text("Referências da Anestesia")
            }
            Section {
                DateTimePickerSheet(
                    date: $srpaStartAt,
                    isSelected: $hasSrpaStartAt,
                    title: "Início SRPA",
                    placeholder: "Selecionar",
                    minDate: minDate,
                    maxDate: maxDate
                )
                if isEditingExisting{
                    DateTimePickerSheet(
                        date: $srpaEndAt,
                        isSelected: $hasSrpaEndAt,
                        title: "Alta às",
                        placeholder: "Selecionar",
                        minDate: minDate,
                        maxDate: maxDate
                    )
                }
            } header: {
                Text("SRPA")
            }

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
                if anesthesiaTechniques.isEmpty {
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

                Button("Adicionar técnica") {
                    showingTechniqueSheet = true
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
                    Task { await submit() }
                } label: {
                    Text(submitButtonTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                }
                .listRowBackground(submitButtonColor)
                .disabled(isSubmitting)

                if mode == .standalone, isEditingExisting {
                    Button {
                        Task { await deleteSRPA() }
                    } label: {
                        Text(isDeleting ? "Excluindo..." : "Excluir SRPA")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.red)
                    .disabled(isSubmitting || isDeleting)
                }
            }
        }
        .sheet(isPresented: $showingTechniqueSheet) {
            AnesthesiaTechniquePickerView { technique in
                anesthesiaTechniques.append(technique)
            }
        }
    }

    private var standaloneBody: some View {
        NavigationStack {
            formContent
                .navigationTitle(isEditingExisting ? "Editar SRPA" : "Criar SRPA")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar", systemImage: "checkmark") {
                            Task { await submit() }
                        }
                        .disabled(isSubmitting || isDeleting)
                    }
                }
        }
    }

    private var isSubmitting: Bool {
        isLoading || submitVisualState == .submitting
    }

    private var isEditingExisting: Bool {
        srpaId != nil || initialSRPA != nil || existingSRPA != nil
    }

    private var minDate: Date {
        Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? .distantPast
    }

    private var maxDate: Date {
        Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? .distantFuture
    }

    private var submitButtonTitle: String {
        switch submitVisualState {
        case .idle:
            return "Salvar"
        case .submitting:
            return "Enviando..."
        case .success:
            return "Sucesso"
        case .failure:
            return "Falha ao salvar"
        }
    }

    private var submitButtonColor: Color {
        switch submitVisualState {
        case .idle:
            return .blue
        case .submitting:
            return .orange
        case .success:
            return .green
        case .failure:
            return .red
        }
    }

    private var inlineValidationMessage: String? {
        shouldShowValidation ? validationErrorMessage : nil
    }

    private var shouldShowValidation: Bool {
        if hasAttemptedSubmit { return true }
        return hasSrpaStartAt || hasSrpaEndAt || asaSelection != nil || !anesthesiaTechniques.isEmpty
    }

    private var validationErrorMessage: String? {
        if !hasSrpaStartAt {
            return "Início da SRPA é obrigatório"
        }
        if hasSrpaEndAt && srpaEndAt < srpaStartAt {
            return "Fim da SRPA não pode ser antes do início"
        }
        if anesthesiaTechniques.isEmpty {
            return "Informe ao menos uma técnica"
        }
        if asaSelection == nil {
            return "ASA é obrigatório"
        }
        return nil
    }

    private func loadInitialIfNeeded() {
        guard !hasLoadedExisting else { return }
        hasLoadedExisting = true

        if let initial = initialSRPA {
            applyExistingSRPA(initial)
            return
        }

        Task { await loadExistingBySurgery() }
    }

    private func loadExistingBySurgery() async {
        do {
            let srpa = try await srpaSession.getBySurgery(surgeryId: surgeryId)
            applyExistingSRPA(srpa)
        } catch let authError as AuthError {
            if case .notFound = authError {
                await loadSharedPre()
                return
            }
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func loadSharedPre() async {
        do {
            let shared = try await sharedPreSession.getBySurgery(surgeryId: surgeryId)
            applySharedPre(shared)
        } catch {
            return
        }
    }

    private func applySharedPre(_ shared: SharedPreAnesthesiaDTO) {
        if asaSelection == nil {
            asaSelection = parseASA(shared.asaRaw)
        }
        if anesthesiaTechniques.isEmpty {
            anesthesiaTechniques = shared.anesthesiaTechniques
        }
    }

    private func applyExistingSRPA(_ srpa: SurgerySRPADetailsDTO) {
        existingSRPA = srpa
        srpaId = srpa.srpaId
        anesthesiaEndAt = srpa.anesthesiaEndAt
        surgeryEndAt = srpa.surgeryEndAt
        asaSelection = parseASA(srpa.asaRaw)
        anesthesiaTechniques = srpa.anesthesiaTechniques

        if let value = srpa.startAt {
            srpaStartAt = value
            hasSrpaStartAt = true
        }

        if let value = srpa.endAt {
            srpaEndAt = value
            hasSrpaEndAt = true
        } else {
            srpaEndAt = srpaStartAt
            hasSrpaEndAt = false
        }
    }

    private func submit() async {
        if isSubmitting { return }
        hasAttemptedSubmit = true
        if validationErrorMessage != nil {
            return
        }

        errorMessage = nil
        isLoading = true
        submitVisualState = .submitting
        defer { isLoading = false }

        do {
            let asaValue = asaSelection?.displayName ?? ""
            let startISO = Self.isoDateTimeFormatter.string(from: srpaStartAt)
            let endISO = hasSrpaEndAt ? Self.isoDateTimeFormatter.string(from: srpaEndAt) : nil
            let techniqueInputs = anesthesiaTechniques.map {
                AnesthesiaTechniqueInput(
                    categoryRaw: $0.categoryRaw,
                    type: $0.type,
                    regionRaw: $0.regionRaw
                )
            }

            let updated: SurgerySRPADetailsDTO
            if let srpaId {
                let input = UpdateSRPAInput(
                    start_at: startISO,
                    end_at: endISO,
                    status: nil,
                    asa_raw: asaValue,
                    anesthesia_techniques: techniqueInputs
                )
                updated = try await srpaSession.update(srpaId: srpaId, input: input)
            } else {
                let input = CreateSRPAInput(
                    surgery_id: surgeryId,
                    start_at: startISO,
                    end_at: endISO,
                    status: nil,
                    asa_raw: asaValue,
                    anesthesia_techniques: techniqueInputs
                )
                updated = try await srpaSession.create(input: input)
            }

            applyExistingSRPA(updated)
            onComplete?(updated)
            submitVisualState = .success
            try? await Task.sleep(nanoseconds: 700_000_000)
            submitVisualState = .idle
            if mode == .standalone { dismiss() }
        } catch let authError as AuthError {
            await failSubmit(authError.userMessage)
        } catch {
            await failSubmit("Erro de rede")
        }
    }

    private func deleteSRPA() async {
        if isDeleting || isSubmitting { return }
        guard let srpaId else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await srpaSession.delete(srpaId: srpaId)
            self.srpaId = nil
            existingSRPA = nil
            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
    }

    private func failSubmit(_ message: String) async {
        errorMessage = message
        submitVisualState = .failure
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        submitVisualState = .idle
    }

    private func parseASA(_ value: String?) -> ASAClassification? {
        guard let raw = value?.uppercased().replacingOccurrences(of: "ASA ", with: "") else {
            return nil
        }
        return ASAClassification(rawValue: raw)
    }

    private func removeTechnique(at offsets: IndexSet) {
        anesthesiaTechniques.remove(atOffsets: offsets)
    }

    private func techniqueSummary(_ technique: AnesthesiaTechniqueDTO) -> String {
        let categoryName = categoryDisplayName(technique.categoryRaw)
        let typeName = typeDisplayName(technique.type)
        return "\(categoryName) - \(typeName)"
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
}

#Preview {
    SRPAFormView(
        mode: .standalone,
        surgeryId: "surgery-123",
        initialSRPA: nil,
        onComplete: nil
    )
    .environmentObject(SRPASession(authSession: AuthSession(), api: SRPAAPI()))
    .environmentObject(SharedPreAnesthesiaSession(authSession: AuthSession()))
}
