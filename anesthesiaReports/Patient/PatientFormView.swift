import SwiftUI

struct PatientFormView: View {
    enum Mode {
        case standalone
        case wizard
    }

    @EnvironmentObject private var patientSession: PatientSession
    @Environment(\.dismiss) private var dismiss

    var mode: Mode = .standalone
    
    let existing: PatientDTO?
    let onComplete: ((PatientDTO) -> Void)?

    @State private var name = ""
    @State private var sex: Sex? = nil
    @State private var dateOfBirth = ""
    @State private var cns = ""

    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var duplicateMatches: [PrecheckMatchDTO] = []
    @State private var showDuplicateSheet = false
    
    var body: some View {
        Group {
            switch mode {
            case .standalone:
                standaloneBody
            case .wizard:
                wizardBody
            }
        }
        .sheet(isPresented: $showDuplicateSheet) {
            DuplicatePatientSheet(
                message: "Você está cadastrando um paciente que pode estar no banco de dados. Revise para evitar dados duplicados",
                foundPatients: duplicateMatches,
                onCreateNew: {
                    Task { await createPatient() }
                },
                onSelect: { match in
                    Task { await claimAndUse(match) }
                },
                onUpdate: { match in
                    Task { await claimAndUpdate(match) }
                }
            )
        }
    }
    
    private var formContent: some View {
        Form {
            Section {
                EditRow(label: "Nome", value: $name)
                EditRow(label: "Data de Nascimento", value: $dateOfBirth)
                HStack{
                    Text("Número SUS")
                        .fontWeight(.bold)
                    Spacer()
                    TextField("000 0000 0000 0000", text: Binding(
                        get: { formatCNS(cns) },
                        set: { newValue in
                            cns = newValue.filter {$0.isNumber}
                        }
                    ))
                    .keyboardType(.numberPad)
                    .onChange(of: cns) { _, newValue in
                        if newValue.count > 15 {
                            cns = String(newValue.prefix(15))
                        }
                    }
                    .multilineTextAlignment(.trailing)
                    if !cns.isEmpty {
                        Button {
                            cns = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Limpar Número SUS")
                    }
                }
                HStack{
                    Text("Sexo")
                        .fontWeight(.bold)
                    Spacer()
                    Picker("Sexo", selection: $sex) {
                        ForEach(Sex.allCases, id: \.self) { sex in
                            Text(sex == .male ? "Masculino" : "Feminino")
                                .tag(sex as Sex?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 230)
                }
            } header : {
                HStack {
                    let title = existing == nil ? "Novo Paciente" : "Editar Paciente"
                    Text(title)
                }
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
                .navigationTitle(existing == nil ? "Novo Paciente" : "Editar Paciente")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar", systemImage: "checkmark") {
                            Task {
                                await submit()
                            }
                        }
                        .disabled(isLoading || !isValid)
                    }
                }
                .onAppear {
                    loadIfNeeded()
                }
                // Futuramente .sheet -> DuplicatedSheetView
        }
    }
    private var wizardBody: some View {
        formContent
        // Futuramente .sheet -> DuplicatedSheetView
    }
    
    private var isValid: Bool {
        let digitCount = cns.filter { $0.isNumber }.count
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let dob = DateFormatterHelper.normalizeISODateString(dateOfBirth)
        return hasName && digitCount == 15 && !dob.isEmpty && sex != nil
    }
    
    private func formatCNS(_ cns: String) -> String {
        let numbers = cns.filter { $0.isNumber }.prefix(15)
        var result = ""
        
        for (index, char) in numbers.enumerated() {
            if index == 3 || index == 7 || index == 11 {
                result += " "
            }
            result.append(char)
        }
        
        return result
    }


    private func loadIfNeeded() {
        guard let existing else { return }
        name = existing.name
        sex = existing.sex
        dateOfBirth = DateFormatterHelper.normalizeISODateString(existing.dateOfBirth)
        cns = existing.cns
    }

    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDob = DateFormatterHelper.normalizeISODateString(dateOfBirth)
        let trimmedCns = cns.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Nome obrigatório"
            return
        }
        guard !trimmedDob.isEmpty else {
            errorMessage = "Data de nascimento obrigatória"
            return
        }
        guard let sex else {
            errorMessage = "Sexo obrigatório"
            return
        }
        guard !trimmedCns.isEmpty else {
            errorMessage = "CNS obrigatório"
            return
        }

        do {
            if let existing {
                let updated = try await patientSession.update(
                    patientId: existing.id,
                    input: UpdatePatientInput(
                        patient_name: trimmedName,
                        sex: sex,
                        date_of_birth: trimmedDob,
                        cns: trimmedCns
                    )
                )
                onComplete?(updated)
            } else {
                let input = CreatePatientInput(
                    patient_name: trimmedName,
                    sex: sex,
                    date_of_birth: trimmedDob,
                    cns: trimmedCns
                )
                let matches = try await patientSession.precheck(input: input)
                if matches.isEmpty {
                    let created = try await patientSession.create(input)
                    onComplete?(created)
                } else {
                    duplicateMatches = matches
                    showDuplicateSheet = true
                    return
                }
            }

            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
    }

    private func createPatient() async {
        guard let sex else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDob = DateFormatterHelper.normalizeISODateString(dateOfBirth)
        let trimmedCns = cns.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let created = try await patientSession.create(
                CreatePatientInput(
                    patient_name: trimmedName,
                    sex: sex,
                    date_of_birth: trimmedDob,
                    cns: trimmedCns
                )
            )
            onComplete?(created)
            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
    }

    private func claimAndUse(_ match: PrecheckMatchDTO) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await patientSession.claim(patientId: match.patientId)
            let patient = try await patientSession.getById(match.patientId)
            onComplete?(patient)
            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
    }

    private func claimAndUpdate(_ match: PrecheckMatchDTO) async {
        guard let sex else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDob = DateFormatterHelper.normalizeISODateString(dateOfBirth)
        let trimmedCns = cns.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await patientSession.claim(patientId: match.patientId)
            let updated = try await patientSession.update(
                patientId: match.patientId,
                input: UpdatePatientInput(
                    patient_name: trimmedName,
                    sex: sex,
                    date_of_birth: trimmedDob,
                    cns: trimmedCns
                )
            )
            onComplete?(updated)
            if mode == .standalone {
                dismiss()
            }
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
    }
}
