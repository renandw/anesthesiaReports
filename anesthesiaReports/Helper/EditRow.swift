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
        }
    }
}
