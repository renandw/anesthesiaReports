import SwiftUI

struct DateTimePickerSheet: View {
    @Binding var date: Date
    @Binding var isSelected: Bool
    let title: String
    let placeholder: String
    let minDate: Date
    let maxDate: Date

    @State private var showPicker = false
    @State private var draftDate = Date()

    var body: some View {
        Button {
            draftDate = bounded(isSelected ? date : Date())
            showPicker = true
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                if isSelected && minDate <= maxDate {
                    Text(Self.displayFormatter.string(from: date))
                        .foregroundStyle(.tint)
                } else {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                VStack(spacing: 12) {
                    DatePicker(
                        title,
                        selection: $draftDate,
                        in: minDate...maxDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showPicker = false }
                            .tint(.red)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("OK") {
                            date = bounded(draftDate)
                            isSelected = true
                            showPicker = false
                        }
                        .tint(.blue)
                    }
                }
                .padding()
            }
            .presentationDetents([.fraction(0.42)])
        }
    }

    private func bounded(_ value: Date) -> Date {
        min(max(value, minDate), maxDate)
    }

    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.timeZone = .current
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

#if DEBUG
#Preview {
    NavigationStack {
        Form {
            DateTimePickerSheet(
                date: .constant(Date()),
                isSelected: .constant(false),
                title: "Início da anestesia",
                placeholder: "Selecionar",
                minDate: Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? .distantPast,
                maxDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? .distantFuture
            )
        }
    }
}
#endif
