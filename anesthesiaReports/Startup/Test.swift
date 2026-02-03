//
//  Test.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 28/01/26.
//

import SwiftUI

struct TestView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo ou Ícone
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.bottom, 40)
                    
                    // Form
                    Form {
                        Section {
                            HStack(spacing: 12){
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.secondary)
                                TextField("Email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                            }
                            HStack(spacing: 12){
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                if isSecured {
                                    SecureField("Senha", text: $password)
                                } else {
                                        TextField("Senha", text: $password)
                                }
                                
                                Button(action: {
                                    isSecured.toggle()
                                }) {
                                    Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Section {
                            Button(action: {
                                // Ação de login
                            }) {
                                Text("Entrar")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color.blue)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .frame(height: 230)
                    
                    // Esqueceu a senha
                    Button(action: {
                        // Ação
                    }) {
                        Text("Esqueceu a senha?")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TestView()
}
