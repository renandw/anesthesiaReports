import SwiftUI

struct NewSRPAWizardView: View {
    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var srpaSession: SRPASession
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 1
    @State private var patient: PatientDTO?
    @State private var surgery: SurgeryDTO?
    @State private var srpa: SurgerySRPADetailsDTO?
    @State private var existingSRPA: SurgerySRPADetailsDTO?
    @State private var isCheckingExisting = false
    @State private var hasCheckedExisting = false
    @State private var errorMessage: String?

    let onFinish: ((SurgeryDTO, SurgerySRPADetailsDTO) -> Void)?

    init(onFinish: ((SurgeryDTO, SurgerySRPADetailsDTO) -> Void)? = nil) {
        self.onFinish = onFinish
    }

    var body: some View {
        var stepTitle: String {
            switch step {
            case 1: return "Identificação do Paciente"
            case 2: return "Dados da Cirurgia"
            default: return "Início do SRPA"
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
                    await checkExistingSRPA()
                }
            }
        }
    }
}

private extension NewSRPAWizardView {
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
                } else if let existingSRPA {
                    VStack(spacing: 16) {
                        Text("SRPA já existe para esta cirurgia.")
                            .font(.headline)
                        Button("Abrir detalhes") {
                            onFinish?(surgery, existingSRPA)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    SRPAFormView(
                        mode: .wizard,
                        surgeryId: surgery.id,
                        initialSRPA: nil,
                        onComplete: { created in
                            srpa = created
                            onFinish?(surgery, created)
                            dismiss()
                        }
                    )
                    .environmentObject(srpaSession)
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
                srpa = nil
                existingSRPA = nil
                hasCheckedExisting = false
                step = 2
            } else if step == 2 {
                surgery = nil
                srpa = nil
                existingSRPA = nil
                hasCheckedExisting = false
                step = 1
            }
        }
    }

    func checkExistingSRPA() async {
        guard let surgery else { return }
        hasCheckedExisting = true
        isCheckingExisting = true
        defer { isCheckingExisting = false }
        do {
            existingSRPA = try await srpaSession.getBySurgery(surgeryId: surgery.id)
        } catch let authError as AuthError {
            if case .notFound = authError {
                existingSRPA = nil
            } else {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }
}

#Preview {
    NewSRPAWizardView()
        .environmentObject(PatientSession(authSession: AuthSession(), api: PatientAPI()))
        .environmentObject(SurgerySession(authSession: AuthSession(), api: SurgeryAPI()))
        .environmentObject(SRPASession(authSession: AuthSession(), api: SRPAAPI()))
}
