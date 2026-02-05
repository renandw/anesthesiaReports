import SwiftUI

struct FinancialFormView: View {
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

    private enum NumericField: Hashable {
        case valueAnesthesia
        case valuePreAnesthesia
        case glosaAnesthesiaValue
        case glosaPreanesthesiaValue
        case taxPercentage
        case taxedValue
        case valuePartialPayment
    }

    @EnvironmentObject private var authSession: AuthSession
    @Environment(\.dismiss) private var dismiss

    var mode: Mode = .standalone
    let surgeryId: String
    let initialFinancial: SurgeryFinancialDetailsDTO?
    let onComplete: ((SurgeryFinancialDetailsDTO?) -> Void)?

    @State private var valueAnesthesia = ""
    @State private var valuePreAnesthesia = ""
    @State private var glosaAnesthesiaValue = ""
    @State private var glosaPreanesthesiaValue = ""
    @State private var taxPercentage = ""
    @State private var taxedValue = ""
    @State private var valuePartialPayment = ""
    @State private var notes = ""
    @State private var paymentDate = ""
    @State private var paid = false
    @State private var glosaAnesthesia = false
    @State private var glosaPreanesthesia = false

    @State private var errorMessage: String?
    @State private var numericFieldErrors: [NumericField: String] = [:]
    @State private var isLoading = false
    @State private var submitVisualState: SubmitVisualState = .idle
    @State private var showDeleteConfirmation = false
    @State private var isSyncingTaxFields = false

