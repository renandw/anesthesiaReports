import SwiftUI

struct FinancialDetailView: View {
    @EnvironmentObject private var authSession: AuthSession

    let surgeryId: String
    let permission: SurgeryPermission

    @State private var financial: SurgeryFinancialDetailsDTO?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEdit = false

    var body: some View {
        Form {
            if isLoading {
                Section { ProgressView() }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                if let financial {
                    financialMoneyRow("Valor anestesia", value: financial.valueAnesthesia, color: .blue)
                    financialMoneyRow("Valor pré-anestesia", value: financial.valuePreAnesthesia, color: .blue)
                    financialMoneyRow("Valor Faturado", value: financial.baseValue, color: .blue)
                    financialMoneyRow("Impostos", value: financial.taxedValue, color: .red)
                    financialMoneyRow("Valor Líquido", value: financial.finalSurgeryValue, color: .green)
                    HStack {
                        Text("Pago?")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(financial.paid ? "Sim" : "Não")
                            .fontWeight(.bold)
                            .foregroundStyle(financial.paid ? .green : .orange)
                    }
                    financialMoneyRow("Valor Pago", value: financial.valuePartialPayment)
                    financialMoneyRow("Pendente", value: financial.remainingValue, color: .orange)
                    
                    
                    if let paymentDateString = financial.paymentDate, !paymentDateString.isEmpty {
                        DetailRow(
                            label: "Data pagamento",
                            value: DateFormatterHelper.formatISODateString(paymentDateString, dateStyle: .medium)
                        )
                    }
                    if let notes = financial.notes, !notes.isEmpty {
                        DetailRow(label: "Observações", value: notes)
                    }
                } else {
                    Text("Sem dados financeiros")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Financeiro")
            }
        }
        .navigationTitle("Financeiro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEditFinancial(permission) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(financial == nil ? "Adicionar" : "Editar") {
                        showEdit = true
                    }
                }
            }
        }
        .task { await loadFinancial() }
        .refreshable { await loadFinancial() }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                FinancialFormView(
                    mode: .standalone,
                    surgeryId: surgeryId,
                    initialFinancial: financial,
                    onComplete: { updated in
                        financial = updated
                    }
                )
                .environmentObject(authSession)
            }
        }
        .onChange(of: showEdit) { oldValue, newValue in
            if oldValue && !newValue {
                Task { await loadFinancial() }
            }
        }
    }

    private func loadFinancial() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let service = FinancialService(authSession: authSession)
            financial = try await service.get(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if case .notFound = authError {
                financial = nil
                return
            }
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func canEditFinancial(_ permission: SurgeryPermission) -> Bool {
        permission == .full_editor || permission == .owner
    }

    @ViewBuilder
    private func financialMoneyRow(_ label: String, value: String?, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatMoney(value))
                .fontWeight(.bold)
                .foregroundStyle(color ?? .primary)
        }
    }

    private func formatMoney(_ raw: String?) -> String {
        guard
            let raw,
            !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let number = Double(raw)
        else {
            return "-"
        }
        return number.formatted(.currency(code: "BRL"))
    }
}
