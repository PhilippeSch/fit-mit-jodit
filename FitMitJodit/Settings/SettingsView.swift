import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = app.store
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Image("LogoFMJ").resizable().scaledToFit().frame(height: 120)
                        Image("LogoJodit").resizable().scaledToFit().frame(height: 120)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Theme.ink)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("fitmitjodit"))
                }
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
                    Picker(String(localized: "Sprachansagen"), selection: $store.settings.signals.voiceMode) {
                        Text("Aus").tag(VoiceMode.off)
                        Text("Automatisch").tag(VoiceMode.auto)
                        Text("Immer").tag(VoiceMode.always)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("voiceMode")
                    Text(voiceModeHint(store.settings.signals.voiceMode))
                        .font(.footnote).foregroundStyle(.secondary)
                    if store.settings.signals.voiceMode != .off {
                        Toggle(isOn: $store.settings.signals.voiceDetailed) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ausführliche Ansagen")
                                Text("Mit Dauer, «Bereit machen» und «Noch 10 Sekunden»")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("toggleVoiceDetailed")
                        volume($store.settings.signals.voiceVolume, String(localized: "Lautstärke Ansagen"))
                        Picker(String(localized: "Stimme"), selection: $store.settings.signals.voiceIdentifier) {
                            Text("Automatisch (beste installierte)").tag(String?.none)
                            ForEach(VoiceCatalog.voices(), id: \.identifier) { v in
                                Text("\(v.name) · \(VoiceCatalog.qualityLabel(v.quality))").tag(Optional(v.identifier))
                            }
                        }
                        .accessibilityIdentifier("voicePicker")
                        VoiceStatusCard()
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
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

                Section {
                    JoditPromoCard(compact: true)
                        .listRowInsets(EdgeInsets())
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
            .tint(Theme.work) // Schalter «ein» eindeutig grün
            .accessibilityIdentifier("settingsForm")
            .navigationTitle(Text("Einstellungen"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Fertig")) { dismiss() }
                        .accessibilityIdentifier("closeSettings")
                }
            }
        }
    }

    private func voiceModeHint(_ m: VoiceMode) -> String {
        switch m {
        case .off: return String(localized: "Nur Töne, keine Stimme.")
        case .auto: return String(localized: "Die Stimme sagt Trainings mit Übungsnamen an (z. B. «Kniebeugen, 45 Sekunden»). Trainings ohne Namen, etwa im Kurs, bleiben bei den Tönen.")
        case .always: return String(localized: "Die Stimme sagt jedes Training an, ohne Namen mit «Arbeit» und «Pause».")
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
        case .chime: return String(localized: "Glocke")
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
