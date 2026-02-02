import SwiftUI

struct CanShareSurgeryWithView: View {

    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @Environment(\.dismiss) private var dismiss

    @State private var users: [RelatedUserDTO] = []
    @State private var searchText = ""
    @State private var companyFilter: String = "all"
    @State private var shares: [SurgeryShareDTO] = []
    @State private var isLoadingUsers = false
    @State private var isLoadingShares = false
    @State private var updatingUserIds: Set<String> = []
    @State private var shakeTokens: [String: Int] = [:]
    @State private var hasLoaded = false
    @State private var hasLoadError = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    let surgeryId: String
    let createdById: String
    let patientId: String

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)

                    Text("Compartilhar Cirurgia")
                        .font(.headline)

                    Text("Selecione um colega para compartilhar esta cirurgia")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack {
                    Picker("Empresa", selection: $companyFilter) {
                        Text("Todas").tag("all")
                        ForEach(KnownCompany.allCases, id: \.rawValue) { company in
                            Text(company.displayName).tag(company.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()

                Group {
                    if (isLoadingUsers || isLoadingShares) && users.isEmpty {
                        List(0..<6, id: \.self) { _ in
                            UserShareRowPlaceholder()
                        }
                        .listStyle(.plain)
                        .redacted(reason: .placeholder)
                        .shimmering()
                    } else if hasLoadError {
                        List {
                            ContentUnavailableView(
                                "Erro ao carregar usuários",
                                systemImage: "exclamationmark.triangle",
                                description: Text(errorMessage ?? "Tente novamente mais tarde")
                            )
                        }
                    } else if users.isEmpty && !isLoadingUsers {
                        List {
                            ContentUnavailableView(
                                "Nenhum usuário encontrado",
                                systemImage: "person.2.slash",
                                description: Text("Tente ajustar os filtros de busca")
                            )
                        }
                    } else {
                        List(users) { user in
                            let share = shareFor(userId: user.id)
                            SurgeryShareRow(
                                user: user,
                                share: share,
                                isUpdating: updatingUserIds.contains(user.id),
                                shakeToken: shakeTokens[user.id, default: 0],
                                isOwner: user.id == createdById,
                                onSelect: { newPermission in
                                    Task { await updatePermission(for: user, to: newPermission) }
                                },
                                onRevokeRequested: {
                                    Task { await revoke(userId: user.id) }
                                }
                            )
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark") { dismiss() }
                }
            }
            .navigationTitle("Compartilhar Cirurgia")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar por nome")
            .onChange(of: searchText) { _, _ in
                scheduleSearch()
            }
            .onChange(of: companyFilter) { _, _ in
                scheduleSearch()
            }
            .task {
                if !hasLoaded {
                    hasLoaded = true
                    await reloadAll()
                }
            }
            .refreshable { await reloadAll() }
        }
    }

    private func loadUsers() async {
        hasLoadError = false
        errorMessage = nil
        isLoadingUsers = true
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let company = companyFilter == "all" ? nil : companyFilter
        do {
            users = try await userSession.fetchRelatedUsers(
                company: company,
                search: search.isEmpty ? nil : search
            )
        } catch let authError as AuthError {
            if authError.isFatalSessionError {
                return
            }
            errorMessage = authError.userMessage
            hasLoadError = true
        } catch {
            errorMessage = "Erro de rede"
            hasLoadError = true
        }
        isLoadingUsers = false
    }

    private func share(with user: RelatedUserDTO, permission: String) async {
        updatingUserIds.insert(user.id)
        do {
            try await surgerySession.share(
                surgeryId: surgeryId,
                input: ShareSurgeryInput(
                    user_id: user.id,
                    permission: permission
                )
            )
            await loadShares()
        } catch let authError as AuthError {
            if authError.isFatalSessionError {
                return
            }
            errorMessage = authError.userMessage
            triggerShake(for: user.id)
        } catch {
            errorMessage = "Erro de rede"
            triggerShake(for: user.id)
        }
        updatingUserIds.remove(user.id)
    }

    private func loadShares() async {
        errorMessage = nil
        isLoadingShares = true
        do {
            shares = try await surgerySession.listShares(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if authError.isFatalSessionError {
                return
            }
            errorMessage = authError.userMessage
            hasLoadError = true
        } catch {
            errorMessage = "Erro de rede"
            hasLoadError = true
        }
        isLoadingShares = false
    }

    private func shareFor(userId: String) -> SurgeryShareDTO? {
        shares.first(where: { $0.userId == userId })
    }

    private func revoke(userId: String) async {
        updatingUserIds.insert(userId)
        do {
            try await surgerySession.revoke(surgeryId: surgeryId, userId: userId)
            await loadShares()
        } catch let authError as AuthError {
            if authError.isFatalSessionError {
                return
            }
            errorMessage = authError.userMessage
            triggerShake(for: userId)
        } catch {
            errorMessage = "Erro de rede"
            triggerShake(for: userId)
        }
        updatingUserIds.remove(userId)
    }

    private func updatePermission(for user: RelatedUserDTO, to permission: String) async {
        if permission == "none" { return }
        await share(with: user, permission: permission)
    }

    private func triggerShake(for userId: String) {
        shakeTokens[userId, default: 0] += 1
    }

    private func reloadAll() async {
        async let usersTask: Void = loadUsers()
        async let sharesTask: Void = loadShares()
        await usersTask
        await sharesTask
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled {
                await loadUsers()
            }
        }
    }
}

private struct SurgeryShareRow: View {
    let user: RelatedUserDTO
    let share: SurgeryShareDTO?
    let isUpdating: Bool
    let shakeToken: Int
    let isOwner: Bool
    let onSelect: (String) -> Void
    let onRevokeRequested: () -> Void

    @State private var showRevokeAlert = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isShared ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(initials(from: user.name))
                        .font(.headline.bold())
                        .foregroundStyle(isShared ? .green : .blue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Text("CRM:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(user.crm)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let rqe = user.rqe, !rqe.isEmpty {
                        HStack {
                            Text("RQE:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rqe)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            if isOwner {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Criador da cirurgia")
            } else {
                Menu {
                    Button {
                        onSelect("read")
                    } label: {
                        Label("Leitura", systemImage: "eye")
                    }
                    Button {
                        onSelect("pre_editor")
                    } label: {
                        Label("Pré‑anestesia", systemImage: "stethoscope")
                    }
                    Button {
                        onSelect("ane_editor")
                    } label: {
                        Label("Anestesia", systemImage: "syringe")
                    }
                    Button {
                        onSelect("srpa_editor")
                    } label: {
                        Label("SRPA", systemImage: "bed.double")
                    }
                    Button {
                        onSelect("full_editor")
                    } label: {
                        Label("Editor completo", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        if isShared {
                            showRevokeAlert = true
                        }
                    } label: {
                        Label("Sem Permissão", systemImage: "nosign")
                    }
                } label: {
                    SurgeryPermissionBadgeView(permission: currentPermission, isUpdating: isUpdating)
                }
            }
        }
        .modifier(ShakeEffect(trigger: shakeToken))
        .alert("Remover permissão?", isPresented: $showRevokeAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Confirmar", role: .destructive) {
                onRevokeRequested()
            }
        } message: {
            Text("O usuário não mais poderá ter acesso a essa cirurgia.")
        }
    }

    private var isShared: Bool {
        share != nil
    }

    private var currentPermission: SurgeryPermission {
        share?.resolvedPermission ?? .unknown
    }

    private func initials(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "" }
        if parts.count == 1 {
            if let firstChar = parts[0].first {
                return String(firstChar).uppercased()
            } else {
                return ""
            }
        } else {
            let firstPart = parts.first!
            let lastPart = parts.last!
            let firstInitial = firstPart.first.map { String($0) } ?? ""
            let lastInitial = lastPart.first.map { String($0) } ?? ""
            return (firstInitial + lastInitial).uppercased()
        }
    }
}

private struct UserShareRowPlaceholder: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 110, height: 12)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 28, height: 20)
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var trigger: Int
    var amplitude: CGFloat = 6
    var shakesPerUnit: CGFloat = 3

    var animatableData: CGFloat {
        get { CGFloat(trigger) }
        set { }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amplitude * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}

#if DEBUG
#Preview {
    let authSession = AuthSession()
    let storage = AuthStorage()
    let userSession = UserSession(storage: storage, authSession: authSession)
    authSession.attachUserSession(userSession)
    let surgerySession = SurgerySession(authSession: authSession, api: SurgeryAPI())

    return NavigationStack {
        CanShareSurgeryWithView(
            surgeryId: UUID().uuidString,
            createdById: UUID().uuidString,
            patientId: UUID().uuidString
        )
        .environmentObject(userSession)
        .environmentObject(surgerySession)
    }
}
#endif
