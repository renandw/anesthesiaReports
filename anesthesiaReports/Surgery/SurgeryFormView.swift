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
    @State private var lastInsuranceNameBeforeSus = ""
    @State private var insuranceNumber = ""
    @State private var mainSurgeon = ""
    @State private var auxiliarySurgeons: [String] = []
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
        .onChange(of: focusedField) { previous, current in
            if previous == .some(.mainSurgeon), current != .some(.mainSurgeon) {
                mainSurgeon = NameFormatHelper.normalizeTitleCase(mainSurgeon)
            }
            if previous == .some(.hospital), current != .some(.hospital) {
                hospital = NameFormatHelper.normalizeTitleCase(hospital)
            }
        }
        .onChange(of: auxiliarySurgeons) { _, newValue in
            let normalized = newValue
                .map { NameFormatHelper.normalizeTitleCase($0) }
                .filter { !$0.isEmpty }
            if normalized != newValue {
                auxiliarySurgeons = normalized
            }
        }
    }

    private var formContent: some View {
        Form {
            Section {
                HStack {
                    Text("Tipo")
                        .font(.subheadline)
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
                .onChange(of: type) { oldValue, newValue in
                    if newValue != .insurance {
                        let currentInsurance = insuranceName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !currentInsurance.isEmpty, currentInsurance.lowercased() != "sus" {
                            lastInsuranceNameBeforeSus = currentInsurance
                        }
                        insuranceName = "SUS"
                    } else if insuranceName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "sus" {
                        insuranceName = lastInsuranceNameBeforeSus
                    }
                }
                DateOnlyPickerSheet(
                    isoDate: $date,
                    title: "Data da Cirurgia",
                    placeholder: "Selecionar",
                    minDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? .distantPast,
                    maxDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? .distantFuture
                )
                if type == .insurance {
                    let insuranceList = ["Bradesco", "Unimed", "Particular", "Astir", "Amil", "Sulamerica", "Assefaz",
                                        "Capesesp", "Cassi", "Funsa", "Fusex", "Geap",
                                        "Life", "Saúde Caixa", "Innova", "Ipam" ]
                    EditRowWithOptions(
                        label: "Convênio",
                        value: $insuranceName,
                        options: insuranceList,
                    )
                    .focused($focusedField, equals: .insuranceName)
                } else {
                    HStack {
                        Text("SUS")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(insuranceName)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                EditRow(
                    label: type == .insurance ? "Carteirinha" : "Prontuário",
                    value: $insuranceNumber
                )
                .focused($focusedField, equals: .insuranceNumber)
            } header: {
                HStack{
                    Text("Dados Básicos")
                }
            }
            Section {
                let privateHospitals = [
                    "Hospital 9 de Julho",
                    "Hospital Central",
                    "Hospital das Clínicas",
                    "Hospital Prontocordis",
                    "Hospital Unimed",
                    "Instituto do Coração",
                    "Igeron",
                    "Hospital Samar"
                ]
                let publicHospitals = [
                    "Hospital de Base - Centro Cirúrgico",
                    "Hospital de Base - Centro Diagnóstico",
                    "Hospital de Base - Centro Obstétrico",
                    "Hospital de Base - UNACON",
                    "Hospital de Retaguarda - Centro Cirúrgico",
                    "Hospital João Paulo II - Centro Cirúrgico"
                ]
                if type == .insurance {
                    EditRowWithOptions(label: "Hospital", value: $hospital, options: privateHospitals )
                        .focused($focusedField, equals: .hospital)
                } else {
                    EditRowWithOptions(label: "Hospital", value: $hospital, options: publicHospitals )
                        .focused($focusedField, equals: .hospital)
                }
                EditRow(label: "Peso (kg)", value: $weight)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .weight)
                EditRow(label: "Procedimento proposto", value: $proposedProcedure)
                    .focused($focusedField, equals: .proposedProcedure)
                EditRow(label: "Procedimento completo", value: $completeProcedure)
                    .focused($focusedField, equals: .completeProcedure)
            } header : {
                HStack {
                    Text("Dados da Cirurgia")
                }
            }
            Section {
                EditRow(label: "Cirurgião principal", value: $mainSurgeon)
                    .focused($focusedField, equals: .mainSurgeon)
                EditRowArray(label: "Auxiliares", values: $auxiliarySurgeons)
            } header: {
                HStack {
                    Text("Equipe Cirúrgica")
                }
            }

            Section {
                Button {
                    showCbhpmSheet = true
                } label: {
                    HStack {
                        Text("Códigos CBHPM")
                        Spacer()
                        Text(cbhpmSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
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
        switch cbhpms.count {
        case 0: return "Adicionar"
        case 1: return "1 item"
        default: return "\(cbhpms.count) itens"
        }
    }

    private func loadIfNeeded() {
        guard let existing else { return }
        date = DateFormatterHelper.normalizeISODateString(existing.date)
        insuranceName = existing.insuranceName
        if existing.insuranceName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "sus" {
            lastInsuranceNameBeforeSus = existing.insuranceName
        }
        insuranceNumber = existing.insuranceNumber
        mainSurgeon = existing.mainSurgeon
        auxiliarySurgeons = existing.auxiliarySurgeons ?? []
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
        let trimmedMainSurgeon = NameFormatHelper.normalizeTitleCase(mainSurgeon)
        let trimmedHospital = NameFormatHelper.normalizeTitleCase(hospital)
        let trimmedProposed = proposedProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedComplete = completeProcedure.trimmingCharacters(in: .whitespacesAndNewlines)

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

        let auxArray = normalizedAuxiliarySurgeons()

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
        let trimmedMainSurgeon = NameFormatHelper.normalizeTitleCase(mainSurgeon)
        let trimmedHospital = NameFormatHelper.normalizeTitleCase(hospital)
        let trimmedProposed = proposedProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedComplete = completeProcedure.trimmingCharacters(in: .whitespacesAndNewlines)

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

        let auxArray = normalizedAuxiliarySurgeons()

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

    private func normalizedAuxiliarySurgeons() -> [String]? {
        let normalized = auxiliarySurgeons
            .map { NameFormatHelper.normalizeTitleCase($0) }
            .filter { !$0.isEmpty }
        return normalized.isEmpty ? nil : normalized
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
