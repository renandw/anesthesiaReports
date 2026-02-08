import SwiftUI

struct PatientDetailView: View {
    private enum LoadingScope: Hashable {
        case patient
        case shares
        case surgeries
    }

    private enum ActiveSheet: Identifiable, Equatable {
        case edit
        case share
        case createSurgery

        var id: String {
            switch self {
            case .edit:
                return "edit"
            case .share:
                return "share"
            case .createSurgery:
                return "createSurgery"
            }
        }
    }

    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var anesthesiaSession: AnesthesiaSession
    @EnvironmentObject private var srpaSession: SRPASession
    @EnvironmentObject private var preanesthesiaSession: PreanesthesiaSession
    @EnvironmentObject private var sharedPreSession: SharedPreAnesthesiaSession
    @Environment(\.dismiss) private var dismiss

    let patientId: String
    private let autoLoad: Bool

    @State private var patient: PatientDTO?
    @State private var errorMessage: String?
    @State private var isDeleting = false
    @State private var activeSheet: ActiveSheet?
    @State private var showDeleteConfirm = false
    @State private var showMetadata = false
    @State private var shares: [PatientShareDTO] = []
    @State private var surgeries: [SurgeryDTO] = []
    @State private var loadingScopes: Set<LoadingScope> = []
    @State private var hasLoadedPatient = false
    @State private var hasLoadedShares = false
    @State private var hasLoadedSurgeries = false

    init(patientId: String, autoLoad: Bool = true, initialLoading: Bool = false) {
        self.patientId = patientId
        self.autoLoad = autoLoad
        _loadingScopes = State(initialValue: initialLoading ? [.patient, .shares, .surgeries] : [])
    }

    var navigationTitle: String {
        patient?.name ?? "Paciente"
    }

    private var filteredShares: [PatientShareDTO] {
        visibleShares()
    }

    private var canEditPatient: Bool {
        patient?.resolvedPermission == .write
    }


