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
                .fontWeight(.bold)
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
