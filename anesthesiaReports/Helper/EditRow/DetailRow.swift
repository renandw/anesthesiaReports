//
//  DetailRow.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 04/02/26.
//
import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}
