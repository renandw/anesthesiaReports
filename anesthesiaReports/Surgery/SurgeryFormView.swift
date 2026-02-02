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
    @State private var showCbhpmSheet = false

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
            Section {
                EditRow(label: "Código", value: $cbhpmCode)
                EditRow(label: "Procedimento", value: $cbhpmProcedure)
                EditRow(label: "Porte", value: $cbhpmPort)
            } header: {
                Text("CBHPM")
            }
        }
        .navigationTitle("CBHPM")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar", systemImage: "xmark") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("OK", systemImage: "checkmark") { dismiss() }
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
        let trimmedCode = cbhpmCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCode.isEmpty { return "Opcional" }
        return trimmedCode
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

        if let cbhpm = existing.cbhpm {
            cbhpmCode = cbhpm.code
            cbhpmProcedure = cbhpm.procedure
            cbhpmPort = cbhpm.port
        }
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

        let cbhpmInput: SurgeryCbhpmInput? = {
            let code = cbhpmCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let proc = cbhpmProcedure.trimmingCharacters(in: .whitespacesAndNewlines)
            let port = cbhpmPort.trimmingCharacters(in: .whitespacesAndNewlines)
            if code.isEmpty && proc.isEmpty && port.isEmpty {
                return nil
            }
            guard !code.isEmpty, !proc.isEmpty, !port.isEmpty else {
                errorMessage = "CBHPM incompleto"
                return nil
            }
            return SurgeryCbhpmInput(code: code, procedure: proc, port: port)
        }()

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
                        cbhpm: cbhpmInput,
                        financial: canEditFinancial
                            ? SurgeryFinancialInput(value_anesthesia: valueAnesthesiaDouble)
                            : nil
                    )
                )
                onComplete?(updated)
            } else {
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
                        cbhpm: cbhpmInput,
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

    private var canEditFinancial: Bool {
        guard let existing else { return true }
        return existing.resolvedPermission == .owner
    }
}
