import SwiftUI
import Combine

struct PatientsListView: View {
    @EnvironmentObject private var patientSession: PatientSession

    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showCreate = false
    @State private var hasLoaded = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

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
                if !isLoading && patientSession.patients.isEmpty {
                    ContentUnavailableView(
                        "Nenhum paciente",
                        systemImage: "person.text.rectangle",
                        description: Text("Crie seu primeiro paciente")
                    )
                }
            }
            .overlay(alignment: .top) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 8)
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
            if !hasLoaded {
                hasLoaded = true
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
        isLoading = true
        errorMessage = nil
        do {
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            try await patientSession.list(search: search.isEmpty ? nil : search)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Erro de rede"
        }
        isLoading = false
    }
}
