import SwiftUI

struct DateOnlyPickerSheet: View {
    @Binding var isoDate: String
    let title: String
    let placeholder: String
    let minDate: Date
    let maxDate: Date

    @State private var showPicker = false
    @State private var day = 1
    @State private var month = 1
    @State private var year = 2000

    var body: some View {
        Button {
            seedFromIso()
            showPicker = true
        } label: {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                Spacer()
                if let date = DateFormatterHelper.parseISODate(isoDate), !isoDate.isEmpty {
                    Text(Self.displayFormatter.string(from: date))
                        .foregroundStyle(.tint)
                        //.fontWeight(.semibold)
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
                    HStack(spacing: 12) {
                        Picker("Dia", selection: $day) {
                            ForEach(1...31, id: \.self) { value in
                                Text("\(value)")
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Mês", selection: $month) {
                            ForEach(1...12, id: \.self) { value in
                                Text(Self.monthName(value))
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Ano", selection: $year) {
                            ForEach(yearRange, id: \.self) { value in
                                Text(String(value))
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "pt_BR"))
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
                            if let date = buildDate() {
                                isoDate = DateFormatterHelper.formatISODate(date)
                                showPicker = false
                            }
                        }
                        .tint(.blue)
                    }
                }
                .padding()
            }
            .presentationDetents([.fraction(0.35)])
        }
    }

    private var yearRange: [Int] {
        let min = Calendar.current.component(.year, from: minDate)
        let max = Calendar.current.component(.year, from: maxDate)
        return Array(min...max)
    }

    private func seedFromIso() {
        if let date = DateFormatterHelper.parseISODate(isoDate), !isoDate.isEmpty {
            let calendar = Calendar.current
            day = calendar.component(.day, from: date)
            month = calendar.component(.month, from: date)
            year = calendar.component(.year, from: date)
            return
        }

        let calendar = Calendar.current
        day = calendar.component(.day, from: maxDate)
        month = calendar.component(.month, from: maxDate)
        year = calendar.component(.year, from: maxDate)
    }

    private func buildDate() -> Date? {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.calendar = Calendar.current
        components.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = components.date else { return nil }
        if date < minDate || date > maxDate { return nil }
        return date
    }

    private static func monthName(_ value: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.monthSymbols[value - 1].capitalized
    }

    // MARK: - Formatters

    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateStyle = .medium
        return f
    }()
}

#if DEBUG
#Preview {
    NavigationStack {
        Form {
            DateOnlyPickerSheet(
                isoDate: .constant("2026-01-01"),
                title: "Data de Nascimento",
                placeholder: "Selecionar",
                minDate: Calendar.current.date(byAdding: .year, value: -150, to: Date()) ?? .distantPast,
                maxDate: Date()
            )
        }
        .navigationTitle("Preview")
    }
}
#endif
