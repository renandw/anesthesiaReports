import SwiftUI

struct SurgeryDetailView: View {
    private enum LoadingScope: Hashable {
        case surgery
        case shares
        case preanesthesia
        case anesthesia
        case srpa
    }

    private enum ActiveSheet: Identifiable, Equatable {
        case edit
        case share
        case anesthesia
        case preanesthesia
        case srpa

        var id: String {
            switch self {
            case .edit:
                return "edit"
            case .share:
                return "share"
            case .anesthesia:
                return "anesthesia"
            case .preanesthesia:
                return "preanesthesia"
            case .srpa:
                return "srpa"
            }
        }
    }

    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var anesthesiaSession: AnesthesiaSession
    @EnvironmentObject private var srpaSession: SRPASession
    @EnvironmentObject private var preanesthesiaSession: PreanesthesiaSession
    @EnvironmentObject private var sharedPreSession: SharedPreAnesthesiaSession
    @Environment(\.dismiss) private var dismiss

    let surgeryId: String
    @State private var showMetadata = false
    @State private var surgery: SurgeryDTO?
    @State private var errorMessage: String?
    @State private var isDeleting = false
    @State private var activeSheet: ActiveSheet?
    @State private var anesthesiaDetails: SurgeryAnesthesiaDetailsDTO?
    @State private var preanesthesiaDetails: SurgeryPreanesthesiaDetailsDTO?
    @State private var srpaDetails: SurgerySRPADetailsDTO?
    @State private var showDeleteConfirmation = false
    @State private var shares: [SurgeryShareDTO] = []
    @State private var loadingScopes: Set<LoadingScope> = []
    @State private var hasLoadedSurgery = false
    @State private var hasLoadedShares = false
    @State private var hasLoadedPreanesthesia = false
    @State private var hasLoadedAnesthesia = false
    @State private var hasLoadedSrpa = false

    var navigationTitle: String {
        surgery?.proposedProcedure ?? "Cirurgia"
    }

    private var visibleShares: [SurgeryShareDTO] {
        guard let currentUserId = userSession.user?.id else { return shares }
        return shares.filter { $0.userId != currentUserId }
    }

