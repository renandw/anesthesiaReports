import SwiftUI

struct SurgeryDetailView: View {
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var anesthesiaSession: AnesthesiaSession
    @Environment(\.dismiss) private var dismiss

    let surgeryId: String
    @State private var showMetadata = false
    @State private var surgery: SurgeryDTO?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isLoadingShares = false
    @State private var isDeleting = false
    @State private var showEdit = false
    @State private var showAnesthesiaProgress = false
    @State private var anesthesiaDetails: SurgeryAnesthesiaDetailsDTO?
    @State private var showShare = false
    @State private var showDeleteConfirmation = false
    @State private var shares: [SurgeryShareDTO] = []

    var navigationTitle: String {
        surgery?.proposedProcedure ?? "Cirurgia"
    }

    private var visibleShares: [SurgeryShareDTO] {
        guard let currentUserId = userSession.user?.id else { return shares }
        return shares.filter { $0.userId != currentUserId }
    }

    var body: some View {
        Form {
            if isLoading {
                Section { ProgressView() }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            if let surgery {
                Section {
                    DetailRow(label: "Data", value: DateFormatterHelper.formatISODateString(surgery.date, dateStyle: .medium))
                    DetailRow(label: "Convênio", value: surgery.insuranceName)
                    if surgery.insuranceNumber != "-" && surgery.type == "insurance" {
                        DetailRow(label: "Carteirinha", value: surgery.insuranceNumber)
                    } else if surgery.type == "sus" {
                        DetailRow(label: "Prontuário", value: surgery.insuranceNumber)
                    }
                    DetailRow(label: "Cirurgião", value: surgery.mainSurgeon)
                    if let aux = surgery.auxiliarySurgeons, !aux.isEmpty {
                        DetailRow(label: "Auxiliares", value: aux.joined(separator: ", "))
                    }
                    DetailRow(label: "Hospital", value: surgery.hospital)
                    DetailRow(label: "Peso", value: surgery.weight)
                    DetailRow(label: "Cirurgia", value: surgery.proposedProcedure)
                    if let complete = surgery.completeProcedure, !complete.isEmpty {
                        DetailRow(label: "Cirurgia Realizada", value: complete)
                    }
                } header: {
                    Text("Dados da cirurgia")
                }

                Section {
                    if surgery.cbhpms.isEmpty {
                        Text("Nenhum CBHPM")
                            .foregroundStyle(.secondary)
                    } else {
                        HStack {
                            Text("Total")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(surgery.cbhpms.count) \(surgery.cbhpms.count == 1 ? "item" : "itens")")
                                .fontWeight(.bold)
                        }

                        NavigationLink {
                            SurgeryCbhpmsListView(cbhpms: surgery.cbhpms)
                        } label: {
                            Label("Ver lista completa", systemImage: "list.bullet")
                        }
                    }
                } header: {
                    Text("Códigos e Procedimentos CBHPM")
                }

                if canSeeFinancial(surgery.resolvedPermission), surgery.type == "insurance" {
                    Section {
                        NavigationLink {
                            FinancialDetailView(
                                surgeryId: surgery.id,
                                permission: surgery.resolvedPermission
                            )
                        } label: {
                            Label("Abrir financeiro", systemImage: "dollarsign.circle")
                        }
                    } header: {
                        Text("Financeiro")
                    }
                }

                if canEdit(surgery.resolvedPermission) {
                    Section {
                        if let anesthesia = anesthesiaDetails {
                              NavigationLink {
                                 // AnesthesiaDetailView(anesthesia: anesthesia)
                              } label: {
                                  Label("Detalhes da Anestesia", systemImage: "waveform.path.ecg")
                              }
                          } else {
                              Button {
                                  Task { await openAnesthesiaSheet() }
                              } label: {
                                  Label("Criar anestesia", systemImage: "plus.circle")
                              }
                          }
                    } header: {
                        Text("Anesthesia")
                    }
                }
                

                if canShare(surgery.resolvedPermission) {
                    Section {
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
                                    SurgeryPermissionInlineBadgeView(permission: share.resolvedPermission)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Compartilhado com")
                            Spacer()
                            Button {
                                showShare = true
                            } label: {
                                Image(systemName: "person.fill.badge.plus")
                            }
                        }
                    }
                    
                    Section {
                        if showMetadata {
                            HStack {
                                Text("Permissão")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                SurgeryPermissionInlineBadgeView(permission: surgery.resolvedPermission)
                            }
                            DetailRow(label: "Tipo", value: SurgeryType(rawValue: surgery.type)?.displayName ?? surgery.type)
                            DetailRow(label: "Status", value: surgery.status)
                            DetailRow(label: "Criado em", value: DateFormatterHelper.format(surgery.createdAt, dateStyle: .medium, timeStyle: .short))
                            DetailRow(label: "Criado por", value: surgery.createdByName)
                            DetailRow(label: "Atualizado em", value: DateFormatterHelper.format(surgery.updatedAt, dateStyle: .medium, timeStyle: .short))
                            DetailRow(
                                label: "Atualizado por",
                                value: surgery.updatedByName ?? "Nunca Atualizado"
                            )
                            DetailRow(
                                label: "Última Atividade em",
                                value: surgery.lastActivityAt
                                    .map { DateFormatterHelper.format($0, dateStyle: .medium, timeStyle: .short) } ?? "Sem Última Atividade"
                            )
                            DetailRow(label: "Última Atividade por", value: surgery.lastActivityByName ?? "Sem Última Atividade")
                            DetailRow(label: "Versão", value: "\(surgery.version)")
                            DetailRow(label: "Sincronização", value: surgery.syncStatus)
                            DetailRow(
                                label: "Última Sincronização em",
                                value: surgery.lastSyncAt
                                    .map { DateFormatterHelper.format($0, dateStyle: .medium, timeStyle: .short) } ?? "Nunca Sincronizado"
                            )
                        }
                    } header: {
                        HStack{
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
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let surgery, canEdit(surgery.resolvedPermission) {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEdit = true
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        if canShare(surgery.resolvedPermission) {
                            Button {
                                showShare = true
                            } label: {
                                Label("Compartilhar", systemImage: "square.and.arrow.up")
                            }
                        }
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .confirmationDialog(
            "Excluir cirurgia?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                Task { await removeSurgery() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essa ação marca a cirurgia como excluída e não pode ser desfeita pelo app.")
        }
        .task { await reloadAll() }
        .refreshable { await reloadAll() }
        .sheet(isPresented: $showEdit) {
            if let surgery {
                SurgeryFormView(
                    mode: .standalone,
                    patientId: surgery.patientId,
                    existing: surgery,
                    onComplete: { updated in
                        self.surgery = updated
                    }
                )
                .environmentObject(surgerySession)
            }
        }
        .sheet(isPresented: $showShare) {
            if let surgery {
                NavigationStack {
                    CanShareSurgeryWithView(
                        surgeryId: surgery.id,
                        createdById: surgery.createdBy,
                        patientId: surgery.patientId
                    )
                    .environmentObject(userSession)
                    .environmentObject(surgerySession)
                }
            }
        }
        .sheet(isPresented: $showAnesthesiaProgress, onDismiss: {
            Task { await reloadAll() }
        }) {
            AnesthesiaFormView(
                mode: .standalone,
                surgeryId: surgeryId,
                initialAnesthesia: anesthesiaDetails,
                onComplete: { _ in
                    Task { await load() }
                }
            )
            .environmentObject(anesthesiaSession)
        }
        .onChange(of: showShare) { oldValue, newValue in
            if oldValue && !newValue {
                Task { await loadShares() }
            }
        }
        .onChange(of: surgery?.resolvedPermission) { _ in
            Task { await loadShares() }
        }
    }

    private func reloadAll() async {
        await load()
        await loadAnesthesiaLookup()
        await loadShares()
    }

    private func openAnesthesiaSheet() async {
        showAnesthesiaProgress = true
    }

    private func load() async {
        guard !isDeleting else { return }
        isLoading = true
        errorMessage = nil
        do {
            surgery = try await surgerySession.getById(surgeryId)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
        isLoading = false
    }

    private func loadAnesthesiaLookup() async {
        guard let surgery, canEdit(surgery.resolvedPermission) else {
            anesthesiaDetails = nil
            return
        }

        do {
            anesthesiaDetails = try await anesthesiaSession.getBySurgery(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if case .notFound = authError {
                anesthesiaDetails = nil
            } else {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func loadShares() async {
        guard let surgery, canShare(surgery.resolvedPermission) else {
            shares = []
            return
        }

        isLoadingShares = true
        do {
            shares = try await surgerySession.listShares(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if !authError.isFatalSessionError {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
        isLoadingShares = false
    }

    private func removeSurgery() async {
        guard !isDeleting else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await surgerySession.delete(surgeryId: surgeryId)
            dismiss()
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func canEdit(_ permission: SurgeryPermission) -> Bool {
        permission != .read
    }

    private func canShare(_ permission: SurgeryPermission) -> Bool {
        permission == .full_editor || permission == .owner
    }
    
    private func canSeeFinancial(_ permission: SurgeryPermission) -> Bool {
        permission != .unknown
    }
}

private struct SurgeryCbhpmsListView: View {
    let cbhpms: [SurgeryCbhpmDTO]

    var body: some View {
        List {
            ForEach(Array(cbhpms.enumerated()), id: \.offset) { index, cbhpm in
                Section {
                    DetailRow(label: "Código", value: cbhpm.code)
                    Text(cbhpm.procedure)
                    DetailRow(label: "Porte", value: cbhpm.port)
                } header: {
                    Text("Item \(index + 1)")
                }
            }
        }
        .navigationTitle("CBHPMs")
        .navigationBarTitleDisplayMode(.inline)
    }
}
