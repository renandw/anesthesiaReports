//
//  EditRow.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 28/01/26.
//
import SwiftUI

struct EditRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            TextField(label, text: $value)
                .multilineTextAlignment(.trailing)
            if !value.isEmpty {
                Button {
                    value = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpar \(label)")
            }
        }
    }
}

struct PasswordEditRow: View {
    let label: String
    @Binding var value: String
    @State private var showPassword = false

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.bold)
            Spacer()
            Group {
                if showPassword {
                    TextField(label, text: $value)
                } else {
                    SecureField(label, text: $value)
                }
            }
            .multilineTextAlignment(.trailing)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(showPassword ? .primary : .secondary)
            }
            .buttonStyle(.plain)
        }

    }
}