    var body: some View {
        Form {
            errorSection

            if !hasLoadedPatient || patient == nil {
                informationLoadingSection
            } else if let patient {
                identificationSection(patient)
            }

            if !hasLoadedSurgeries {
                surgeryLoadingSection
            } else if let patient {
                surgeriesSection(patient)
            }

            if !hasLoadedShares {
                shareLoadingSection
            } else if canEditPatient {
                sharesSection
            }

            if let patient {
                metadataSection(patient)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if patient?.resolvedPermission == .write && patient != nil {
                ToolbarItem(placement: .topBarTrailing){
                    Menu {
                        Button {
                            activeSheet = .edit
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        Button {
                            activeSheet = .share
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
                .accessibilityLabel("Mais ações")
            }
        }
        }
        .confirmationDialog("Excluir paciente?", isPresented: $showDeleteConfirm) {
            Button("Excluir", role: .destructive) {
                Task { await deletePatient() }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .task(id: patientId) {
            if autoLoad {
                await reloadAll()
            }
        }
        .refreshable { await reloadAll() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                PatientFormView(
                    mode: .standalone,
                    existing: patient,
                    onComplete: { updated in
                        patient = updated
                    }
                )
                .environmentObject(patientSession)
            case .share:
                NavigationStack {
                    CanShareWithView(patientId: patientId, createdById: patient?.createdBy)
                        .environmentObject(patientSession)
                        .environmentObject(userSession)
                }
            case .createSurgery:
                SurgeryFormView(
                    mode: .standalone,
                    patientId: patientId,
                    existing: nil,
                    onComplete: { _ in
                        Task { await loadSurgeries() }
                    }
                )
                .environmentObject(surgerySession)
            }
        }
        .onChange(of: activeSheet) { oldValue, newValue in
            if oldValue == .share, newValue == nil {
                Task { await loadShares() }
            }
        }
        .onChange(of: patient?.resolvedPermission) { _, newValue in
            if newValue != nil, !loadingScopes.contains(.shares) {
                Task { await loadShares() }
            }
        }
        .disabled(isDeleting)
    }

    @ViewBuilder
    private var informationLoadingSection: some View {
        placeholderSection(
            title: "Informações",
            rows: 5,
            show: true
        )
    }
    
    @ViewBuilder
    private var surgeryLoadingSection: some View {
        placeholderSection(
            title: "Cirurgias",
            rows: 2,
            show: true
        )
    }
    @ViewBuilder
    private var shareLoadingSection: some View {
        placeholderSection(
            title: "Compartilhamento",
            rows: 2,
            show: true
        )
    }

    @ViewBuilder
    private func placeholderSection(title: String, rows: Int, show: Bool) -> some View {
        if show {
            Section {
                VStack(spacing: 12) {
                    ForEach(0..<rows, id: \.self) { _ in
                        HStack{
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 30)
                            Spacer()
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 30)
                        }
                    }
                }
                .redacted(reason: .placeholder)
                .shimmering()
            } header: {
                Text(title)
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

    private func identificationSection(_ patient: PatientDTO) -> some View {
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
                    activeSheet = .edit
                } label: {
                    Image(systemName: "info.circle.fill")
                }
                .accessibilityLabel("Editar paciente")
            }
        }
    }

    @ViewBuilder
    private func surgeriesSection(_ patient: PatientDTO) -> some View {
        Section {
            if surgeries.isEmpty {
                Text("Nenhuma cirurgia")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(surgeries) { surgery in
                    NavigationLink {
                        SurgeryDetailView(surgeryId: surgery.id)
                            .environmentObject(surgerySession)
                            .environmentObject(userSession)
                            .environmentObject(anesthesiaSession)
                            .environmentObject(srpaSession)
                            .environmentObject(preanesthesiaSession)
                            .environmentObject(sharedPreSession)
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
                Text("Cirurgias")
                Spacer()
                if patient.resolvedPermission == .write {
                    Button {
                        activeSheet = .createSurgery
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel("Adicionar cirurgia")
                }
            }
        }
    }

    private var sharesSection: some View {
        Section {
            if filteredShares.isEmpty {
                Text("Nenhum compartilhamento")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredShares) { share in
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
            HStack {
                Text("Compartilhado com")
                Spacer()
                Button {
                    activeSheet = .share
                } label: {
                    Image(systemName: "person.fill.badge.plus")
                }
                .accessibilityLabel("Compartilhar paciente")
            }
        }
    }

    private func metadataSection(_ patient: PatientDTO) -> some View {
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
                .accessibilityLabel(showMetadata ? "Ocultar metadados" : "Mostrar metadados")
            }
        }
    }

    private func load(trackLoading: Bool = true) async {
        hasLoadedPatient = false
        if trackLoading {
            loadingScopes.insert(.patient)
        }
        errorMessage = nil
        do {
            patient = try await patientSession.getById(patientId)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
        if trackLoading {
            loadingScopes.remove(.patient)
        }
        hasLoadedPatient = true
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

    private func loadShares(trackLoading: Bool = true) async {
        hasLoadedShares = false
        if trackLoading {
            loadingScopes.insert(.shares)
        }
        defer {
            if trackLoading {
                loadingScopes.remove(.shares)
            }
            hasLoadedShares = true
        }

        guard patient?.resolvedPermission == .write else {
            shares = []
            return
        }

        do {
            shares = try await patientSession.listShares(patientId: patientId)
        } catch let authError as AuthError {
            if !authError.isFatalSessionError {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = "Erro de rede"
        }
    }

    private func loadSurgeries(trackLoading: Bool = true) async {
        hasLoadedSurgeries = false
        if trackLoading {
            loadingScopes.insert(.surgeries)
        }
        defer {
            if trackLoading {
                loadingScopes.remove(.surgeries)
            }
            hasLoadedSurgeries = true
        }

        do {
            surgeries = try await surgerySession.listByPatient(patientId: patientId)
        } catch let authError as AuthError {
            if !authError.isFatalSessionError {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = "Erro de rede"
        }
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
        hasLoadedPatient = false
        hasLoadedShares = false
        hasLoadedSurgeries = false
        loadingScopes = [.patient, .shares, .surgeries]
        await load(trackLoading: false)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadShares(trackLoading: false) }
            group.addTask { await loadSurgeries(trackLoading: false) }
        }
        loadingScopes.removeAll()
    }

    private func ageText(for patient: PatientDTO) -> String {
        guard let birthDate = DateFormatterHelper.parseISODate(patient.dateOfBirth) else {
            return "—"
        }
        return AgeContext.out.ageLongString(from: birthDate)
    }
}

#if DEBUG
#Preview("PatientDetailView - Loading") {
    let authSession = AuthSession()
    let storage = AuthStorage()
    let userSession = UserSession(storage: storage, authSession: authSession)
    authSession.attachUserSession(userSession)
    let patientSession = PatientSession(authSession: authSession, api: PatientAPI())
    let surgerySession = SurgerySession(authSession: authSession, api: SurgeryAPI())
    let anesthesiaSession = AnesthesiaSession(authSession: authSession, api: AnesthesiaAPI())
    let srpaSession = SRPASession(authSession: authSession, api: SRPAAPI())
    let preanesthesiaSession = PreanesthesiaSession(authSession: authSession, api: PreanesthesiaAPI())
    let sharedPreSession = SharedPreAnesthesiaSession(authSession: authSession)

    return NavigationStack {
        PatientDetailView(
            patientId: UUID().uuidString,
            autoLoad: false,
            initialLoading: true
        )
            .environmentObject(patientSession)
            .environmentObject(userSession)
            .environmentObject(surgerySession)
            .environmentObject(anesthesiaSession)
            .environmentObject(srpaSession)
            .environmentObject(preanesthesiaSession)
            .environmentObject(sharedPreSession)
    }
}
#endif
