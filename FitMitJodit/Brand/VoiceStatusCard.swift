import AVFoundation
import SwiftUI

/// Zeigt, welche Stimme spricht. Gibt es nur die einfache Standardstimme (klingt robotisch),
/// erklärt die Karte, wie man eine Premium-Stimme lädt. iOS erlaubt Apps nicht, Stimmen selbst zu laden.
struct VoiceStatusCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // Die Liste lädt im Hintergrund (siehe `VoiceLibrary`); die Karte baut sich neu auf, sobald sie da ist.
        let loaded = VoiceLibrary.shared.isLoaded
        let best = VoiceCatalog.voices().first
        let basic = VoiceCatalog.onlyBasicVoices
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: basic ? "exclamationmark.bubble.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(basic ? Theme.rest : Theme.work, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    if !loaded {
                        Text("Stimme wird geprüft …").font(.headline)
                    } else if basic {
                        Text("Für natürliche Ansagen eine Premium-Stimme laden").font(.headline)
                        Text("Auf diesem Gerät ist nur die einfache Stimme installiert, sie klingt robotisch. So lädst du eine bessere (einmalig, gratis):")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else if let best {
                        Text("Ansagen mit «\(best.name)»").font(.headline)
                        Text("Die beste installierte Stimme (\(VoiceCatalog.qualityLabel(best.quality))) wird automatisch verwendet. Wechseln kannst du sie in den Einstellungen unter «Stimme».")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            if basic {
                VStack(alignment: .leading, spacing: 6) {
                    step(1, String(localized: "iOS-Einstellungen › Bedienungshilfen › Lesen & Sprechen › Stimmen."))
                    step(2, VoiceCatalog.appLanguage == "de" ? String(localized: "«Deutsch» wählen und eine Stimme mit «Premium» laden, z. B. «Anna (Premium)».")
                                                         : String(localized: "«English» wählen und eine Stimme mit «Premium» laden, z. B. «Ava (Premium)»."))
                    step(3, String(localized: "Zurück in die App: Die neue Stimme wird automatisch verwendet."))
                }
            }
            Button {
                var s = app.store.settings.signals
                s.voiceMode = .always
                let name = ExerciseCatalog.all.first { $0.id == "squats" }.map { ExerciseCatalog.localizedName($0) }
                app.signalPlayer?.play(.announcement(Announcements.getReady(next: Step(kind: .work, seconds: 45, exerciseName: name))), settings: s)
            } label: {
                Label(String(localized: "Stimme probehören"), systemImage: "play.circle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("welcomeVoiceSample")
        }
        .padding(16)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        // Neu prüfen, wenn man aus den iOS-Einstellungen zurückkommt oder iOS neue Stimmen meldet.
        .onChange(of: scenePhase) { _, p in if p == .active { VoiceLibrary.shared.reload() } }
        .onReceive(NotificationCenter.default.publisher(for: AVSpeechSynthesizer.availableVoicesDidChangeNotification)) { _ in VoiceLibrary.shared.reload() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("voiceStatusCard")
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(verbatim: "\(n).").font(.subheadline.bold().monospacedDigit())
            Text(text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
    }
}
