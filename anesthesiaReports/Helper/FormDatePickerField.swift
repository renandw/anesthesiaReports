import SwiftUI

struct DateOnlyPickerSheetButton: View {

    // ISO: "yyyy-MM-dd" ("" = vazio)
    @Binding var isoDate: String

    var title: String
    var placeholder: String = "Selecionar"

    var minDate: Date? = nil
    var maxDate: Date? = nil

    @State private var showPicker = false
    @State private var tempDate: Date? = nil


    var body: some View {

        Button {

            // String → Date (se existir)
            if let parsed = Self.isoFormatter.date(from: isoDate),
               !isoDate.isEmpty {

                tempDate = parsed

            } else {

                tempDate = Date()
            }

            showPicker = true

        } label: {

            HStack {

                Text(title)

                Spacer()

                if let date = Self.isoFormatter.date(from: isoDate),
                   !isoDate.isEmpty {

                    Text(Self.displayFormatter.string(from: date))
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)

                } else {

                    Text(placeholder)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)


        // Sheet
        .sheet(isPresented: $showPicker) {

            NavigationStack {

                VStack {

                    DatePicker(
                        "",
                        selection: Binding<Date>(
                            get: { tempDate ?? Date() },
                            set: { tempDate = $0 }
                        ),
                        in: (minDate ?? .distantPast)...(maxDate ?? .distantFuture),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "pt_BR"))
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)

                .toolbar {

                    // Cancelar
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            showPicker = false
                        }
                        .tint(.red)
                    }

                    // Confirmar
                    ToolbarItem(placement: .confirmationAction) {

                        Button("OK") {

                            if let confirmed = tempDate {

                                // Date → ISO
                                isoDate = Self.isoFormatter.string(from: confirmed)
                            }

                            showPicker = false
                        }
                        .tint(.blue)
                    }
                }
                .padding()
            }
            .presentationDetents([.fraction(0.35)])
        }
    }


    // MARK: - Formatters

    /// yyyy-MM-dd (ISO seguro)
    static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        //f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()


    /// Exibição amigável
    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .medium
        return f
    }()
}

#Preview {
    @Previewable @State var date: String = "2024-12-15"
    DateOnlyPickerSheetButton(isoDate: $date, title: "Data de Nascimento")
}
