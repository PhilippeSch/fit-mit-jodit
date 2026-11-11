import SwiftUI

/// Trainingsverlauf: diese Woche auf einen Blick, darunter alle Trainings nach Tag.
struct HistoryView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let history = app.store.history
        NavigationStack {
            List {
                Section {
                    WeekSummaryView(history: history)
                }
                ForEach(groupedByDay(history), id: \.day) { group in
                    Section {
                        ForEach(group.entries) { e in
                            HistoryRow(entry: e)
                                .swipeActions {
                                    Button(role: .destructive) { app.store.deleteHistory(e) } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text(group.day, format: .dateTime.weekday(.wide).day().month(.wide))
                    }
                }
            }
            .overlay {
                if history.isEmpty {
                    ContentUnavailableView {
                        Label("Noch keine Trainings", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Abgeschlossene Trainings erscheinen hier, abgebrochene ab einer Minute.")
                    }
                    .padding(.top, 160)
                }
            }
            .navigationTitle(Text("Verlauf"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("closeHistory")
                }
            }
        }
    }

    private struct DayGroup { let day: Date; let entries: [HistoryEntry] }

    private func groupedByDay(_ entries: [HistoryEntry]) -> [DayGroup] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: entries) { cal.startOfDay(for: $0.startedAt) }
        return groups.keys.sorted(by: >).map { DayGroup(day: $0, entries: groups[$0] ?? []) }
    }
}

private struct WeekSummaryView: View {
    let history: [HistoryEntry]

    var body: some View {
        let now = Date()
        let week = HistorySummary.week(history, now: now)
        let perDay = HistorySummary.minutesPerDay(history, now: now)
        let maxMinutes = max(perDay.max() ?? 0, 1)
        let symbols = weekdaySymbols()
        VStack(alignment: .leading, spacing: 14) {
            Text("Diese Woche").font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                stat(value: "\(week.count)", label: String(localized: "Trainings"))
                stat(value: "\(Int((Double(week.seconds) / 60).rounded()))", label: String(localized: "Minuten"))
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(perDay[i] > 0 ? Theme.work : Color.secondary.opacity(0.2))
                            .frame(height: max(CGFloat(perDay[i]) / CGFloat(maxMinutes) * 60, 6))
                        Text(symbols[i]).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Minuten pro Tag"))
            .accessibilityValue(Text(zip(symbols, perDay).map { "\($0): \($1)" }.joined(separator: ", ")))
        }
        .padding(.vertical, 6)
        .accessibilityIdentifier("weekSummary")
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Theme.title(.largeTitle, weight: .bold)).monospacedDigit()
            Text(label).font(.subheadline).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    /// Kurze Wochentage ab dem ersten Tag der Woche (z. B. Mo … So).
    private func weekdaySymbols() -> [String] {
        let cal = Calendar.current
        let s = cal.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { s[(cal.firstWeekday - 1 + $0) % 7] }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack {
            Image(systemName: entry.completed ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(entry.completed ? Theme.work : .secondary)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).font(.headline)
                HStack(spacing: 6) {
                    Text(entry.startedAt, format: .dateTime.hour().minute())
                    if !entry.completed { Text("· abgebrochen") }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(DurationFormat.clock(entry.seconds)).font(.body.monospacedDigit())
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("historyRow")
    }
}
