import SwiftUI

struct AnesthesiaFormView: View {
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

    @EnvironmentObject private var anesthesiaSession: AnesthesiaSession
    @Environment(\.dismiss) private var dismiss

    var mode: Mode = .standalone
    let surgeryId: String
    let initialAnesthesia: SurgeryAnesthesiaDetailsDTO?
    let onComplete: ((SurgeryAnesthesiaDetailsDTO) -> Void)?

    @State private var surgeryStartAt = Date()
    @State private var surgeryEndAt = Date()
    @State private var hasSurgeryStartAt = false
    @State private var hasSurgeryEndAt = false

    @State private var anesthesiaStartAt = Date()
    @State private var anesthesiaEndAt = Date()
    @State private var hasAnesthesiaStartAt = false
    @State private var hasAnesthesiaEndAt = false

    @State private var asaSelection: ASAClassification?
    @State private var anesthesiaTechniques: [AnesthesiaTechniqueDTO] = []
    @State private var showingTechniqueSheet = false
    @State private var positioning: Positioning?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isDeleting = false
    @State private var anesthesiaId: String?
    @State private var existingAnesthesia: SurgeryAnesthesiaDetailsDTO?
    @State private var submitVisualState: SubmitVisualState = .idle
    @State private var hasAttemptedSubmit = false
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
                wizardBody
            }
        }
        .onAppear { loadInitialIfNeeded() }
    }

    private var formContent: some View {
        Form {
            Section {
                DateTimePickerSheet(
                    date: $anesthesiaStartAt,
                    isSelected: $hasAnesthesiaStartAt,
                    title: "Anestesia",
                    placeholder: "Selecionar",
                    minDate: minDate,
                    maxDate: maxDate
                )
                DateTimePickerSheet(
                    date: $surgeryStartAt,
                    isSelected: $hasSurgeryStartAt,
                    title: "Cirurgia",
                    placeholder: "Selecionar",
                    minDate: minDate,
                    maxDate: maxDate
                )

               
            } header: {
                Text("Início do Procedimento")
            }
            if isEditingExisting {
                Section {
                    DateTimePickerSheet(
                        date: $surgeryEndAt,
                        isSelected: $hasSurgeryEndAt,
                        title: "Cirurgia",
                        placeholder: "Selecionar",
                        minDate: minDate,
                        maxDate: maxDate
                    )
                    DateTimePickerSheet(
                        date: $anesthesiaEndAt,
                        isSelected: $hasAnesthesiaEndAt,
                        title: "Anestesia",
                        placeholder: "Selecionar",
                        minDate: minDate,
                        maxDate: maxDate
                    )
                } header: {
                    Text("Fim do Procedimento")
                }
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
                NavigationLink {
                    PositionPickerView(selection: $positioning)
                } label: {
                    HStack {
                        Text("Posicionamento")
                        Spacer()
                        if let positioning {
                            Text(positioning.rawValue)
                                .foregroundStyle(.primary)
                        } else {
                            Text("Selecionar")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Posicionamento")
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
                        Task { await deleteAnesthesia() }
                    } label: {
                        Text(isDeleting ? "Excluindo..." : "Excluir Anesthesia")
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
                .navigationTitle(isEditingExisting ? "Editar Anestesia" : "Criar Anestesia")
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

    private var wizardBody: some View {
        formContent
    }

    private var isSubmitting: Bool {
        isLoading || submitVisualState == .submitting
    }

    private var isEditingExisting: Bool {
        anesthesiaId != nil || initialAnesthesia != nil || existingAnesthesia != nil
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
        return hasAnesthesiaStartAt
            || hasSurgeryStartAt
            || hasSurgeryEndAt
            || hasAnesthesiaEndAt
            || asaSelection != nil
            || !anesthesiaTechniques.isEmpty
    }

    private var validationErrorMessage: String? {
        if isEditingExisting {
            if !hasAnesthesiaStartAt && !hasAnesthesiaEndAt && !hasSurgeryStartAt && !hasSurgeryEndAt {
                return "Início e fim da anestesia e cirurgia são obrigatórios"
            }
            if !hasAnesthesiaStartAt {
                return "Início da anestesia é obrigatório"
            }
            if !hasSurgeryStartAt {
                return "Início da cirurgia é obrigatório"
            }
            if !hasSurgeryEndAt {
                return "Fim da cirurgia é obrigatório"
            }
            if !hasAnesthesiaEndAt {
                return "Fim da anestesia é obrigatório"
            }
        } else {
            if !hasAnesthesiaStartAt && !hasSurgeryStartAt {
                return "Início da anestesia e da cirurgia são obrigatórios"
            }
            if !hasAnesthesiaStartAt {
                return "Início da anestesia é obrigatório"
            }
            if !hasSurgeryStartAt {
                return "Início da cirurgia é obrigatório"
            }
        }
        
        if surgeryStartAt < anesthesiaStartAt {
            return "Cirurgia não pode começar antes da anestesia"
        }
        if isEditingExisting && surgeryEndAt < surgeryStartAt {
            return "Fim da cirurgia não pode ser antes do início"
        }
        if isEditingExisting && anesthesiaEndAt < anesthesiaStartAt {
            return "Fim da anestesia não pode ser antes do início"
        }
        if isEditingExisting && anesthesiaEndAt < surgeryEndAt {
            return "Anestesia não pode terminar antes do fim da cirurgia"
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
        print("ANESTHESIA_FORM initialAnesthesia:", initialAnesthesia?.anesthesiaId ?? "nil")
        guard let initial = initialAnesthesia else { return }
        applyExistingAnesthesia(initial)
    }

    private func applyExistingAnesthesia(_ anesthesia: SurgeryAnesthesiaDetailsDTO) {
        existingAnesthesia = anesthesia
        anesthesiaId = anesthesia.anesthesiaId

        if let value = anesthesia.surgeryStartAt {
            surgeryStartAt = value
            hasSurgeryStartAt = true
        }

        if let value = anesthesia.surgeryEndAt {
            surgeryEndAt = value
            hasSurgeryEndAt = true
        } else {
            surgeryEndAt = surgeryStartAt
            hasSurgeryEndAt = false
        }

        if let value = anesthesia.startAt {
            anesthesiaStartAt = value
            hasAnesthesiaStartAt = true
        }

        if let value = anesthesia.endAt {
            anesthesiaEndAt = value
            hasAnesthesiaEndAt = true
        } else {
            anesthesiaEndAt = anesthesiaStartAt
            hasAnesthesiaEndAt = false
        }

        asaSelection = parseASA(anesthesia.asaRaw)
        positioning = parsePositioning(anesthesia.positionRaw)
        anesthesiaTechniques = anesthesia.anesthesiaTechniques
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
            let surgeryStartISO = Self.isoDateTimeFormatter.string(from: surgeryStartAt)
            let surgeryEndISO = Self.isoDateTimeFormatter.string(from: surgeryEndAt)
            let anesthesiaStartISO = Self.isoDateTimeFormatter.string(from: anesthesiaStartAt)
            let anesthesiaEndISO = Self.isoDateTimeFormatter.string(from: anesthesiaEndAt)
            let techniqueInputs = anesthesiaTechniques.map {
                AnesthesiaTechniqueInput(
                    categoryRaw: $0.categoryRaw,
                    type: $0.type,
                    regionRaw: $0.regionRaw
                )
            }
            print("ANESTHESIA_SUBMIT payload:", [
                "surgery_id": surgeryId,
                "surgery_start_at": surgeryStartISO,
                "surgery_end_at": surgeryEndISO,
                "start_at": anesthesiaStartISO,
                "end_at": anesthesiaEndISO,
                "position_raw": positioning?.rawValue ?? "",
                "asa_raw": asaValue,
                "anesthesia_techniques": anesthesiaTechniques.map { [
                    "category_raw": $0.categoryRaw,
                    "type": $0.type,
                    "region_raw": $0.regionRaw ?? "null",
                ] }
            ])

            let updated: SurgeryAnesthesiaDetailsDTO
            if let anesthesiaId {
                print("ANESTHESIA_SUBMIT mode: PATCH", anesthesiaId)
                let input = UpdateAnesthesiaInput(
                    surgery_start_at: surgeryStartISO,
                    surgery_end_at: surgeryEndISO,
                    start_at: anesthesiaStartISO,
                    end_at: anesthesiaEndISO,
                    position_raw: positioning?.rawValue,
                    asa_raw: asaValue,
                    status: nil,
                    anesthesia_techniques: techniqueInputs
                )
                updated = try await anesthesiaSession.update(
                    anesthesiaId: anesthesiaId,
                    input: input
                )
            } else {
                print("ANESTHESIA_SUBMIT mode: POST")
                let input = CreateAnesthesiaInput(
                    surgery_id: surgeryId,
                    surgery_start_at: surgeryStartISO,
                    start_at: anesthesiaStartISO,
                    end_at: nil,
                    position_raw: positioning?.rawValue,
                    asa_raw: asaValue,
                    anesthesia_techniques: techniqueInputs
                )
                updated = try await anesthesiaSession.create(input: input)
            }

            applyExistingAnesthesia(updated)
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

    private func deleteAnesthesia() async {
        if isDeleting || isSubmitting { return }
        guard let anesthesiaId else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await anesthesiaSession.delete(anesthesiaId: anesthesiaId)
            self.anesthesiaId = nil
            existingAnesthesia = nil
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

    private func removeTechnique(at offsets: IndexSet) {
        anesthesiaTechniques.remove(atOffsets: offsets)
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
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowered = trimmed.lowercased()
        let normalized: String
        if lowered.hasPrefix("asa") {
            normalized = String(trimmed.dropFirst(3))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            normalized = trimmed
        }

        let normalizedLower = normalized.lowercased()
        if let match = ASAClassification.allCases.first(where: { $0.rawValue.lowercased() == normalizedLower }) {
            return match
        }

        return ASAClassification.allCases.first(where: { $0.displayName.lowercased() == lowered })
    }

    private func parsePositioning(_ rawValue: String?) -> Positioning? {
        guard let rawValue else { return nil }
        return Positioning.allCases.first { $0.rawValue == rawValue }
    }
}

#if DEBUG
#Preview {
    AnesthesiaFormView(
        mode: .standalone,
        surgeryId: UUID().uuidString,
        initialAnesthesia: nil,
        onComplete: { _ in }
    )
    .environmentObject(AnesthesiaSession(authSession: AuthSession(), api: AnesthesiaAPI()))
}
#endif
