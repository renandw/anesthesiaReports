import SwiftUI

struct FormDatePickerField: View {

    let title: String

    @Binding var value: String   // ISO: "" = vazio

    var required: Bool = false
    var errorMessage: String? = nil


    // Picker
    @State private var showPicker = false
    @State private var tempDate: Date?


    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            // Label
            HStack {

                Text(title)
                    .font(.subheadline)

                if required {
                    Text("*")
                        .foregroundStyle(.red)
                }
            }


            // Campo clicável
            Button {

                if let parsed = Self.isoFormatter.date(from: value),
                   !value.isEmpty {

                    tempDate = parsed
                } else {
                    tempDate = Date()
                }

                showPicker = true

            } label: {

                HStack {

                    if let date = Self.isoFormatter.date(from: value),
                       !value.isEmpty {

                        Text(Self.displayFormatter.string(from: date))
                            .foregroundStyle(.primary)

                    } else {

                        Text("Selecionar")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)


            // Erro
            if isInvalid, let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }


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
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)

                .toolbar {

                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            showPicker = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {

                        Button("OK") {

                            if let d = tempDate {
                                value = Self.isoFormatter.string(from: d)
                            }

                            showPicker = false
                        }
                    }
                }
                .padding()
            }
            .presentationDetents([.fraction(0.35)])
        }
    }


    // MARK: - Validation

    private var isInvalid: Bool {
        required && value.isEmpty
    }

    private var borderColor: Color {
        isInvalid ? .red : .secondary.opacity(0.4)
    }


    // MARK: - Formatters

    static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .gmt
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .medium
        return f
    }()
}
