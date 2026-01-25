//
//  SessionExpiredView.swift
//  anesthesiaReports
//

import SwiftUI

struct SessionExpiredView: View {

    @Environment(AuthSession.self) private var authSession

    @State private var showLogin = false

    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            Image(systemName: "lock.clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Sessão expirada")
                .font(.title2)
                .fontWeight(.semibold)

            Text("""
Seus dados estão salvos neste dispositivo.

Para continuar sincronizando e editar informações,
é necessário entrar novamente.
""")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {

                Button {
                    showLogin = true
                } label: {
                    Text("Entrar novamente")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    Task {
                        await authSession.logout()
                    }
                } label: {
                    Text("Sair e apagar dados")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

        }
        .padding()
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
    }
}
