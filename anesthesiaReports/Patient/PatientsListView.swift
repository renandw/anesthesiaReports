import SwiftUI

struct PatientsListView: View {
    private enum LoadingScope: Hashable {
        case patients
    }

    @EnvironmentObject private var patientSession: PatientSession

    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var showCreate = false
    @State private var hasLoadedPatients = false
    @State private var loadingScopes: Set<LoadingScope> = []
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if !hasLoadedPatients || loadingScopes.contains(.patients) {
                List {
                    ForEach(0..<6, id: \.self) { _ in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 180, height: 16)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 220, height: 12)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 140, height: 12)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 44, height: 20)
                        }
                        .redacted(reason: .placeholder)
                        .shimmering()
                        .padding(.vertical, 6)
                    }
                }
            } else {
                List(patientSession.patients) { patient in
                    NavigationLink {
                        PatientDetailView(patientId: patient.id)
                            .environmentObject(patientSession)
                    } label: {
                        PatientRowView(
                            patient: patient,
                            numberCnsContext: .notNeeded,
                            ageContext: .out,
                            role: patient.resolvedRole
                        )
                    }
                }
                .overlay {
                    if patientSession.patients.isEmpty {
                        ContentUnavailableView(
                            "Nenhum paciente",
                            systemImage: "person.text.rectangle",
                            description: Text("Crie seu primeiro paciente")
                        )
                    }
                }
            }
        }
        .navigationTitle("Pacientes")
        .searchable(text: $searchText, prompt: "Buscar paciente")
        .onChange(of: searchText) { _, _ in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                if !Task.isCancelled {
                    await load()
                }
            }
        }
        .toolbar {
            Button {
                showCreate = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Novo")
                }
            }
        }
        .task {
            if !hasLoadedPatients {
                await load()
            }
        }
        .refreshable { await load() }
        .sheet(isPresented: $showCreate) {
            PatientFormView(mode: .standalone, existing: nil, onComplete: { _ in
                Task { await load() }
            })
            .environmentObject(patientSession)
        }
    }

    private func load() async {
        hasLoadedPatients = false
        loadingScopes.insert(.patients)
        defer {
            loadingScopes.remove(.patients)
            hasLoadedPatients = true
        }
        errorMessage = nil
        do {
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            try await patientSession.list(search: search.isEmpty ? nil : search)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
    }
}

#if DEBUG
#Preview("PatientsListView - Loading") {
    let authSession = AuthSession()
    let patientSession = PatientSession(authSession: authSession, api: PatientAPI())

    return NavigationStack {
        PatientsListView()
            .environmentObject(patientSession)
    }
}
#endif
