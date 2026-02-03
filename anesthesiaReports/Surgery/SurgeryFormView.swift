import SwiftUI

struct SurgeryFormView: View {
    enum Mode {
        case standalone
        case wizard
    }

    private enum Field: Hashable {
        case insuranceName
        case insuranceNumber
        case mainSurgeon
        case hospital
        case weight
        case proposedProcedure
        case completeProcedure
        case valueAnesthesia
    }

    @EnvironmentObject private var surgerySession: SurgerySession
    @Environment(\.dismiss) private var dismiss

    var mode: Mode = .standalone

    let patientId: String
    let existing: SurgeryDTO?
    let onComplete: ((SurgeryDTO) -> Void)?
    private let cbhpmCatalog = SurgeryCbhpmSearchView.loadCatalogFromBundle()

    @State private var date: String = ""
    @State private var insuranceName = ""
    @State private var insuranceNumber = ""
    @State private var mainSurgeon = ""
    @State private var auxiliarySurgeonsText = ""
    @State private var hospital = ""
    @State private var weight = ""
    @State private var proposedProcedure = ""
    @State private var completeProcedure = ""
    @State private var type: SurgeryType = .insurance
    @State private var valueAnesthesia = ""

    @State private var cbhpmCode = ""
    @State private var cbhpmProcedure = ""
    @State private var cbhpmPort = ""
    @State private var cbhpms: [SurgeryCbhpmInput] = []
    @State private var showCbhpmSheet = false
    @State private var cbhpmSheetError: String?
    @State private var duplicateMatches: [PrecheckSurgeryMatchDTO] = []
    @State private var showDuplicateSheet = false

    @State private var errorMessage: String?
    @State private var isLoading = false

    @FocusState private var focusedField: Field?

    var body: some View {
        Group {
            switch mode {
            case .standalone:
                standaloneBody
            case .wizard:
                wizardBody
            }
        }
        .sheet(isPresented: $showCbhpmSheet) {
            NavigationStack {
                cbhpmSheetContent
            }
        }
        .sheet(isPresented: $showDuplicateSheet) {
            SurgeryDuplicatePatientSheet(
                message: "Você está cadastrando uma cirurgia que pode já existir no banco de dados. Revise para evitar registros duplicados.",
                foundSurgeries: duplicateMatches,
                onCreateNew: {
                    Task { await createSurgeryEvenWithDuplicate() }
                },
                onSelect: { match in
                    Task { await claimAndUse(match) }
                }
            )
        }
    }

