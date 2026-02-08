import SwiftUI

struct AnesthesiaDetailView: View {
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var anesthesiaSession: AnesthesiaSession
    @EnvironmentObject private var patientSession: PatientSession

    @State private var selectedTab: TabSection = .identification
    @State private var customTitleBarButton: AnyView? = nil
    @State private var surgery: SurgeryDTO?
    @State private var anesthesia: SurgeryAnesthesiaDetailsDTO?
    @State private var patient: PatientDTO?
    @State private var isLoading = false
    @State private var errorMessage: String?

    let surgeryId: String
    let initialSurgery: SurgeryDTO?
    let initialAnesthesia: SurgeryAnesthesiaDetailsDTO?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Picker
                Picker("Seção", selection: $selectedTab) {
                    ForEach(TabSection.allCases, id: \.self) { tab in
                        Image(systemName: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                
                HStack(spacing: 8) {
                    Text(selectedTab.title)
                        .font(.title2).bold()
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    if let button = customTitleBarButton {
                        button
                    } else {
                        Spacer()
                            .frame(width: 32)
                    }
                }
                .frame(minHeight: 44, alignment: .center) // ajuste esse valor à sua UI
                .padding(.horizontal, 16)
                
                Divider()
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentSectionView(
                        section: selectedTab,
                        surgery: $surgery,
                        anesthesia: $anesthesia,
                        patient: $patient,
                        surgeryId: surgeryId
                    )
                    .padding(.horizontal)
                }
                
            }
            .navigationTitle("Ficha Anestésica")
            .navigationBarTitleDisplayMode(.inline)
            .onPreferenceChange(CustomTitleBarButtonPreferenceKey.self) { pref in
                customTitleBarButton = pref?.view
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Ação do relógio
                    }) {
                        Image(systemName: "clock")
                    }
                }
            }
            .task { await loadIfNeeded() }
        }
    }

    private func loadIfNeeded() async {
        if surgery == nil {
            surgery = initialSurgery
        }
        if anesthesia == nil {
            anesthesia = initialAnesthesia
        }

        if surgery == nil {
            isLoading = true
            defer { isLoading = false }
            do {
                surgery = try await surgerySession.getById(surgeryId)
            } catch let authError as AuthError {
                errorMessage = authError.userMessage
                return
            } catch {
                errorMessage = AuthError.network.userMessage
                return
            }
        }

        if anesthesia == nil {
            isLoading = true
            defer { isLoading = false }
            do {
                anesthesia = try await anesthesiaSession.getBySurgery(surgeryId: surgeryId)
            } catch let authError as AuthError {
                if case .notFound = authError {
                    anesthesia = nil
                } else {
                    errorMessage = authError.userMessage
                }
                return
            } catch {
                errorMessage = AuthError.network.userMessage
                return
            }
        }

        if patient == nil, let surgery {
            isLoading = true
            defer { isLoading = false }
            do {
                patient = try await patientSession.getById(surgery.patientId)
            } catch let authError as AuthError {
                errorMessage = authError.userMessage
            } catch {
                errorMessage = AuthError.network.userMessage
            }
        }
    }
}

// MARK: - CustomTitleBarButton

struct CustomTitleBarButtonPreference: Equatable {
    let id: AnyHashable
    let view: AnyView
    let token: AnyHashable
    
    static func == (lhs: CustomTitleBarButtonPreference, rhs: CustomTitleBarButtonPreference) -> Bool {
        lhs.id == rhs.id && lhs.token == rhs.token
    }
}

struct CustomTitleBarButtonPreferenceKey: PreferenceKey {
    static var defaultValue: CustomTitleBarButtonPreference? = nil
    static func reduce(value: inout CustomTitleBarButtonPreference?, nextValue: () -> CustomTitleBarButtonPreference?) {
        if let next = nextValue() {
            value = next
        }
    }
}

// MARK: - Content Section View

struct ContentSectionView: View {
    let section: TabSection
    @Binding var surgery: SurgeryDTO?
    @Binding var anesthesia: SurgeryAnesthesiaDetailsDTO?
    @Binding var patient: PatientDTO?
    let surgeryId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch section {
            case .identification:
                IdentificationView(
                    patient: $patient,
                    surgery: $surgery,
                    anesthesia: $anesthesia
                )
            case .apa:
                PreanesthesiaDetailView(
                    surgeryId: surgeryId,
                    initialPreanesthesia: nil
                )
            case .medications:
                ContentUnavailableView(
                    "Medicações",
                    systemImage: "person.text.rectangle",
                    description: Text("Dados de medicações do paciente quando tivermos uma view apropriada")
                )
            case .vitalSigns:
                ContentUnavailableView(
                    "Sinais Vitais",
                    systemImage: "person.text.rectangle",
                    description: Text("Dados de sinais vitais do paciente quando tivermos uma view apropriada")
                )
            case .description:
                ContentUnavailableView(
                    "Descrição",
                    systemImage: "person.text.rectangle",
                    description: Text("Dados de descrição anestésica do paciente quando tivermos uma view apropriada")
                )
            case .preview:
                ContentUnavailableView(
                    "Visualização",
                    systemImage: "person.text.rectangle",
                    description: Text("Dados de visualização da ficha anestésica do paciente quando tivermos uma view apropriada")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



// MARK: - Tab Section Enum

enum TabSection: CaseIterable {
    case identification
    case apa
    case medications
    case vitalSigns
    case description
    case preview
    
    var title: String {
        switch self {
        case .identification: return "Identificação"
        case .apa: return "A. Pré-Anestésica"
        case .medications: return "Medicações"
        case .vitalSigns: return "Sinais Vitais"
        case .description: return "Descrição"
        case .preview: return "Visualização"
        }
    }
    
    var icon: String {
        switch self {
        case .identification: return "person.text.rectangle"
        case .apa: return "doc.text.magnifyingglass"
        case .medications: return "pills"
        case .vitalSigns: return "waveform.path.ecg"
        case .description: return "square.and.pencil"
        case .preview: return "eye"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnesthesiaDetailView(
            surgeryId: UUID().uuidString,
            initialSurgery: nil,
            initialAnesthesia: nil
        )
        .environmentObject(SurgerySession(authSession: AuthSession(), api: SurgeryAPI()))
        .environmentObject(AnesthesiaSession(authSession: AuthSession(), api: AnesthesiaAPI()))
        .environmentObject(PatientSession(authSession: AuthSession(), api: PatientAPI()))
        .environmentObject(PreanesthesiaSession(authSession: AuthSession(), api: PreanesthesiaAPI()))
        .environmentObject(SharedPreAnesthesiaSession(authSession: AuthSession()))
    }
}
