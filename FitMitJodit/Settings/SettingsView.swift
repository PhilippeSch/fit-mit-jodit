import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = app.store
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $store.settings.leadInSeconds, in: 0...30, step: 5) {
                        LabeledContent(String(localized: "Vorlauf"), value: DurationFormat.short(store.settings.leadInSeconds))
                    }
                    .accessibilityIdentifier("leadInStepper")
                } footer: {
                    Text("«Bereit machen» in Blau vor dem ersten Block.")
                }

                Section {
                    Toggle(String(localized: "Töne (letzte 3 Sekunden, Blockwechsel)"), isOn: $store.settings.signals.tonesEnabled)
                        .accessibilityIdentifier("toggleTones")
                    if store.settings.signals.tonesEnabled {
                        volume($store.settings.signals.tonesVolume, String(localized: "Lautstärke Töne"))
                    }
                    Toggle(String(localized: "Signal bei Halbzeit"), isOn: $store.settings.signals.halftimeEnabled)
                        .accessibilityIdentifier("toggleHalftime")
                    if store.settings.signals.halftimeEnabled {
                        volume($store.settings.signals.halftimeVolume, String(localized: "Lautstärke Halbzeit"))
                    }
                    Toggle(String(localized: "Sprachansagen"), isOn: $store.settings.signals.voiceEnabled)
                        .accessibilityIdentifier("toggleVoice")
                    if store.settings.signals.voiceEnabled {
                        volume($store.settings.signals.voiceVolume, String(localized: "Lautstärke Ansagen"))
                    }
                    Picker(String(localized: "Ton-Set"), selection: $store.settings.signals.toneSet) {
                        ForEach(ToneSet.allCases) { t in Text(t.label).tag(t) }
                    }
                    .accessibilityIdentifier("toneSet")
                    Button(String(localized: "Probehören")) {
                        app.signalPlayer?.play(.countdown(1), settings: store.settings.signals)
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.8))
                            app.signalPlayer?.play(.blockStart(.work), settings: store.settings.signals)
                        }
                    }
                } header: {
                    Text("Signale")
                } footer: {
                    Text("Während Ton und Ansage wird Musik aus anderen Apps kurz leiser.")
                }

                Section(String(localized: "Musik daneben")) {
                    SplitViewHintContent()
                }

                Section {
                    Link(String(localized: "Datenschutz"), destination: URL(string: "https://github.com/PhilippeSch/fit-mit-jodit/blob/main/docs/Privacy.md")!)
                    Link(String(localized: "Support"), destination: URL(string: "https://github.com/PhilippeSch/fit-mit-jodit/issues")!)
                    LabeledContent(String(localized: "Version"), value: Bundle.main.versionString)
                }
            }
            .navigationTitle(Text("Einstellungen"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Fertig")) { dismiss() }
                        .accessibilityIdentifier("closeSettings")
                }
            }
        }
    }

    private func volume(_ value: Binding<Double>, _ label: String) -> some View {
        HStack {
            Image(systemName: "speaker.fill").accessibilityHidden(true)
            Slider(value: value, in: 0...1)
                .accessibilityLabel(Text(label))
            Image(systemName: "speaker.wave.3.fill").accessibilityHidden(true)
        }
    }
}

extension ToneSet {
    var label: String {
        switch self {
        case .beeps: return String(localized: "Sportliche Piepser")
        case .boxingBell: return String(localized: "Boxglocke")
        case .softGong: return String(localized: "Sanfter Gong")
        }
    }
}

extension Bundle {
    var versionString: String {
        let v = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }
}

/// Einmaliger Hinweis, wie man Spotify daneben legt.
struct SplitViewHintContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spotify daneben legen", systemImage: "rectangle.split.2x1").font(.headline)
            Text("Auf dem iPad (und dem aufgeklappten iPhone Duo) Fit mit Jodit und Spotify nebeneinander anordnen: über die Fenstersteuerung oben links oder indem du Spotify aus dem Dock neben Fit mit Jodit ziehst. Fit mit Jodit darf schmal sein, der Timer bleibt lesbar.")
                .font(.subheadline)
            Text("Auf dem iPhone läuft Spotify im Hintergrund weiter, die Signale kommen trotzdem.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

struct SplitViewHintSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView { SplitViewHintContent().padding() }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "Verstanden")) { dismiss() }.accessibilityIdentifier("dismissHint")
                    }
                }
        }
        .presentationDetents([.medium])
    }
}
