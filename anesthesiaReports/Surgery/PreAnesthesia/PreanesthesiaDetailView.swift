import SwiftUI

struct PreanesthesiaDetailView: View {
    @EnvironmentObject private var preanesthesiaSession: PreanesthesiaSession

    private enum LoadingScope: Hashable {
        case preanesthesia
    }

    @State private var preanesthesia: SurgeryPreanesthesiaDetailsDTO?
    @State private var errorMessage: String?
    @State private var activeSheet: PreanesthesiaSheet?
    @State private var loadingScopes: Set<LoadingScope> = []
    @State private var hasLoadedPreanesthesia = false
    @State private var didLoadInitial = false

    let surgeryId: String
    let initialPreanesthesia: SurgeryPreanesthesiaDetailsDTO?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                } else if !hasLoadedPreanesthesia {
                    shimmerState
                } else if let preanesthesia {
                    headerCard(preanesthesia)
                    clearanceCard(preanesthesia)
                    techniquesCard(preanesthesia)
                } else {
                    emptyState
                }
                Spacer()
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .preference(
            key: CustomTitleBarButtonPreferenceKey.self,
            value: CustomTitleBarButtonPreference(
                id: "preanesthesia_button",
                view: AnyView(editButton),
                token: preanesthesia?.preanesthesiaId ?? "new"
            )
        )
        .sheet(item: $activeSheet) { _ in
            NavigationStack{
                PreanesthesiaFormView(
                    surgeryId: surgeryId,
                    initialPreanesthesia: preanesthesia,
                    mode: .standalone,
                    onSaved: { updated in
                        preanesthesia = updated
                        hasLoadedPreanesthesia = true
                    }
                )
            }
        }
        .task(id: surgeryId) { await loadIfNeeded() }
    }

    private var editButton: some View {
        Button {
            activeSheet = .form
        } label: {
            Image(systemName: preanesthesia == nil ? "plus" : "pencil")
        }
        .accessibilityLabel(preanesthesia == nil ? "Criar pré-anestesia" : "Editar pré-anestesia")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Avaliação Pré-Anestésica")
                .font(.title3).bold()
            Text("Ainda não há dados de pré‑anestesia para esta cirurgia.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func headerCard(_ preanesthesia: SurgeryPreanesthesiaDetailsDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ASA")
                    .font(.headline)
                Spacer()
                if let asa = parseASA(preanesthesia.asaRaw) {
                    asa.badgeView
                } else {
                    Text(preanesthesia.asaRaw ?? "—")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func clearanceCard(_ preanesthesia: SurgeryPreanesthesiaDetailsDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Liberação para Procedimento")
                .font(.headline)
            if let clearance = preanesthesia.clearance,
               let status = ClearanceStatus(rawValue: clearance.status) {
                HStack {
                    Text(status.displayName)
                        .font(.subheadline)
                    Spacer()
                }
                if clearance.items.isEmpty {
                    EmptyView()
                } else {
                    ForEach(clearance.items, id: \.self) { item in
                        Text(item.itemValue)
                            .font(.subheadline)
                    }
                }
            } else {
                Text("Sem clearance cadastrado")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func techniquesCard(_ preanesthesia: SurgeryPreanesthesiaDetailsDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Técnicas Anestésicas")
                .font(.headline)
            if preanesthesia.anesthesiaTechniques.isEmpty {
                Text("Nenhuma técnica adicionada")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(preanesthesia.anesthesiaTechniques, id: \.self) { technique in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(techniqueSummary(technique))
                        if let region = technique.regionRaw {
                            Text(regionDisplayName(region))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadIfNeeded() async {
        guard !didLoadInitial else { return }
        didLoadInitial = true
        if preanesthesia == nil { preanesthesia = initialPreanesthesia }
        hasLoadedPreanesthesia = preanesthesia != nil
        guard preanesthesia == nil else { return }
        guard !surgeryId.isEmpty else { return }

        await loadPreanesthesia()
    }

    private func loadPreanesthesia(trackLoading: Bool = true) async {
        hasLoadedPreanesthesia = false
        if trackLoading { loadingScopes.insert(.preanesthesia) }
        defer {
            if trackLoading { loadingScopes.remove(.preanesthesia) }
            hasLoadedPreanesthesia = true
        }
        do {
            preanesthesia = try await preanesthesiaSession.getBySurgery(surgeryId: surgeryId)
        } catch let authError as AuthError {
            if case .notFound = authError {
                preanesthesia = nil
            } else {
                errorMessage = authError.userMessage
            }
        } catch {
            errorMessage = AuthError.network.userMessage
        }
    }

    private func techniqueSummary(_ technique: AnesthesiaTechniqueDTO) -> String {
        let categoryName = categoryDisplayName(technique.categoryRaw)
        let typeName = typeDisplayName(technique.type)
        return "\(categoryName) · \(typeName)"
    }

    private func categoryDisplayName(_ raw: String) -> String {
        AnesthesiaTechniqueCategory(rawValue: raw)?.displayName ?? raw
    }

    private func typeDisplayName(_ raw: String) -> String {
        AnesthesiaTechniqueType(rawValue: raw)?.displayName ?? raw
    }

    private func regionDisplayName(_ raw: String) -> String {
        AnesthesiaTechniqueRegion(rawValue: raw)?.displayName ?? raw
    }

    private func parseASA(_ rawValue: String?) -> ASAClassification? {
        guard let rawValue else { return nil }
        let normalized = rawValue
            .replacingOccurrences(of: "ASA", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLower = normalized.lowercased()

        if let match = ASAClassification.allCases.first(where: { $0.rawValue.lowercased() == normalizedLower }) {
            return match
        }

        let lowered = rawValue.lowercased()
        return ASAClassification.allCases.first(where: { $0.displayName.lowercased() == lowered })
    }

    private var shimmerState: some View {
        VStack(alignment: .leading, spacing: 16) {
            shimmerCard(lines: 2)
            shimmerCard(lines: 3)
            shimmerCard(lines: 3)
        }
    }

    private func shimmerCard(lines: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<lines, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: 16)
                    .shimmering()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private enum PreanesthesiaSheet: String, Identifiable {
    case form

    var id: String { rawValue }
}

#Preview {
    NavigationStack {
        PreanesthesiaDetailView(
            surgeryId: UUID().uuidString,
            initialPreanesthesia: nil
        )
        .environmentObject(PreanesthesiaSession(authSession: AuthSession(), api: PreanesthesiaAPI()))
    }
}
