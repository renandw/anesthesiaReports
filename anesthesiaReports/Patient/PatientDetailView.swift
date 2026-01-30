import SwiftUI

struct PatientDetailView: View {
    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var userSession: UserSession
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
                var age: String {
                    guard
                        let birthDate = DateFormatterHelper.parseISODate(patient.dateOfBirth)
                    else {
                        return "—"
                    }
                    return AgeContext.out.ageLongString(from: birthDate)
                }
                Section {
                    DetailRow(label: "Nome", value: patient.name)
                    DetailRow(label: "Sexo", value: patient.sex.sexStringDescription)
                    DetailRow(
                        label: "Nascimento",
                        value: DateFormatterHelper
                            .parseISODate(patient.dateOfBirth)
                            .map { DateFormatterHelper.format($0, dateStyle: .medium) }
                            ?? ""
                    )
                    DetailRow(label: "Idade", value: age)
                    
                        
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
                
                if patient.myPermission == "write" || patient.myPermission == "" {
                    //gambiarra para que quando permission == read, não poder compartilhar com outros
                    Section {
                        let visibleShares = shares.filter { $0.userId != userSession.user?.id }
                        if isLoadingShares {
                            ProgressView()
                        } else if visibleShares.isEmpty {
                            Text("Nenhum compartilhamento")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(visibleShares) { share in
                                HStack {
                                    Text(share.userName ?? share.userId)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                    PermissionInlineBadgeView(permission: share.permission)
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
                            showMetadata = true
                        } label: {
                        Image(systemName: "info.circle.fill")
                        }
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if patient?.myPermission == "write" && patient != nil {
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
        .task { await load() }
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
        .onChange(of: showShare) { oldValue, newValue in
            if oldValue && !newValue {
                Task { await loadShares() }
            }
        }
        .onChange(of: patient?.myPermission) { _ in
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
        guard patient?.myPermission == "write" else {
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

    private func reloadAll() async {
        await load()
        await loadShares()
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}