    var body: some View {
        Form {
            errorSection

            if !hasLoadedSurgery || surgery == nil {
                surgeryDataLoadingSection
                cbhpmLoadingSection
                financialLoadingSection
                preanesthesiaLoadingSection
                anesthesiaLoadingSection
                srpaLoadingSection
                sharesLoadingSection
                metadataLoadingSection
            } else if let surgery {
                surgeryDataSection(surgery)
                cbhpmSection(surgery)

                if canSeeFinancial(surgery.resolvedPermission), surgery.type == "insurance" {
                    financialSection(surgery)
                }

                if canEdit(surgery.resolvedPermission) {
                    if !hasLoadedPreanesthesia {
                        preanesthesiaLoadingSection
                    } else {
                        preanesthesiaSection
                    }
                    if !hasLoadedAnesthesia {
                        anesthesiaLoadingSection
                    } else {
                        anesthesiaSection(surgery)
                    }
                    if !hasLoadedSrpa {
                        srpaLoadingSection
                    } else {
                        srpaSection(surgery)
                    }
                }
                

                if canShare(surgery.resolvedPermission) {
                    if !hasLoadedShares {
                        sharesLoadingSection
                    } else {
                        sharesSection
                    }
                    
                    metadataSection(surgery)
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
                            activeSheet = .edit
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        if canShare(surgery.resolvedPermission) {
                            Button {
                                activeSheet = .share
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
                    .accessibilityLabel("Mais ações")
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
        .task(id: surgeryId) { await reloadAll() }
        .refreshable { await reloadAll() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
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
            case .share:
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
            case .anesthesia:
                AnesthesiaFormView(
                    mode: .standalone,
                    surgeryId: surgeryId,
                    initialAnesthesia: anesthesiaDetails,
                    onComplete: { _ in
                        Task { await load() }
                    }
                )
                .environmentObject(anesthesiaSession)
                .environmentObject(sharedPreSession)
            case .preanesthesia:
                NavigationStack {
                    PreanesthesiaFormView(
                        surgeryId: surgeryId,
                        initialPreanesthesia: preanesthesiaDetails,
                        mode: .standalone,
                        onSaved: { updated in
                            preanesthesiaDetails = updated
                            Task { await load() }
                        }
                    )
                    .environmentObject(preanesthesiaSession)
                    .environmentObject(sharedPreSession)
                }
            case .srpa:
                SRPAFormView(
                    mode: .standalone,
                    surgeryId: surgeryId,
                    initialSRPA: srpaDetails,
                    onComplete: { updated in
                        srpaDetails = updated
                        Task { await load() }
                    }
                )
                .environmentObject(srpaSession)
            }
        }
        .onChange(of: activeSheet) { oldValue, newValue in
            if oldValue == .share, newValue == nil {
                Task { await loadShares() }
            }
            if newValue == nil, (oldValue == .anesthesia || oldValue == .preanesthesia || oldValue == .srpa) {
                Task { await reloadAll() }
            }
        }
        .onChange(of: surgery?.resolvedPermission) { _, newValue in
            if newValue != nil, !loadingScopes.contains(.shares) {
                Task { await loadShares() }
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage {
            Section {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    private var surgeryDataLoadingSection: some View {
        placeholderSection(title: "Dados da cirurgia", rows: 6, show: true)
    }

    private var cbhpmLoadingSection: some View {
        placeholderSection(title: "Códigos e Procedimentos CBHPM", rows: 2, show: true)
    }

    private var financialLoadingSection: some View {
        placeholderSection(title: "Financeiro", rows: 1, show: true)
    }

    private var preanesthesiaLoadingSection: some View {
        placeholderSection(title: "Preanesthesia", rows: 1, show: true)
    }

    private var anesthesiaLoadingSection: some View {
        placeholderSection(title: "Anesthesia", rows: 1, show: true)
    }

    private var srpaLoadingSection: some View {
        placeholderSection(title: "SRPA", rows: 1, show: true)
    }

    private var sharesLoadingSection: some View {
        placeholderSection(title: "Compartilhado com", rows: 2, show: true)
    }

    private var metadataLoadingSection: some View {
        placeholderSection(title: "Metadados", rows: 4, show: true)
    }

    @ViewBuilder
    private func placeholderSection(title: String, rows: Int, show: Bool) -> some View {
        if show {
            Section {
                VStack(spacing: 12) {
                    ForEach(0..<rows, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 24)
                    }
                }
                .redacted(reason: .placeholder)
                .shimmering()
            } header: {
                Text(title)
            }
        }
    }

    private func surgeryDataSection(_ surgery: SurgeryDTO) -> some View {
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
    }

    private func cbhpmSection(_ surgery: SurgeryDTO) -> some View {
        Section {
            if surgery.cbhpms.isEmpty {
                Text("Nenhum CBHPM")
                    .foregroundStyle(.secondary)
            } else {
                NavigationLink {
                    SurgeryCbhpmsListView(cbhpms: surgery.cbhpms)
                } label: {
                    Label("Ver procedimentos", systemImage: "list.bullet")
                    Spacer()
                    Text("\(surgery.cbhpms.count) \(surgery.cbhpms.count == 1 ? "item" : "itens")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .bold()
                }
            }
        } header: {
            Text("Códigos e Procedimentos CBHPM")
        }
    }

    private func financialSection(_ surgery: SurgeryDTO) -> some View {
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

    private var preanesthesiaSection: some View {
        Section {
            if let preanesthesia = preanesthesiaDetails {
                NavigationLink {
                    PreanesthesiaDetailView(
                        surgeryId: surgeryId,
                        initialPreanesthesia: preanesthesia
                    )
                } label: {
                    Label("Detalhes da Pré-anestesia", systemImage: "doc.text.magnifyingglass")
                }
            } else {
                Button {
                    activeSheet = .preanesthesia
                } label: {
                    Label("Criar Pré-anestesia", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Avaliação Pré-Anestésica")
        }
    }

    private func anesthesiaSection(_ surgery: SurgeryDTO) -> some View {
        Section {
            if let anesthesia = anesthesiaDetails {
                NavigationLink {
                    AnesthesiaDetailView(
                        surgeryId: surgeryId,
                        initialSurgery: surgery,
                        initialAnesthesia: anesthesia
                    )
                } label: {
                    Label("Detalhes da Anestesia", systemImage: "waveform.path.ecg")
                }
            } else {
                Button {
                    activeSheet = .anesthesia
                } label: {
                    Label("Criar anestesia", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Anesthesia")
        }
    }

    private func srpaSection(_ surgery: SurgeryDTO) -> some View {
        Section {
            if let srpa = srpaDetails {
                NavigationLink {
                    SRPADetailView(
                        surgeryId: surgeryId,
                        initialSurgery: surgery,
                        initialSRPA: srpa
                    )
                } label: {
                    Label("Detalhes do SRPA", systemImage: "bed.double")
                }
            } else {
                Button {
                    activeSheet = .srpa
                } label: {
                    Label("Criar SRPA", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("SRPA")
        }
    }

    private var sharesSection: some View {
        Section {
            if visibleShares.isEmpty {
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
                    activeSheet = .share
                } label: {
                    Image(systemName: "person.fill.badge.plus")
                }
                .accessibilityLabel("Compartilhar cirurgia")
            }
        }
    }

    private func metadataSection(_ surgery: SurgeryDTO) -> some View {
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
                .accessibilityLabel(showMetadata ? "Ocultar metadados" : "Mostrar metadados")
            }
        }
    }

    private func reloadAll() async {
        hasLoadedSurgery = false
        hasLoadedShares = false
        hasLoadedPreanesthesia = false
        hasLoadedAnesthesia = false
        hasLoadedSrpa = false
        await load()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadPreanesthesiaLookup() }
            group.addTask { await loadAnesthesiaLookup() }
            group.addTask { await loadSrpaLookup() }
            group.addTask { await loadShares() }
        }
    }

    private func load() async {
        guard !isDeleting else { return }
        hasLoadedSurgery = false
        loadingScopes.insert(.surgery)
        defer {
            loadingScopes.remove(.surgery)
            hasLoadedSurgery = true
        }
        errorMessage = nil
        do {
            surgery = try await surgerySession.getById(surgeryId)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func loadAnesthesiaLookup() async {
        hasLoadedAnesthesia = false
        loadingScopes.insert(.anesthesia)
        defer {
            loadingScopes.remove(.anesthesia)
            hasLoadedAnesthesia = true
        }
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

    private func loadPreanesthesiaLookup() async {
        hasLoadedPreanesthesia = false
        loadingScopes.insert(.preanesthesia)
        defer {
            loadingScopes.remove(.preanesthesia)
            hasLoadedPreanesthesia = true
        }
        guard let surgery, canEdit(surgery.resolvedPermission) else {
            preanesthesiaDetails = nil
            return
        }

        do {
            preanesthesiaDetails = try await preanesthesiaSession.getBySurgery(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if case .notFound = authError {
                preanesthesiaDetails = nil
            } else {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func loadSrpaLookup() async {
        hasLoadedSrpa = false
        loadingScopes.insert(.srpa)
        defer {
            loadingScopes.remove(.srpa)
            hasLoadedSrpa = true
        }
        guard let surgery, canEdit(surgery.resolvedPermission) else {
            srpaDetails = nil
            return
        }

        do {
            srpaDetails = try await srpaSession.getBySurgery(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if case .notFound = authError {
                srpaDetails = nil
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
            hasLoadedShares = true
            return
        }

        hasLoadedShares = false
        loadingScopes.insert(.shares)
        defer {
            loadingScopes.remove(.shares)
            hasLoadedShares = true
        }
        do {
            shares = try await surgerySession.listShares(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if !authError.isFatalSessionError {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
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
            ForEach(Array(cbhpms.enumerated()), id: \.element.stableId) { index, cbhpm in
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

private extension SurgeryCbhpmDTO {
    var stableId: String {
        "\(code)|\(procedure)|\(port)"
    }
}
