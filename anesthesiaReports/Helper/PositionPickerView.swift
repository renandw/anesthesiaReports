import SwiftUI

struct PositionPickerView: View {
    @Binding var selection: Positioning?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(Positioning.allCases, id: \.self) { position in
                Button {
                    selection = position
                    dismiss()
                } label: {
                    HStack {
                        Text(position.rawValue)
                        Spacer()
                        if selection == position {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Posicionamento")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PositionPickerView(selection: .constant(.decubitoDorsal))
    }
}
#endif