    var body: some View {
        Group {
            switch mode {
            case .standalone:
                standaloneBody
            case .wizard:
                wizardBody
            }
        }
        .onAppear { loadIfNeeded() }
        .onChange(of: paid) { _, newValue in
            if !newValue {
                paymentDate = ""
                valuePartialPayment = ""
                numericFieldErrors.removeValue(forKey: .valuePartialPayment)
            }
        }
        .confirmationDialog(
            "Excluir financeiro?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                Task { await removeFinancial() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essa ação remove os dados financeiros desta cirurgia.")
        }
    }

    private var formContent: some View {
        Form {
            Section {
                EditRow(label: "Valor anestesia", value: numericBinding(.valueAnesthesia, text: $valueAnesthesia))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(.blue)
                if glosaAnesthesia {
                    EditRow(label: "Glosa anestesia", value: numericBinding(.glosaAnesthesiaValue, text: $glosaAnesthesiaValue))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.red)
                }
                EditRow(label: "Valor pré-anestesia", value: numericBinding(.valuePreAnesthesia, text: $valuePreAnesthesia))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(.blue)
                if glosaPreanesthesia {
                    EditRow(label: "Glosa pré-anestesia", value: numericBinding(.glosaPreanesthesiaValue, text: $glosaPreanesthesiaValue))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.red)
                }
                if paid {
                    EditRow(label: "Valor Recebido", value: numericBinding(.valuePartialPayment, text: $valuePartialPayment))
                        .keyboardType(.decimalPad)
                }
                EditRow(
                    label: "Imposto (%)",
                    value: numericBinding(.taxPercentage, text: $taxPercentage, max: 100)
                )
                    .keyboardType(.decimalPad)
                    .foregroundStyle(.red)
                EditRow(label: "Imposto (valor)", value: numericBinding(.taxedValue, text: $taxedValue))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(.red)
            } header: {
                Text("Valores")
            }

            Section {
                Toggle("Glosa Anestesia?", isOn: $glosaAnesthesia)
                Toggle("Glosa Pré-anestesia?", isOn: $glosaPreanesthesia)
                
            } header: {
                Text("Glosa e impostos")
            }

            if let inputErrorMessage = firstInputError {
                Text(inputErrorMessage)
                    .foregroundStyle(.red)
            }

            Section {
                HStack {
                    Text("Faturado")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(baseValueForTaxSync, format: .currency(code: "BRL"))
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                HStack {
                    Text("Valor Líquido")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text((Double(financialPreview.finalSurgeryValueText) ?? 0), format: .currency(code: "BRL"))
                        .foregroundStyle(.green)
                        .fontWeight(.bold)
                }
                HStack {
                    Text("Valor Pendente")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text((Double(financialPreview.remainingValueText) ?? 0), format: .currency(code: "BRL"))
                        .foregroundStyle(.orange)
                        .fontWeight(.bold)
                        
                }
            } header: {
                Text("Prévia de cálculo (local)")
            }

            Section {
                Toggle("Pago?", isOn: $paid)
                if paid {
                    DateOnlyPickerSheet(
                        isoDate: $paymentDate,
                        title: "Data de Pagamento",
                        placeholder: "Selecionar",
                        minDate: Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? .distantPast,
                        maxDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? .distantFuture
                    )
                }
                if let paidValidationMessage {
                    Text(paidValidationMessage)
                        .foregroundStyle(.red)
                }
                EditRow(label: "Observações", value: $notes)
            } header: {
                Text("Pagamento e observações")
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await submit() }
            } label: {
                Text(submitButtonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
            }
            .listRowBackground(submitButtonColor)
            .disabled(isSubmitting || paidValidationMessage != nil)

            if initialFinancial != nil {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Excluir financeiro")
                        .frame(maxWidth: .infinity)
                }
                .disabled(isSubmitting)
            }
        }
    }

    private var standaloneBody: some View {
        NavigationStack {
            formContent
                .navigationTitle("Financeiro")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar", systemImage: "checkmark") {
                            Task { await submit() }
                        }
                        .disabled(isSubmitting)
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

    private var submitButtonTitle: String {
        switch submitVisualState {
        case .idle:
            return "Salvar financeiro"
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

    private func loadIfNeeded() {
        guard let financial = initialFinancial else { return }
        valueAnesthesia = financial.valueAnesthesia ?? ""
        valuePreAnesthesia = financial.valuePreAnesthesia ?? ""
        glosaAnesthesiaValue = financial.glosaAnesthesiaValue ?? ""
        glosaPreanesthesiaValue = financial.glosaPreanesthesiaValue ?? ""
        taxPercentage = financial.taxPercentage ?? ""
        taxedValue = financial.taxedValue ?? ""
        valuePartialPayment = financial.valuePartialPayment ?? ""
        notes = financial.notes ?? ""
        paymentDate = financial.paymentDate ?? ""
        paid = financial.paid
        glosaAnesthesia = financial.glosaAnesthesia ?? false
        glosaPreanesthesia = financial.glosaPreanesthesia ?? false
    }

    private func submit() async {
        if isSubmitting { return }
        if let paidValidationMessage {
            await failSubmit(paidValidationMessage, authError: nil)
            return
        }
        if let inputErrorMessage = firstInputError {
            await failSubmit(inputErrorMessage, authError: nil)
            return
        }
        errorMessage = nil
        isLoading = true
        submitVisualState = .submitting
        defer { isLoading = false }

        do {
            let payload = try buildPayload()
            try validateBeforeSubmit(payload)

            let service = FinancialService(authSession: authSession)
            let updated = try await service.update(
                surgeryId: surgeryId,
                input: payload
            )

            onComplete?(updated)
            submitVisualState = .success
            try? await Task.sleep(nanoseconds: 700_000_000)
            submitVisualState = .idle
            if mode == .standalone { dismiss() }
        } catch let authError as AuthError {
            await failSubmit(authError.userMessage, authError: authError)
        } catch let validationError as FinancialValidationError {
            await failSubmit(validationError.message, authError: nil)
        } catch {
            await failSubmit("Erro de rede", authError: nil)
        }
    }

    private func removeFinancial() async {
        if isSubmitting { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let service = FinancialService(authSession: authSession)
            try await service.delete(surgeryId: surgeryId)
            onComplete?(nil)
            if mode == .standalone { dismiss() }
        } catch let authError as AuthError {
            await failSubmit(authError.userMessage, authError: authError)
        } catch {
            await failSubmit("Erro de rede", authError: nil)
        }
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

    private func decimalOrNil(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private var financialPreview: FinancialPreview {
        let valueAnesthesiaNumber = decimalOrNil(valueAnesthesia) ?? 0
        let valuePreAnesthesiaNumber = decimalOrNil(valuePreAnesthesia) ?? 0
        let glosaAnesthesiaNumber = decimalOrNil(glosaAnesthesiaValue) ?? 0
        let glosaPreanesthesiaNumber = decimalOrNil(glosaPreanesthesiaValue) ?? 0

        let baseValue = round2(
            max(0, valueAnesthesiaNumber - glosaAnesthesiaNumber) +
            max(0, valuePreAnesthesiaNumber - glosaPreanesthesiaNumber)
        )

        let hasTaxPercentageInput =
            !taxPercentage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTaxedValueInput =
            !taxedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        var taxPercentageValue = decimalOrNil(taxPercentage)
        var taxedValueNumber = decimalOrNil(taxedValue)

        if hasTaxPercentageInput {
            if let pct = taxPercentageValue {
                taxedValueNumber = round2((baseValue * pct) / 100)
            } else {
                taxPercentageValue = nil
                taxedValueNumber = nil
            }
        } else if hasTaxedValueInput {
            if let taxed = taxedValueNumber {
                taxPercentageValue = baseValue > 0 ? round2((taxed / baseValue) * 100) : 0
            } else {
                taxPercentageValue = nil
                taxedValueNumber = nil
            }
        } else if let pct = taxPercentageValue {
            taxedValueNumber = round2((baseValue * pct) / 100)
        } else if let taxed = taxedValueNumber {
            taxPercentageValue = baseValue > 0 ? round2((taxed / baseValue) * 100) : 0
        }

        let finalValue = round2(baseValue - (taxedValueNumber ?? 0))
        let normalizedPaidValue: Double = {
            guard paid else { return 0 }
            let raw = decimalOrNil(valuePartialPayment) ?? 0
            // Backend treats 0/empty as full payment when paid == true.
            if raw == 0 { return finalValue }
            return raw
        }()
        let remainingValue = round2(paid ? max(0, finalValue - normalizedPaidValue) : finalValue)

        return FinancialPreview(
            baseValueText: money(baseValue),
            finalSurgeryValueText: money(finalValue),
            remainingValueText: money(remainingValue)
        )
    }

    private func emptyToNil(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func parseDecimal(_ raw: String, fieldName: String) throws -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        guard let parsed = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else {
            throw FinancialValidationError(message: "\(fieldName) inválido")
        }
        return parsed
    }

    private func normalizeOptionalISODate(_ raw: String, fieldName: String) throws -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let normalized = DateFormatterHelper.normalizeISODateString(trimmed)
        if normalized.isEmpty {
            throw FinancialValidationError(message: "\(fieldName) inválida")
        }
        return normalized
    }

    private func buildPayload() throws -> UpdateSurgeryFinancialInput {
        let normalizedGlosaAnesthesia: Bool? = {
            let oldValue = initialFinancial?.glosaAnesthesia ?? false
            return glosaAnesthesia == oldValue ? nil : glosaAnesthesia
        }()
        let normalizedGlosaPreanesthesia: Bool? = {
            let oldValue = initialFinancial?.glosaPreanesthesia ?? false
            return glosaPreanesthesia == oldValue ? nil : glosaPreanesthesia
        }()

        return UpdateSurgeryFinancialInput(
            value_anesthesia: try parseDecimal(valueAnesthesia, fieldName: "Valor anestesia"),
            value_pre_anesthesia: try parseDecimal(valuePreAnesthesia, fieldName: "Valor pré-anestesia"),
            final_surgery_value: nil,
            value_partial_payment: paid
                ? try parseDecimal(valuePartialPayment, fieldName: "Valor recebido")
                : nil,
            glosa_anesthesia: normalizedGlosaAnesthesia,
            glosa_preanesthesia: normalizedGlosaPreanesthesia,
            glosa_anesthesia_value: try parseDecimal(glosaAnesthesiaValue, fieldName: "Glosa anestesia"),
            glosa_preanesthesia_value: try parseDecimal(glosaPreanesthesiaValue, fieldName: "Glosa pré-anestesia"),
            notes: emptyToNil(notes),
            paid: paid,
            payment_date: try normalizeOptionalISODate(paymentDate, fieldName: "Data de pagamento"),
            taxed_value: try parseDecimal(taxedValue, fieldName: "Imposto (valor)"),
            tax_percentage: try parseDecimal(taxPercentage, fieldName: "Imposto (%)")
        )
    }

    private func validateBeforeSubmit(_ payload: UpdateSurgeryFinancialInput) throws {
        if paid {
            let partialPaid = payload.value_partial_payment ?? 0
            let finalValue = Double(financialPreview.finalSurgeryValueText) ?? 0
            if partialPaid > finalValue {
                throw FinancialValidationError(message: "Valor recebido não pode ser maior que o valor final")
            }
        }

        let hasAnyValue =
            payload.value_anesthesia != nil ||
            payload.value_pre_anesthesia != nil ||
            payload.value_partial_payment != nil ||
            payload.glosa_anesthesia_value != nil ||
            payload.glosa_preanesthesia_value != nil ||
            payload.tax_percentage != nil ||
            payload.taxed_value != nil ||
            payload.payment_date != nil ||
            payload.notes != nil ||
            payload.paid != (initialFinancial?.paid ?? false) ||
            glosaAnesthesia != (initialFinancial?.glosaAnesthesia ?? false) ||
            glosaPreanesthesia != (initialFinancial?.glosaPreanesthesia ?? false)

        if !hasAnyValue {
            throw FinancialValidationError(message: "Preencha ao menos um campo")
        }
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }

    private func round2(_ value: Double) -> Double {
        ((value * 100).rounded()) / 100
    }

    private func money(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private var firstInputError: String? {
        numericFieldErrors.values.first
    }

    private func numericBinding(
        _ field: NumericField,
        text: Binding<String>,
        max: Double? = nil
    ) -> Binding<String> {
        Binding(
            get: { text.wrappedValue },
            set: { newValue in
                let sanitized = sanitizeDecimalInput(newValue)
                text.wrappedValue = sanitized
                validateNumericInput(field: field, value: sanitized, max: max)
                syncTaxFieldsIfNeeded(edited: field)
            }
        )
    }

    private func sanitizeDecimalInput(_ raw: String) -> String {
        var result = ""
        var usedSeparator = false

        for char in raw {
            if char.isNumber {
                result.append(char)
                continue
            }

            if (char == "." || char == ",") && !usedSeparator {
                result.append(char)
                usedSeparator = true
            }
        }

        return result
    }

    private func validateNumericInput(field: NumericField, value: String, max: Double?) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            numericFieldErrors.removeValue(forKey: field)
            return
        }

        if trimmed.hasSuffix(".") || trimmed.hasSuffix(",") {
            numericFieldErrors.removeValue(forKey: field)
            return
        }

        guard let parsed = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else {
            numericFieldErrors[field] = "Número inválido"
            return
        }

        if parsed < 0 {
            numericFieldErrors[field] = "Valor não pode ser negativo"
            return
        }

        if let max, parsed > max {
            numericFieldErrors[field] = "Valor deve ser <= \(Int(max))"
            return
        }

        numericFieldErrors.removeValue(forKey: field)
    }

    private func syncTaxFieldsIfNeeded(edited: NumericField) {
        guard !isSyncingTaxFields else { return }

        switch edited {
        case .taxPercentage:
            isSyncingTaxFields = true
            defer { isSyncingTaxFields = false }

            guard numericFieldErrors[.taxPercentage] == nil else { return }

            let trimmed = taxPercentage.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                taxedValue = ""
                numericFieldErrors.removeValue(forKey: .taxedValue)
                return
            }

            guard let pct = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else { return }
            let taxed = round2((baseValueForTaxSync * pct) / 100)
            taxedValue = formattedInputNumber(taxed)
            validateNumericInput(field: .taxedValue, value: taxedValue, max: nil)

        case .taxedValue:
            isSyncingTaxFields = true
            defer { isSyncingTaxFields = false }

            guard numericFieldErrors[.taxedValue] == nil else { return }

            let trimmed = taxedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                taxPercentage = ""
                numericFieldErrors.removeValue(forKey: .taxPercentage)
                return
            }

            guard let taxed = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else { return }
            let pct = baseValueForTaxSync > 0 ? round2((taxed / baseValueForTaxSync) * 100) : 0
            taxPercentage = formattedInputNumber(pct)
            validateNumericInput(field: .taxPercentage, value: taxPercentage, max: 100)

        default:
            break
        }
    }

    private var baseValueForTaxSync: Double {
        let valueAnesthesiaNumber = decimalOrNil(valueAnesthesia) ?? 0
        let valuePreAnesthesiaNumber = decimalOrNil(valuePreAnesthesia) ?? 0
        let glosaAnesthesiaNumber = decimalOrNil(glosaAnesthesiaValue) ?? 0
        let glosaPreanesthesiaNumber = decimalOrNil(glosaPreanesthesiaValue) ?? 0
        return round2(
            max(0, valueAnesthesiaNumber - glosaAnesthesiaNumber) +
            max(0, valuePreAnesthesiaNumber - glosaPreanesthesiaNumber)
        )
    }

    private func formattedInputNumber(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private var paidValidationMessage: String? {
        if paid && paymentDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Informe a data de pagamento quando o financeiro estiver pago"
        }
        return nil
    }
}

private struct FinancialValidationError: Error {
    let message: String
}

private struct FinancialPreview {
    let baseValueText: String
    let finalSurgeryValueText: String
    let remainingValueText: String
}

#if DEBUG
#Preview {
    FinancialFormView(
        mode: .standalone,
        surgeryId: UUID().uuidString,
        initialFinancial: nil,
        onComplete: { _ in }
    )
    .environmentObject(AuthSession())
}
#endif
