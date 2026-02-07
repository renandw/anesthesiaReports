import SwiftUI

struct NewAnesthesiaWizardView: View {
    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var anesthesiaSession: AnesthesiaSession
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 1
    @State private var patient: PatientDTO?
    @State private var surgery: SurgeryDTO?
    @State private var anesthesia: SurgeryAnesthesiaDetailsDTO?
    @State private var existingAnesthesia: SurgeryAnesthesiaDetailsDTO?
    @State private var isCheckingExisting = false
    @State private var hasCheckedExisting = false
    @State private var errorMessage: String?
    let onFinish: ((SurgeryDTO, SurgeryAnesthesiaDetailsDTO) -> Void)?

    init(onFinish: ((SurgeryDTO, SurgeryAnesthesiaDetailsDTO) -> Void)? = nil) {
        self.onFinish = onFinish
    }

    var body: some View {
        var stepTitle: String {
            switch step {
            case 1: return "Identificação do Paciente"
            case 2: return "Dados da Cirurgia"
            default: return "Início da Anestesia"
            }
        }
        
        NavigationStack {
            VStack(spacing: 0) {
                header

                Divider()

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark") { dismiss() }
                }
            }
            .task(id: step) {
                if step == 3, !hasCheckedExisting {
                    await checkExistingAnesthesia()
                }
            }
        }
    }
}

private extension NewAnesthesiaWizardView {
    var header: some View {
        VStack(spacing: 8) {
            HStack {
                if step > 1 {
                    Button("Voltar") {
                        goBack()
                    }
                } else {
                    Spacer().frame(width: 56)
                }
                Spacer()
                Text("Etapa \(step) de 3")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Spacer().frame(width: 56)
            }
            .padding(.horizontal, 16)

            HStack {
                Text(stepTitle)
                    .font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    var stepTitle: String {
        switch step {
        case 1: return "Paciente"
        case 2: return "Cirurgia"
        default: return "Anestesia"
        }
    }

    @ViewBuilder
    var content: some View {
        switch step {
        case 1:
            PatientFormView(
                mode: .wizard,
                existing: nil,
                onComplete: { patient in
                    self.patient = patient
                    advance(to: 2)
                }
            )
            .environmentObject(patientSession)

        case 2:
            if let patient {
                SurgeryFormView(
                    mode: .wizard,
                    patientId: patient.id,
                    existing: nil,
                    onComplete: { surgery in
                        self.surgery = surgery
                        advance(to: 3)
                    }
                )
                .environmentObject(surgerySession)
            } else {
                missingDependency(text: "Selecione um paciente para continuar.")
            }

        default:
            if let surgery {
                if isCheckingExisting {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let existingAnesthesia {
                    VStack(spacing: 16) {
                        Text("Anestesia já existe para esta cirurgia.")
                            .font(.headline)
                        Button("Abrir detalhes") {
                            onFinish?(surgery, existingAnesthesia)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    AnesthesiaFormView(
                        mode: .wizard,
                        surgeryId: surgery.id,
                        initialAnesthesia: nil,
                        onComplete: { created in
                            anesthesia = created
                            onFinish?(surgery, created)
                            dismiss()
                        }
                    )
                    .environmentObject(anesthesiaSession)
                }
            } else {
                missingDependency(text: "Selecione uma cirurgia para continuar.")
            }
        }
    }

    func missingDependency(text: String) -> some View {
        VStack(spacing: 12) {
            Text(text)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func advance(to next: Int) {
        withAnimation {
            step = next
        }
    }

    func goBack() {
        withAnimation {
            if step == 3 {
                anesthesia = nil
                existingAnesthesia = nil
                hasCheckedExisting = false
                step = 2
            } else if step == 2 {
                surgery = nil
                anesthesia = nil
                existingAnesthesia = nil
                hasCheckedExisting = false
                step = 1
            }
        }
    }

    func checkExistingAnesthesia() async {
        guard let surgery else { return }
        hasCheckedExisting = true
        isCheckingExisting = true
        defer { isCheckingExisting = false }
        do {
            existingAnesthesia = try await anesthesiaSession.getBySurgery(surgeryId: surgery.id)
        } catch let authError as AuthError {
            if case .notFound = authError {
                existingAnesthesia = nil
            } else {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }
}

#Preview {
    NewAnesthesiaWizardView()
        .environmentObject(PatientSession(authSession: AuthSession(), api: PatientAPI()))
        .environmentObject(SurgerySession(authSession: AuthSession(), api: SurgeryAPI()))
        .environmentObject(AnesthesiaSession(authSession: AuthSession(), api: AnesthesiaAPI()))
}
