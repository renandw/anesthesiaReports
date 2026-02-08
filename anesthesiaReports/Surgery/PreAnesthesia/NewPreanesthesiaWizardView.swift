import SwiftUI

struct NewPreanesthesiaWizardView: View {
    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var preanesthesiaSession: PreanesthesiaSession
    @EnvironmentObject private var sharedPreSession: SharedPreAnesthesiaSession
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 1
    @State private var patient: PatientDTO?
    @State private var surgery: SurgeryDTO?
    @State private var preanesthesia: SurgeryPreanesthesiaDetailsDTO?
    @State private var existingPreanesthesia: SurgeryPreanesthesiaDetailsDTO?
    @State private var isCheckingExisting = false
    @State private var hasCheckedExisting = false
    @State private var errorMessage: String?

    let onFinish: ((SurgeryDTO, SurgeryPreanesthesiaDetailsDTO) -> Void)?

    init(onFinish: ((SurgeryDTO, SurgeryPreanesthesiaDetailsDTO) -> Void)? = nil) {
        self.onFinish = onFinish
    }

    var body: some View {
        var stepTitle: String {
            switch step {
            case 1: return "Identificação do Paciente"
            case 2: return "Dados da Cirurgia"
            default: return "Avaliação Pré-Anestésica"
            }
        }

        NavigationStack {
            VStack(spacing: 0) {
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
                    await checkExistingPreanesthesia()
                }
            }
        }
    }
}

private extension NewPreanesthesiaWizardView {
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
                } else if let existingPreanesthesia {
                    VStack(spacing: 16) {
                        Text("Pré‑anestesia já existe para esta cirurgia.")
                            .font(.headline)
                        Button("Abrir detalhes") {
                            onFinish?(surgery, existingPreanesthesia)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PreanesthesiaFormView(
                        surgeryId: surgery.id,
                        initialPreanesthesia: nil,
                        mode: .wizard,
                        onSaved: { created in
                            preanesthesia = created
                            onFinish?(surgery, created)
                            dismiss()
                        }
                    )
                    .environmentObject(preanesthesiaSession)
                    .environmentObject(sharedPreSession)
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
                preanesthesia = nil
                existingPreanesthesia = nil
                hasCheckedExisting = false
                step = 2
            } else if step == 2 {
                surgery = nil
                preanesthesia = nil
                existingPreanesthesia = nil
                hasCheckedExisting = false
                step = 1
            }
        }
    }

    func checkExistingPreanesthesia() async {
        guard let surgery else { return }
        hasCheckedExisting = true
        isCheckingExisting = true
        defer { isCheckingExisting = false }
        do {
            existingPreanesthesia = try await preanesthesiaSession.getBySurgery(surgeryId: surgery.id)
        } catch let authError as AuthError {
            if case .notFound = authError {
                existingPreanesthesia = nil
            } else {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }
}

#Preview {
    NewPreanesthesiaWizardView()
        .environmentObject(PatientSession(authSession: AuthSession(), api: PatientAPI()))
        .environmentObject(SurgerySession(authSession: AuthSession(), api: SurgeryAPI()))
        .environmentObject(PreanesthesiaSession(authSession: AuthSession(), api: PreanesthesiaAPI()))
        .environmentObject(SharedPreAnesthesiaSession(authSession: AuthSession()))
}
