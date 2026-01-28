import SwiftUI

struct RegisterView: View {

    @EnvironmentObject private var session: AuthSession
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var crm = ""
    @State private var rqe = ""
    @State private var phone = ""
    @State private var selectedCompanies: [Company] = []
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                
                // Logo ou Ícone
                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                Form {
                    Section {
                        EditRow(label: "Nome", value: $name)
                        EditRow(label: "CRM", value: $crm)
                        EditRow(label: "RQE", value: $rqe)
                        EditRow(label: "Telefone", value: $phone)
                        
                        NavigationLink {
                            CompanySelectionView(selectedCompanies: $selectedCompanies)
                        } label: {
                            HStack {
                                Text("Empresas")
                                    .fontWeight(.bold)
                                Spacer()
                                if selectedCompanies.displayJoined.isEmpty {
                                    Text("Nenhuma")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(selectedCompanies.displayJoined)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    } header: {
                        HStack {
                            Text("Informações Pessoais")
                            
                        }
                    }
                    Section {
                        HStack {
                            Text("e-mail")
                                .fontWeight(.bold)
                            Spacer()
                            TextField("exemplo@me.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Senha")
                                .fontWeight(.bold)
                            Spacer()
                            SecureField("Senha", text: $password)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        
                    } header: {
                        HStack {
                            Text("Criar Conta")
                        }
                    }
                    Section {
                        Button(action: {
                            Task {
                                errorMessage = nil
                                do {
                                    try await session.register(
                                        RegisterInput(
                                            user_name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                            password: password,
                                            crm_number_uf: crm.trimmingCharacters(in: .whitespacesAndNewlines),
                                            rqe: rqe.isEmpty ? nil : rqe,
                                            phone: phone,
                                            company: selectedCompanies
                                        )
                                    )
                                    dismiss()
                                } catch let authError as AuthError {
                                    errorMessage = authError.userMessage
                                } catch {
                                    errorMessage = "Erro de rede"
                                }
                            }
                        }) {
                            Text("Criar conta")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.blue)
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: 550)
                
                Spacer()
            }
        }
        .navigationTitle("Registrar Novo Usuário")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack{
        RegisterView()
    }
}