    private var formContent: some View {
        Form {
            Section {
                DateOnlyPickerSheet(
                    isoDate: $date,
                    title: "Data da Cirurgia",
                    placeholder: "Selecionar",
                    minDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? .distantPast,
                    maxDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? .distantFuture
                )
                EditRow(label: "Convênio", value: $insuranceName)
                    .focused($focusedField, equals: .insuranceName)
                EditRow(label: "Nº Convênio", value: $insuranceNumber)
                    .focused($focusedField, equals: .insuranceNumber)
                EditRow(label: "Cirurgião principal", value: $mainSurgeon)
                    .focused($focusedField, equals: .mainSurgeon)
                EditRow(label: "Cirurgiões auxiliares", value: $auxiliarySurgeonsText)
                EditRow(label: "Hospital", value: $hospital)
                    .focused($focusedField, equals: .hospital)
                EditRow(label: "Peso (kg)", value: $weight)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .weight)
                EditRow(label: "Procedimento proposto", value: $proposedProcedure)
                    .focused($focusedField, equals: .proposedProcedure)
                EditRow(label: "Procedimento completo", value: $completeProcedure)
                    .focused($focusedField, equals: .completeProcedure)

                HStack {
                    Text("Tipo")
                        .fontWeight(.bold)
                    Spacer()
                    Picker("Tipo", selection: $type) {
                        ForEach(SurgeryType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }
            } header: {
                let title = existing == nil ? "Nova Cirurgia" : "Editar Cirurgia"
                Text(title)
            }

            Section {
                Button {
                    showCbhpmSheet = true
                } label: {
                    HStack {
                        Text("CBHPM")
                        Spacer()
                        Text(cbhpmSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if insuranceName.lowercased() == "particular" && canEditFinancial {
                    EditRow(label: "Valor anestesia", value: $valueAnesthesia)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .valueAnesthesia)
                }
            } header: {
                Text("Informações adicionais")
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button(action: {
                Task { await submit() }
            }) {
                let title = existing == nil ? "Criar" : "Salvar"
                Text(title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
            }
            .listRowBackground(Color.blue)
            .disabled(isLoading || !isValid)
        }
    }

    private var standaloneBody: some View {
        NavigationView {
            formContent
                .navigationTitle(existing == nil ? "Nova Cirurgia" : "Editar Cirurgia")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar", systemImage: "checkmark") {
                            Task { await submit() }
                        }
                        .disabled(isLoading || !isValid)
                    }
                }
                .onAppear { loadIfNeeded() }
        }
    }

    private var wizardBody: some View {
        formContent
    }

    private var cbhpmSheetContent: some View {
        Form {
            if !cbhpmCatalog.isEmpty {
                Section {
                    NavigationLink {
                        SurgeryCbhpmSearchView(items: cbhpmCatalog) { selected in
                            appendSelectedFromCatalog(selected)
                        }
                    } label: {
                        Label("Buscar na Tabela CBHPM", systemImage: "magnifyingglass")
                    }
                } header: {
                    Text("Catálogo de Códigos")
                }
            }
            
            Section {
                EditRow(label: "Código", value: $cbhpmCode)
                EditRow(label: "Procedimento", value: $cbhpmProcedure)
                EditRow(label: "Porte", value: $cbhpmPort)

                Button("Adicionar ao resumo") {
                    addManualCbhpmFromSheet()
                }
            } header: {
                Text("Adicionar Não Padronizados")
            }

            Section {
                if cbhpms.isEmpty {
                    Text("Nenhum item adicionado")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(cbhpms.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.code)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Button("Remover", role: .destructive) {
                                    cbhpms.remove(at: index)
                                }
                                .font(.caption)
                            }
                            Text(item.procedure)
                                .font(.subheadline)
                            Text("Porte \(item.port)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Códigos CBHPM adicionados")
            }

            if let cbhpmSheetError {
                Section {
                    Text(cbhpmSheetError)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("CBHPM")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar", systemImage: "xmark") {
                    showCbhpmSheet = false
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("OK", systemImage: "checkmark") {
                    cbhpmSheetError = nil
                    showCbhpmSheet = false
                }
            }
        }
    }

    private var isValid: Bool {
        let trimmedDate = DateFormatterHelper.normalizeISODateString(date)
        guard !trimmedDate.isEmpty else { return false }
        guard !insuranceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !insuranceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !mainSurgeon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !hospital.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !proposedProcedure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return Double(weight.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private var cbhpmSummary: String {
        cbhpms.isEmpty ? "Opcional" : "\(cbhpms.count) item(ns)"
    }

    private func loadIfNeeded() {
        guard let existing else { return }
        date = DateFormatterHelper.normalizeISODateString(existing.date)
        insuranceName = existing.insuranceName
        insuranceNumber = existing.insuranceNumber
        mainSurgeon = existing.mainSurgeon
        auxiliarySurgeonsText = existing.auxiliarySurgeons?.joined(separator: ", ") ?? ""
        hospital = existing.hospital
        weight = String(existing.weight)
        proposedProcedure = existing.proposedProcedure
        completeProcedure = existing.completeProcedure ?? ""
        type = SurgeryType(rawValue: existing.type) ?? .insurance
        valueAnesthesia = existing.financial?.valueAnesthesia ?? ""

        cbhpms = existing.cbhpms.map { SurgeryCbhpmInput(code: $0.code, procedure: $0.procedure, port: $0.port) }
    }

    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedDate = DateFormatterHelper.normalizeISODateString(date)
        let trimmedInsuranceName = insuranceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInsuranceNumber = insuranceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMainSurgeon = mainSurgeon.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHospital = hospital.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProposed = proposedProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedComplete = completeProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let auxTrimmed = auxiliarySurgeonsText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDate.isEmpty else {
            errorMessage = "Data obrigatória"
            return
        }
        guard !trimmedInsuranceName.isEmpty else {
            errorMessage = "Convênio obrigatório"
            return
        }
        guard !trimmedInsuranceNumber.isEmpty else {
            errorMessage = "Número do convênio obrigatório"
            return
        }
        guard !trimmedMainSurgeon.isEmpty else {
            errorMessage = "Cirurgião principal obrigatório"
            return
        }
        guard !trimmedHospital.isEmpty else {
            errorMessage = "Hospital obrigatório"
            return
        }
        guard !trimmedProposed.isEmpty else {
            errorMessage = "Procedimento proposto obrigatório"
            return
        }

        let weightValue = Double(weight.replacingOccurrences(of: ",", with: "."))
        guard let weightValue else {
            errorMessage = "Peso inválido"
            return
        }

        let auxArray: [String]? = auxTrimmed.isEmpty
            ? nil
            : auxTrimmed
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

        let cbhpmsInput = buildCbhpmsPayload()
        if errorMessage != nil { return }

        let valueAnesthesiaDouble: Double? = {
            let trimmed = valueAnesthesia.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return Double(trimmed.replacingOccurrences(of: ",", with: "."))
        }()

        do {
            if let existing {
                let updated = try await surgerySession.update(
                    surgeryId: existing.id,
                    input: UpdateSurgeryInput(
                        date: trimmedDate,
                        insurance_name: trimmedInsuranceName,
                        insurance_number: trimmedInsuranceNumber,
                        main_surgeon: trimmedMainSurgeon,
                        auxiliary_surgeons: auxArray,
                        hospital: trimmedHospital,
                        weight: weightValue,
                        proposed_procedure: trimmedProposed,
                        complete_procedure: trimmedComplete.isEmpty ? nil : trimmedComplete,
                        type: type.rawValue,
                        status: nil,
                        cbhpms: cbhpmsInput,
                        financial: canEditFinancial
                            ? SurgeryFinancialInput(value_anesthesia: valueAnesthesiaDouble)
                            : nil
                    )
                )
                onComplete?(updated)
            } else {
                let matches = try await surgerySession.precheck(
                    input: PrecheckSurgeryInput(
                        patient_id: patientId,
                        date: trimmedDate,
                        type: type.rawValue,
                        insurance_name: trimmedInsuranceName,
                        hospital: trimmedHospital,
                        main_surgeon: trimmedMainSurgeon,
                        proposed_procedure: trimmedProposed
                    )
                )

                if !matches.isEmpty {
                    duplicateMatches = matches
                    showDuplicateSheet = true
                    return
                }

                let created = try await surgerySession.create(
                    CreateSurgeryInput(
                        patient_id: patientId,
                        date: trimmedDate,
                        insurance_name: trimmedInsuranceName,
                        insurance_number: trimmedInsuranceNumber,
                        main_surgeon: trimmedMainSurgeon,
                        auxiliary_surgeons: auxArray,
                        hospital: trimmedHospital,
                        weight: weightValue,
                        proposed_procedure: trimmedProposed,
                        complete_procedure: trimmedComplete.isEmpty ? nil : trimmedComplete,
                        type: type.rawValue,
                        cbhpms: cbhpmsInput,
                        financial: SurgeryFinancialInput(value_anesthesia: valueAnesthesiaDouble)
                    )
                )
                onComplete?(created)
            }

            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func createSurgeryEvenWithDuplicate() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedDate = DateFormatterHelper.normalizeISODateString(date)
        let trimmedInsuranceName = insuranceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInsuranceNumber = insuranceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMainSurgeon = mainSurgeon.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHospital = hospital.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProposed = proposedProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedComplete = completeProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let auxTrimmed = auxiliarySurgeonsText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDate.isEmpty else {
            errorMessage = "Data obrigatória"
            return
        }
        guard !trimmedInsuranceName.isEmpty else {
            errorMessage = "Convênio obrigatório"
            return
        }
        guard !trimmedInsuranceNumber.isEmpty else {
            errorMessage = "Número do convênio obrigatório"
            return
        }
        guard !trimmedMainSurgeon.isEmpty else {
            errorMessage = "Cirurgião principal obrigatório"
            return
        }
        guard !trimmedHospital.isEmpty else {
            errorMessage = "Hospital obrigatório"
            return
        }
        guard !trimmedProposed.isEmpty else {
            errorMessage = "Procedimento proposto obrigatório"
            return
        }

        let weightValue = Double(weight.replacingOccurrences(of: ",", with: "."))
        guard let weightValue else {
            errorMessage = "Peso inválido"
            return
        }

        let auxArray: [String]? = auxTrimmed.isEmpty
            ? nil
            : auxTrimmed
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

        let cbhpmsInput = buildCbhpmsPayload()
        if errorMessage != nil { return }

        let valueAnesthesiaDouble: Double? = {
            let trimmed = valueAnesthesia.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return Double(trimmed.replacingOccurrences(of: ",", with: "."))
        }()

        do {
            let created = try await surgerySession.create(
                CreateSurgeryInput(
                    patient_id: patientId,
                    date: trimmedDate,
                    insurance_name: trimmedInsuranceName,
                    insurance_number: trimmedInsuranceNumber,
                    main_surgeon: trimmedMainSurgeon,
                    auxiliary_surgeons: auxArray,
                    hospital: trimmedHospital,
                    weight: weightValue,
                    proposed_procedure: trimmedProposed,
                    complete_procedure: trimmedComplete.isEmpty ? nil : trimmedComplete,
                    type: type.rawValue,
                    cbhpms: cbhpmsInput,
                    financial: SurgeryFinancialInput(value_anesthesia: valueAnesthesiaDouble)
                )
            )
            onComplete?(created)
            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func claimAndUse(_ match: PrecheckSurgeryMatchDTO) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await surgerySession.claim(surgeryId: match.surgeryId)
            let surgery = try await surgerySession.getById(match.surgeryId)
            onComplete?(surgery)
            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private var canEditFinancial: Bool {
        guard let existing else { return true }
        return existing.resolvedPermission == .owner
    }

    private enum ManualCbhpmDraft {
        case empty
        case valid(SurgeryCbhpmInput)
        case incomplete
    }

    private func buildCbhpmsPayload() -> [SurgeryCbhpmInput]? {
        var result: [SurgeryCbhpmInput] = []
        var keys = Set<String>()

        for item in cbhpms {
            let normalized = normalizedCbhpm(item.code, item.procedure, item.port)
            guard let normalized else { continue }
            let key = cbhpmKey(normalized)
            if keys.insert(key).inserted {
                result.append(normalized)
            }
        }

        switch manualDraftState() {
        case .empty:
            break
        case let .valid(item):
            let key = cbhpmKey(item)
            if keys.insert(key).inserted {
                result.append(item)
            }
        case .incomplete:
            errorMessage = "CBHPM incompleto"
            return nil
        }

        return result.isEmpty ? nil : result
    }

    private func manualDraftState() -> ManualCbhpmDraft {
        let code = cbhpmCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let procedure = cbhpmProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = cbhpmPort.trimmingCharacters(in: .whitespacesAndNewlines)

        if code.isEmpty && procedure.isEmpty && port.isEmpty {
            return .empty
        }
        guard let normalized = normalizedCbhpm(code, procedure, port) else {
            return .incomplete
        }
        return .valid(normalized)
    }

    private func normalizedCbhpm(_ code: String, _ procedure: String, _ port: String) -> SurgeryCbhpmInput? {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedProcedure = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPort = port.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCode.isEmpty, !normalizedProcedure.isEmpty, !normalizedPort.isEmpty else {
            return nil
        }
        return SurgeryCbhpmInput(code: normalizedCode, procedure: normalizedProcedure, port: normalizedPort)
    }

    private func cbhpmKey(_ item: SurgeryCbhpmInput) -> String {
        "\(item.code.lowercased())|\(item.procedure.lowercased())|\(item.port.lowercased())"
    }

    private func appendSelectedFromCatalog(_ selected: [SelectedCbhpmItem]) {
        cbhpmSheetError = nil

        var existingKeys = Set(cbhpms.map(cbhpmKey))
        for selectedItem in selected {
            guard let normalized = normalizedCbhpm(selectedItem.code, selectedItem.procedure, selectedItem.port) else { continue }
            let key = cbhpmKey(normalized)
            if existingKeys.insert(key).inserted {
                cbhpms.append(normalized)
            }
        }
    }

    private func addManualCbhpmFromSheet() {
        cbhpmSheetError = nil

        guard let item = normalizedCbhpm(cbhpmCode, cbhpmProcedure, cbhpmPort) else {
            cbhpmSheetError = "Preencha código, procedimento e porte para adicionar."
            return
        }

        let key = cbhpmKey(item)
        guard !cbhpms.map(cbhpmKey).contains(key) else {
            cbhpmSheetError = "Esse CBHPM já foi adicionado."
            return
        }

        cbhpms.append(item)
        cbhpmCode = ""
        cbhpmProcedure = ""
        cbhpmPort = ""
    }
}
