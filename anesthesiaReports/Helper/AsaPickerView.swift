import SwiftUI

struct AsaPickerView: View {
    @Binding var selection: ASAClassification?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(ASAClassification.allCases, id: \.self) { asa in
                Button {
                    selection = asa
                    dismiss()
                } label: {
                    HStack {
                        Text(asa.displayName)
                        Spacer()
                        if selection == asa {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("ASA")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AsaPickerView(selection: .constant(.IIe))
    }
}
#endif
