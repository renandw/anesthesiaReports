import SwiftUI

struct SurgeryDuplicatePatientSheet: View {
    @Environment(\.dismiss) private var dismiss

    let message: String
    let foundSurgeries: [PrecheckSurgeryMatchDTO]
    let onCreateNew: () -> Void
    let onSelect: (PrecheckSurgeryMatchDTO) -> Void

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
                        ForEach(foundSurgeries) { surgery in
                            SurgeryDuplicateCard(
                                surgery: surgery,
                                onSelect: { onSelect(surgery) }
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
                        Label("Criar Nova Mesmo Assim", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .alert(
                        "Deseja criar uma nova cirurgia?",
                        isPresented: $showCreateConfirmation
                    ) {
                        Button("Criar Nova", role: .destructive) {
                            onCreateNew()
                        }
                        Button("Cancelar", role: .cancel) { }
                    } message: {
                        Text("Esta ação cria um registro possivelmente duplicado.")
                    }
                }
            }
            .navigationTitle("Cirurgias Encontradas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }
}

private struct SurgeryDuplicateCard: View {
    let surgery: PrecheckSurgeryMatchDTO
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()
                Text("Match \(surgery.matchScore)/6")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }

            detailRow("Procedimento", surgery.proposedProcedure)
            detailRow("Data", DateFormatterHelper.formatISODateString(surgery.date))
            detailRow("Hospital", surgery.hospital)
            detailRow("Convênio", surgery.insuranceName)
            detailRow("Cirurgião", surgery.mainSurgeon)

            Divider()

            Button {
                onSelect()
            } label: {
                Text("Selecionar Cirurgia")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}

