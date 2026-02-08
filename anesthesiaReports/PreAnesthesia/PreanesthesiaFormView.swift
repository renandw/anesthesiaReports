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
    @State private var clearance: PreanesthesiaClearanceDTO?
    @State private var showClearanceSheet = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var submitVisualState: SubmitVisualState = .idle
    @State private var hasAttemptedSubmit = false

    private var isEditing: Bool { initialPreanesthesia != nil }

    var body: some View {
        Form {
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

            PreanesthesiaClearanceSection(clearance: clearance, onEdit: {
                showClearanceSheet = true
            })

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
        }
        .navigationTitle(isEditing ? "Editar Pré-anestesia" : "Criar Pré-anestesia")
        .onAppear {
            loadInitial()
        }
        .sheet(isPresented: $showingTechniqueSheet) {
            AnesthesiaTechniquePickerView { technique in
                anesthesiaTechniques.append(technique)
            }
        }
        .sheet(isPresented: $showClearanceSheet) {
            if let preanesthesiaId = initialPreanesthesia?.preanesthesiaId {
                PreanesthesiaClearancePickerView(
                    status: clearanceStatusOrDefault(),
                    selectedItems: clearance?.items.map { $0.itemValue } ?? []
                ) { status, items in
                    Task {
                        await saveClearance(
                            preanesthesiaId: preanesthesiaId,
                            status: status,
                            items: items
                        )
                    }
                }
            } else {
                Text("Salve a pré-anestesia para editar o clearance.")
                    .presentationDetents([.medium])
            }
        }
    }

    private var isSubmitting: Bool {
        isSaving || submitVisualState == .submitting
    }

    private var submitButtonTitle: String {
        switch submitVisualState {
        case .idle:
            return "Salvar pré-anestesia"
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

    private func loadInitial() {
        if let initialPreanesthesia {
            status = initialPreanesthesia.status
            asaSelection = parseASA(initialPreanesthesia.asaRaw)
            anesthesiaTechniques = initialPreanesthesia.anesthesiaTechniques
            Task { await loadClearance(preanesthesiaId: initialPreanesthesia.preanesthesiaId) }
            return
        }

        Task {
            do {
                let shared = try await sharedPreSession.getBySurgery(surgeryId: surgeryId)
                asaSelection = parseASA(shared.asaRaw)
                anesthesiaTechniques = shared.anesthesiaTechniques
            } catch {
                // ignore if no shared_pre_anesthesia
            }
        }
    }

    private func loadClearance(preanesthesiaId: String) async {
        do {
            clearance = try await preanesthesiaSession.getClearance(preanesthesiaId: preanesthesiaId)
        } catch {
            clearance = nil
        }
    }

    private func clearanceStatusOrDefault() -> ClearanceStatus {
        if let raw = clearance?.status, let status = ClearanceStatus(rawValue: raw) {
            return status
        }
        return .able
    }

    private func saveClearance(
        preanesthesiaId: String,
        status: ClearanceStatus,
        items: [String]
    ) async {
        let input = UpsertPreanesthesiaClearanceInput(
            status: status.rawValue,
            items: items.map { PreanesthesiaClearanceItemInput(
                item_type: status.itemType,
                item_value: $0
            )}
        )

        do {
            clearance = try await preanesthesiaSession.upsertClearance(
                preanesthesiaId: preanesthesiaId,
                input: input
            )
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro ao salvar clearance"
        }
    }

    private func save() async {
        hasAttemptedSubmit = true
        guard inlineValidationMessage == nil else { return }

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
                        anesthesia_techniques: anesthesiaTechniques.map { mapTechniqueInput($0) }
                    )
                )
                onSaved?(response)
            } else {
                let response = try await preanesthesiaSession.create(
                    input: CreatePreanesthesiaInput(
                        surgery_id: surgeryId,
                        status: status,
                        asa_raw: asaSelection?.displayName ?? "",
                        anesthesia_techniques: anesthesiaTechniques.map { mapTechniqueInput($0) }
                    )
                )
                onSaved?(response)
            }

            submitVisualState = .success
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
        let categoryName = technique.categoryRaw.capitalized
        let typeName = technique.type.replacingOccurrences(of: "_", with: " ").capitalized
        return "\(categoryName) · \(typeName)"
    }

    private func regionDisplayName(_ region: String) -> String {
        region.replacingOccurrences(of: "_", with: " ").capitalized
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
}

#Preview {
    NavigationStack {
        PreanesthesiaFormView(surgeryId: "surgery", initialPreanesthesia: nil, mode: .standalone)
            .environmentObject(AuthSession())
            .environmentObject(SharedPreAnesthesiaSession(authSession: AuthSession()))
            .environmentObject(PreanesthesiaSession(authSession: AuthSession(), api: PreanesthesiaAPI()))
    }
}
