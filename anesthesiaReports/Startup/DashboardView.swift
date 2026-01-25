//
//  DashboardView.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//


import SwiftUI
import SwiftData

struct DashboardView: View {

    @SwiftUI.Environment(AuthSession.self) private var authSession
    @Query private var users: [User]

    private var user: User? {
        users.first
    }

    var body: some View {
        VStack(spacing: 24) {

            if let user {
                VStack(spacing: 12) {
                    Text("Bem-vindo")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text(user.name)
                        .font(.largeTitle)
                        .bold()

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(title: "Email", value: user.emailAddress)
                        infoRow(title: "CRM", value: user.crm)
                        if let rqe = user.rqe, !rqe.isEmpty {
                            infoRow(title: "RQE", value: rqe)
                        }
                    }
                }
            } else {
                ProgressView("Carregando usuário…")
            }

            Spacer()

            Button(role: .destructive) {
                Task {
                    await authSession.logout()
                }
            } label: {
                Text("Logout")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - UI Helpers

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
