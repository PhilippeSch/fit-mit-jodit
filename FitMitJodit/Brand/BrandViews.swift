import SwiftUI

/// Links und Texte rund um Jodit. Fotos liegen als austauschbare Assets vor
/// («PhotoWelcome», «PhotoGroup»; vorläufig von fitmitjodit.ch, Originale folgen).
enum JoditBrand {
    static let website = URL(string: "https://fitmitjodit.ch")!
    static let groupFitness = URL(string: "https://fitmitjodit.ch/Group-Fitness/")!
}

/// Willkommensbildschirm beim ersten Start.
struct WelcomeView: View {
    let onDone: () -> Void
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image("PhotoWelcome")
                        .resizable()
                        .scaledToFill()
                        // Oben ausrichten: bei breiten Fenstern (Querformat) wird unten beschnitten, der Kopf bleibt sichtbar.
                        .frame(width: geo.size.width, height: min(geo.size.height * 0.42, 420), alignment: .top)
                        .clipped()
                        .overlay(alignment: .bottom) {
                            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                                .frame(height: 140)
                                .allowsHitTesting(false)
                        }
                        .overlay(alignment: .bottomLeading) {
                            Image("LogoFMJ").resizable().scaledToFit().frame(height: 84)
                                .padding(18)
                                .accessibilityHidden(true)
                        }
                        .accessibilityLabel(Text("Jodit beim Training"))
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Willkommen bei Fit mit Jodit")
                            .font(Theme.title(.largeTitle, weight: .heavy))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("welcomeTitle")
                        Text("Der Intervall-Timer von Jodit – für die Kurse und für dein Training zu Hause.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        feature("square.stack.3d.up.fill", Theme.work, String(localized: "Bausteine antippen, markieren und «mal N» für Runden."))
                        feature("speaker.wave.2.fill", Theme.brand, String(localized: "Fertige Trainings mit Ansage: Die Stimme sagt, welche Übung kommt und wie lange."))
                        feature("timer", Theme.rest, String(localized: "Arbeit grün, Pause orange, Vorbereitung blau – gut lesbar aus mehreren Metern."))
                        feature("applewatch", Theme.prep, String(localized: "Mit der Apple Watch steuern, Musik läuft in Spotify weiter."))
                        if hSize == .regular {
                            feature("rectangle.split.2x1", .gray, String(localized: "Auf dem iPad passt Spotify daneben, der Timer bleibt lesbar."))
                        }
                        VoiceStatusCard()
                            .padding(.top, 4)
                        Button(action: onDone) {
                            Text("Los geht's")
                                .font(.title3.bold())
                                .foregroundStyle(Theme.onBrand)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                        .accessibilityIdentifier("welcomeStart")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 640, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .tint(Theme.brand)
    }

    private func feature(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                // Auf der Markenfarbe (im dunklen Modus hell) braucht das Symbol die passende Gegenfarbe.
                .foregroundStyle(color == Theme.brand ? Theme.onBrand : .white)
                .frame(width: 40, height: 40)
                .background(color, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(text).font(.body).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Werbung für Jodits Trainings: auf dem Abschlussbild und in den Einstellungen.
struct JoditPromoCard: View {
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("PhotoGroup")
                .resizable()
                .scaledToFill()
                .frame(height: compact ? 120 : 180)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityLabel(Text("Group Fitness mit Jodit"))
            VStack(alignment: .leading, spacing: 8) {
                Text("Trainiere mit Jodit")
                    .font(Theme.title(.title2))
                Text("Group Fitness, Personal Training, Reformer Training und Schmerzcoaching in Bülach und Rafz.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Link(destination: JoditBrand.website) {
                    Label(String(localized: "Zu fitmitjodit.ch"), systemImage: "arrow.up.right.square")
                        .font(.headline)
                        .foregroundStyle(Theme.onBrand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.brand)
                .accessibilityIdentifier("promoLink")
            }
            .padding(16)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        // `Color.primary` statt `.primary`: Die Kurzform bezieht sich auf die geerbte Vordergrundfarbe, und die ist auf
        // dem Abschlussbild weiss. Der Text der Karte war dort weiss auf weiss.
        .foregroundStyle(Color.primary)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("promoCard")
    }
}
