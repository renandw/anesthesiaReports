import SwiftUI

struct SRPAIdentificationView: View {
    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var srpaSession: SRPASession

    @Binding var patient: PatientDTO?
    @Binding var surgery: SurgeryDTO?
    @Binding var srpa: SurgerySRPADetailsDTO?

    @State private var showingPatientForm = false
    @State private var showingSurgeryForm = false
    @State private var showingSRPAForm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let patient {
                    DetailRow(label: "Paciente", value: patient.name)
                    DetailRow(label: "Idade", value: ageText(for: patient))
                }
                DetailRow(label: "Cirurgia", value: surgery?.proposedProcedure ?? "-")
                DetailRow(
                    label: "Início SRPA",
                    value: srpa?.startAt.map {
                        DateFormatterHelper.format($0, dateStyle: .medium, timeStyle: .short)
                    } ?? "-"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .preference(
                key: CustomTitleBarButtonPreferenceKey.self,
                value: CustomTitleBarButtonPreference(
                    id: "SRPAIdentificationView.topbar.buttons",
                    view: AnyView(titleBarButtons),
                    token: "SRPAIdentificationView.topbar.buttons.v1"
                )
            )
        }
        .sheet(isPresented: $showingPatientForm) {
            if let patient {
                PatientFormView(
                    mode: .standalone,
                    existing: patient,
                    onComplete: { updated in
                        self.patient = updated
                        Task { await reloadIfPossible() }
                    }
                )
                .environmentObject(patientSession)
            }
        }
        .sheet(isPresented: $showingSurgeryForm) {
            if let surgery {
                SurgeryFormView(
                    mode: .standalone,
                    patientId: surgery.patientId,
                    existing: surgery,
                    onComplete: { updated in
                        self.surgery = updated
                        Task { await reloadIfPossible() }
                    }
                )
                .environmentObject(surgerySession)
            }
        }
        .sheet(isPresented: $showingSRPAForm) {
            if let surgeryId = surgery?.id {
                SRPAFormView(
                    mode: .standalone,
                    surgeryId: surgeryId,
                    initialSRPA: srpa,
                    onComplete: { updated in
                        self.srpa = updated
                        Task { await reloadIfPossible() }
                    }
                )
                .environmentObject(srpaSession)
            }
        }
    }

    private var titleBarButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                showingPatientForm = true
            }) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .regular))
                    .frame(width: 20, height: 20)
            }
            .accessibilityLabel("Editar Paciente")
            .buttonStyle(.glass)
            .tint(.blue)
            .disabled(patient == nil)

            Button(action: {
                showingSurgeryForm = true
            }) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 16, weight: .regular))
                    .frame(width: 20, height: 20)
            }
            .accessibilityLabel("Editar Cirurgia")
            .buttonStyle(.glass)
            .tint(.green)
            .disabled(surgery == nil)

            Button(action: {
                showingSRPAForm = true
            }) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 16, weight: .regular))
                    .frame(width: 20, height: 20)
            }
            .accessibilityLabel("Editar SRPA")
            .buttonStyle(.glass)
            .tint(.purple)
            .disabled(surgery == nil)
        }
    }

    private func ageText(for patient: PatientDTO) -> String {
        guard let birthDate = DateFormatterHelper.parseISODate(patient.dateOfBirth) else {
            return "—"
        }
        let surgeryDate: Date = {
            if let iso = surgery?.date, let parsed = DateFormatterHelper.parseISODate(iso) { return parsed }
            return Date()
        }()
        return AgeContext.at(date: surgeryDate).ageLongString(from: birthDate)
    }

    @MainActor
    private func reloadIfPossible() async {
        guard let surgeryId = surgery?.id else { return }

        do {
            surgery = try await surgerySession.getById(surgeryId)
        } catch {
            // ignore refresh errors in detail context
        }

        if let surgery {
            do {
                patient = try await patientSession.getById(surgery.patientId)
            } catch {
                // ignore refresh errors in detail context
            }
        }

        do {
            srpa = try await srpaSession.getBySurgery(surgeryId: surgeryId)
        } catch {
            // ignore refresh errors in detail context
        }
    }
}
