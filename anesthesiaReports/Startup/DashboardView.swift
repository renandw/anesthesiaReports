import SwiftUI

struct DashboardView: View {

    @EnvironmentObject private var session: AuthSession
    @EnvironmentObject private var userSession: UserSession
    @EnvironmentObject private var patientSession: PatientSession
    @EnvironmentObject private var surgerySession: SurgerySession
    @EnvironmentObject private var anesthesiaSession: AnesthesiaSession
    @EnvironmentObject private var srpaSession: SRPASession
    @State private var showWizard = false
    @State private var showSRPAWizard = false
    @State private var wizardAnesthesiaResult: WizardAnesthesiaResult?
    @State private var wizardSRPAResult: WizardSRPAResult?

    var body: some View {
        ScrollView {
            if let user = userSession.user {
                VStack{
                    VStack(alignment: .center, spacing: 16) {
                        
                        Text("Bem-vindo, \(user.name)")
                            .font(.headline)
                        
                        Text(user.email)
                            .foregroundColor(.secondary)
                        
                        Text(user.rqe ?? "")
                        
                        NavigationLink("Detalhes do Usuário") {
                            UserDetailsView()
                        }
                        
                        NavigationLink("Lista de Pacientes") {
                            PatientsListView()
                        }
                        
                        Button("Nova Anestesia (Wizard)") {
                            showWizard = true
                        }
                        
                        Button("Nova SRPA (Wizard)") {
                            showSRPAWizard = true
                        }
                        
                        NavigationLink("Editar Usuário") {
                            EditUserView()
                        }
                        
                        
                    }
                    .padding()
                    .background(.white)
                    .navigationTitle("Olá, \(user.name)")
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    Button("Logout") {
                        Task {
                            await session.logout()
                        }
                    }
                    .padding()
                    .buttonStyle(.glassProminent)
                }
            }
            
            
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .sheet(isPresented: $showWizard) {
            NewAnesthesiaWizardView { surgery, anesthesia in
                wizardAnesthesiaResult = WizardAnesthesiaResult(surgery: surgery, anesthesia: anesthesia)
                showWizard = false
            }
        }
        .sheet(isPresented: $showSRPAWizard) {
            NewSRPAWizardView { surgery, srpa in
                wizardSRPAResult = WizardSRPAResult(surgery: surgery, srpa: srpa)
                showSRPAWizard = false
            }
        }
        .sheet(item: $wizardAnesthesiaResult) { result in
            AnesthesiaDetailView(
                surgeryId: result.surgery.id,
                initialSurgery: result.surgery,
                initialAnesthesia: result.anesthesia
            )
            .environmentObject(surgerySession)
            .environmentObject(anesthesiaSession)
            .environmentObject(patientSession)
        }
        .sheet(item: $wizardSRPAResult) { result in
            SRPADetailView(
                surgeryId: result.surgery.id,
                initialSurgery: result.surgery,
                initialSRPA: result.srpa
            )
            .environmentObject(surgerySession)
            .environmentObject(srpaSession)
            .environmentObject(patientSession)
        }
    }
}

private struct WizardAnesthesiaResult: Identifiable {
    let id = UUID()
    let surgery: SurgeryDTO
    let anesthesia: SurgeryAnesthesiaDetailsDTO
}

private struct WizardSRPAResult: Identifiable {
    let id = UUID()
    let surgery: SurgeryDTO
    let srpa: SurgerySRPADetailsDTO
}
