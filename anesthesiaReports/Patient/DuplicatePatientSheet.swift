import SwiftUI

struct DuplicatePatientSheet: View {
    @Environment(\.dismiss) private var dismiss

    let message: String
    let foundPatients: [PrecheckMatchDTO]
    let onCreateNew: () -> Void
    let onSelect: (PrecheckMatchDTO) -> Void
    let onUpdate: (PrecheckMatchDTO) -> Void
    
    @State private var showCreateConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)

                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))

                ScrollView {
                    LazyVStack {
                        ForEach(foundPatients) { patient in
                            PatientDuplicateCard(
                                patient: patient,
                                onSelect: { onSelect(patient) },
                                onUpdate: { onUpdate(patient) }
                            )
                        }
                        .padding(.bottom, 2)
                    }
                    .padding()
                }

                VStack(spacing: 0) {
                    Divider()

                    Button(role: .destructive) {
                        showCreateConfirmation = true
                    } label: {
                        Label("Criar Novo Mesmo Assim", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .alert(
                        "Deseja criar um novo paciente?",
                        isPresented: $showCreateConfirmation
                    ) {
                        Button("Criar Novo", role: .destructive) {
                            onCreateNew()
                        }
                        Button("Cancelar", role: .cancel) { }
                    } message: {
                        Text("Esta ação cria um registro duplicado.")
                    }
                }
            }
            .navigationTitle("Pacientes Encontrados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {Image(systemName: "xmark") }
                }
            }
        }
    }
}

// MARK: - Patient Duplicate Card

struct PatientDuplicateCard: View {
    let patient: PrecheckMatchDTO
    let onSelect: () -> Void
    let onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(patient.sex.sexColor)
                        .frame(width: 40, height: 40)
                    Text(initials(from: patient.patientName))
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(patient.patientName)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .lineLimit(1)
                            .truncationMode(.tail)

                    
                    }

                    HStack(spacing: 8) {
                        Label(patient.sex.sexStringDescription, systemImage: patient.sex.sexImage)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(DateFormatterHelper
                            .parseISODate(patient.dateOfBirth)
                            .map { DateFormatterHelper.format($0, dateStyle: .medium) }
                            ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if patient.cns != "000000000000000" {
                        HStack(spacing: 6) {
                            Text("CNS:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .bold()
                            Text(patient.cns.cnsFormatted(expectedLength: 15, digitsOnly: true))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .bold()
                        }
                    }
                }
                Spacer()
                MatchBadge(level: patient.matchLevel)
                
            }
            .frame(maxWidth: .infinity)
            Divider()
            

            HStack(spacing: 12) {
                Button {
                    onSelect()
                } label: {
                    Text("Selecionar")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onUpdate()
                } label: {
                    Text("Atualizar")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func initials(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "" }
        if parts.count == 1 {
            return parts[0].first.map { String($0).uppercased() } ?? ""
        }
        let first = parts.first?.first.map { String($0) } ?? ""
        let last = parts.last?.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }
}

private struct MatchBadge: View {
    let level: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var label: String {
        switch level {
        case "strong":
            return "Semelhante"
        case "weak":
            return "Provável"
        default:
            return "Possível"
        }
    }

    private var color: Color {
        switch level {
        case "strong":
            return .green
        case "weak":
            return .orange
        default:
            return .secondary
        }
    }
}

#Preview("DuplicatePatientSheet - Sample") {
    // Sample patient using provided data
    let sample = PrecheckMatchDTO(
        patientId: "749dbba1-16bc-4d84-bd41-0b0510591140",
        patientName: "Ilza Alves De Lima",
        sex: .female,
        dateOfBirth: "1979-09-21",
        cns: "700700935596176",
        createdBy: "270d7e54-f901-4cb5-914c-ccf5ac15c4bd",
        createdByName: "Renan Wrobel",
        fingerprintMatch: true,
        matchLevel: "strong",
    )
    let sample2 = PrecheckMatchDTO(
        patientId: "749dbba1-46bc-4d84-bd41-0b0510591140",
        patientName: "Ilza Alves De Lima",
        sex: .female,
        dateOfBirth: "1979-09-21",
        cns: "700700935596176",
        createdBy: "270d7e54-f901-4cb5-914c-ccf5ac15c4bd",
        createdByName: "Renan Wrobel",
        fingerprintMatch: true,
        matchLevel: "strong",
    )
    let sample3 = PrecheckMatchDTO(
        patientId: "749dbba1-d6bc-4d84-bd41-0b0510591140",
        patientName: "Ilza Alves De Lima",
        sex: .female,
        dateOfBirth: "1979-09-21",
        cns: "700700935596176",
        createdBy: "270d7e54-f901-4cb5-914c-ccf5ac15c4bd",
        createdByName: "Renan Wrobel",
        fingerprintMatch: true,
        matchLevel: "weak",
    )

    DuplicatePatientSheet(
        message: "Você está cadastrando um paciente que pode estar no banco de dados. Revise para evitar dados duplicados.",
        foundPatients: [sample, sample2, sample3],
        onCreateNew: {
            // Preview action
            print("Create new patient tapped")
        },
        onSelect: { selected in
            // Preview action
            print("Selected existing: \(selected.patientName)")
        },
        onUpdate: { selected in
            // Preview action
            print("Update tapped for: \(selected.patientName)")
        }
    )
}
