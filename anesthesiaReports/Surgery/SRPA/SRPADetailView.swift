import SwiftUI

struct SRPADetailView: View {
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var srpaSession: SRPASession
    @EnvironmentObject private var patientSession: PatientSession

    @State private var selectedTab: SRPATabSection = .identification
    @State private var customTitleBarButton: AnyView? = nil
    @State private var surgery: SurgeryDTO?
    @State private var srpa: SurgerySRPADetailsDTO?
    @State private var patient: PatientDTO?
    @State private var isLoading = false
    @State private var errorMessage: String?

    let surgeryId: String
    let initialSurgery: SurgeryDTO?
    let initialSRPA: SurgerySRPADetailsDTO?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Seção", selection: $selectedTab) {
                    ForEach(SRPATabSection.allCases, id: \.self) { tab in
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
                .frame(minHeight: 44, alignment: .center)
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
                    SRPAContentSectionView(
                        section: selectedTab,
                        surgery: $surgery,
                        srpa: $srpa,
                        patient: $patient
                    )
                    .padding(.horizontal)
                }
            }
            .navigationTitle("SRPA")
            .navigationBarTitleDisplayMode(.inline)
            .onPreferenceChange(CustomTitleBarButtonPreferenceKey.self) { pref in
                customTitleBarButton = pref?.view
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // ação futura do relógio
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
        if srpa == nil {
            srpa = initialSRPA
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

        if srpa == nil {
            isLoading = true
            defer { isLoading = false }
            do {
                srpa = try await srpaSession.getBySurgery(surgeryId: surgeryId)
            } catch let authError as AuthError {
                if case .notFound = authError {
                    srpa = nil
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

// MARK: - Content Section View

struct SRPAContentSectionView: View {
    let section: SRPATabSection
    @Binding var surgery: SurgeryDTO?
    @Binding var srpa: SurgerySRPADetailsDTO?
    @Binding var patient: PatientDTO?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch section {
            case .identification:
                SRPAIdentificationView(
                    patient: $patient,
                    surgery: $surgery,
                    srpa: $srpa
                )
            case .medications:
                ContentUnavailableView(
                    "Medicações",
                    systemImage: "pills",
                    description: Text("Dados de medicações do paciente quando tivermos uma view apropriada")
                )
            case .vitalSigns:
                ContentUnavailableView(
                    "Sinais Vitais",
                    systemImage: "waveform.path.ecg",
                    description: Text("Dados de sinais vitais do paciente quando tivermos uma view apropriada")
                )
            case .description:
                ContentUnavailableView(
                    "Descrição",
                    systemImage: "square.and.pencil",
                    description: Text("Dados de descrição SRPA quando tivermos uma view apropriada")
                )
            case .preview:
                ContentUnavailableView(
                    "Visualização",
                    systemImage: "eye",
                    description: Text("Visualização do SRPA quando tivermos uma view apropriada")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Tab Section Enum

enum SRPATabSection: CaseIterable {
    case identification
    case medications
    case vitalSigns
    case description
    case preview

    var title: String {
        switch self {
        case .identification: return "Identificação"
        case .medications: return "Medicações"
        case .vitalSigns: return "Sinais Vitais"
        case .description: return "Descrição"
        case .preview: return "Visualização"
        }
    }

    var icon: String {
        switch self {
        case .identification: return "person.text.rectangle"
        case .medications: return "pills"
        case .vitalSigns: return "waveform.path.ecg"
        case .description: return "square.and.pencil"
        case .preview: return "eye"
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SRPADetailView(
            surgeryId: UUID().uuidString,
            initialSurgery: nil,
            initialSRPA: nil
        )
        .environmentObject(SurgerySession(authSession: AuthSession(), api: SurgeryAPI()))
        .environmentObject(SRPASession(authSession: AuthSession(), api: SRPAAPI()))
        .environmentObject(PatientSession(authSession: AuthSession(), api: PatientAPI()))
    }
}
#endif
