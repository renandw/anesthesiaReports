import SwiftUI

struct PatientDetailView: View {
    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @Environment(\.dismiss) private var dismiss

    let patientId: String

    @State private var patient: PatientDTO?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isLoadingShares = false
    @State private var isDeleting = false
    @State private var showEdit = false
    @State private var showShare = false
    @State private var showDeleteConfirm = false
    @State private var showMetadata = false
    @State private var shares: [PatientShareDTO] = []
    @State private var surgeries: [SurgeryDTO] = []
    @State private var isLoadingSurgeries = false
    @State private var showCreateSurgery = false

    var navigationTitle: String {
        patient?.name ?? "Paciente"
    }


    var body: some View {
        Form {
            if isLoading {
                Section {
                    ProgressView()
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            if let patient {
                Section {
                    DetailRow(label: "Nome", value: patient.name)
                    DetailRow(label: "Sexo", value: patient.sex.sexStringDescription)
                    DetailRow(
                        label: "Nascimento",
                        value: DateFormatterHelper.formatISODateString(
                            patient.dateOfBirth,
                            dateStyle: .medium
                        )
                    )
                    DetailRow(label: "Idade", value: ageText(for: patient))
                    HStack {
                        Text("Acesso")
                            .foregroundStyle(.secondary)
                        Spacer()
                        RoleInlineBadgeView(role: patient.resolvedRole)
                    }
                    
                        
                    if patient.cns != "000000000000000" {
                        DetailRow(label: "CNS", value: patient.cns.cnsFormatted(expectedLength: 15, digitsOnly: true))
                    }
                } header: {
                    HStack {
                        Text("Identificação do paciente")
                        Spacer()
                        Button {
                            showEdit = true
                        } label: {
                        Image(systemName: "info.circle.fill")
                        }
                    }
                }
                
                if patient.resolvedPermission == .write {
                    //gambiarra para que quando permission == read, não poder compartilhar com outros
                    Section {
                        if isLoadingShares {
                            ProgressView()
                        } else if visibleShares().isEmpty {
                            Text("Nenhum compartilhamento")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(visibleShares()) { share in
                                HStack {
                                    Text(share.userName ?? share.userId)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                    RoleInlineBadgeView(role: roleForShare(share))
                                }
                            }
                        }
                    } header: {
                        HStack{
                            Text("Compartilhado com")
                            Spacer()
                            Button {
                                showShare = true
                            } label: {
                            Image(systemName: "person.fill.badge.plus")
                            }
                        }
                    }
                }

                Section {
                    if isLoadingSurgeries {
                        ProgressView()
                    } else if surgeries.isEmpty {
                        Text("Nenhuma cirurgia")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(surgeries) { surgery in
                            NavigationLink {
                                SurgeryDetailView(surgeryId: surgery.id)
                                    .environmentObject(surgerySession)
                                    .environmentObject(userSession)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(surgery.proposedProcedure)
                                            .font(.subheadline.weight(.semibold))
                                        HStack {
                                            Text(surgery.hospital)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("*")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(DateFormatterHelper.formatISODateString(
                                                surgery.date,
                                                dateStyle: .medium
                                            ))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if surgery.resolvedPermission != .owner {
                                        Text(surgery.resolvedPermission.displayName)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(surgery.resolvedPermission.color)
                                    }
                                }
                            }
                            
                        }
                    }
                } header: {
                    HStack {
                        Text("Cirurgias encontradas")
                        Spacer()
                        if patient.resolvedPermission == .write {
                            Button {
                                showCreateSurgery = true
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                }

                Section {
                    if showMetadata {
                        DetailRow(label: "Criado em", value: DateFormatterHelper.format(patient.createdAt, dateStyle: .medium, timeStyle: .short))
                        DetailRow(label: "Criado por", value: patient.createdByName)
                        DetailRow(label: "Atualizado em", value: DateFormatterHelper.format(patient.updatedAt, dateStyle: .medium, timeStyle: .short))
                        DetailRow(
                            label: "Atualizado por",
                            value: patient.updatedByName ?? "Nunca Atualizado"
                        )
                        DetailRow(
                            label: "Última Atividade em",
                            value: patient.lastActivityAt
                                .map { DateFormatterHelper.format($0, dateStyle: .medium, timeStyle: .short) } ?? "Sem Última Atividade"
                        )
                        DetailRow(label: "Última Atividade por", value: patient.lastActivityByName ?? "Sem Última Atividade")
                        DetailRow(label: "Versão", value: "\(patient.version)")
                        DetailRow(label: "Sincronização", value: patient.syncStatus)
                        DetailRow(
                            label: "Última Sincronização em",
                            value: patient.lastSyncAt
                                .map { DateFormatterHelper.format($0, dateStyle: .medium, timeStyle: .short) } ?? "Nunca Sincronizado"
                        )
                        DetailRow(label: "Fingerprint", value: patient.fingerprint)
                        
                    }
                } header: {
                    HStack {
                        Text("Metadados")
                        Spacer()
                        Button {
                            showMetadata.toggle()
                        } label: {
                            Image(systemName: showMetadata ? "info.circle.fill" : "info.circle")
                        }
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if patient?.resolvedPermission == .write && patient != nil {
                ToolbarItem(placement: .topBarTrailing){
                    Menu {
                        Button {
                            showEdit = true
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        Button {
                            showShare = true
                        } label: {
                            Label("Compartilhar", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showDeleteConfirm = true
                        } label :{
                            Label("Excluir", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
        }
        .confirmationDialog("Excluir paciente?", isPresented: $showDeleteConfirm) {
            Button("Excluir", role: .destructive) {
                Task { await deletePatient() }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .task { await reloadAll() }
        .refreshable { await reloadAll() }
        .sheet(isPresented: $showEdit) {
            PatientFormView(
                mode: .standalone,
                existing: patient,
                onComplete: { updated in
                    patient = updated
                }
            )
            .environmentObject(patientSession)
        }
        .sheet(isPresented: $showShare) {
            NavigationStack {
                CanShareWithView(patientId: patientId, createdById: patient?.createdBy)
                    .environmentObject(patientSession)
                    .environmentObject(userSession)
            }
        }
        .sheet(isPresented: $showCreateSurgery) {
            SurgeryFormView(
                mode: .standalone,
                patientId: patientId,
                existing: nil,
                onComplete: { created in
                    Task { await loadSurgeries() }
                }
            )
            .environmentObject(surgerySession)
        }
        .onChange(of: showShare) { oldValue, newValue in
            if oldValue && !newValue {
                Task { await loadShares() }
            }
        }
        .onChange(of: patient?.resolvedPermission) { _ in
            Task { await loadShares() }
        }
        .disabled(isDeleting)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            patient = try await patientSession.getById(patientId)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
        isLoading = false
    }

    private func deletePatient() async {
        errorMessage = nil
        do {
            isDeleting = true
            try await patientSession.delete(patientId: patientId)
            dismiss()
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
        isDeleting = false
    }

    private func loadShares() async {
        guard patient?.resolvedPermission == .write else {
            shares = []
            return
        }

        isLoadingShares = true
        do {
            shares = try await patientSession.listShares(patientId: patientId)
        } catch let authError as AuthError {
            if !authError.isFatalSessionError {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = "Erro de rede"
        }
        isLoadingShares = false
    }

    private func loadSurgeries() async {
        isLoadingSurgeries = true
        do {
            surgeries = try await surgerySession.listByPatient(patientId: patientId)
        } catch let authError as AuthError {
            if !authError.isFatalSessionError {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = "Erro de rede"
        }
        isLoadingSurgeries = false
    }

    private func roleForShare(_ share: PatientShareDTO) -> PatientRole {
        guard let patient else { return .unknown }
        if share.userId == patient.createdBy {
            return .owner
        }
        if share.grantedBy == share.userId {
            return .editor
        }
        return .shared
    }

    private func visibleShares() -> [PatientShareDTO] {
        shares.filter { $0.userId != userSession.user?.id }
    }

    private func reloadAll() async {
        await load()
        await loadShares()
        await loadSurgeries()
    }

    private func ageText(for patient: PatientDTO) -> String {
        guard let birthDate = DateFormatterHelper.parseISODate(patient.dateOfBirth) else {
            return "—"
        }
        return AgeContext.out.ageLongString(from: birthDate)
    }
}
