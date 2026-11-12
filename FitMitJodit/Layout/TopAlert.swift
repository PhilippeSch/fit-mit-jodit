import UIKit

/// Rückfragen, die jederzeit kommen können (Fernbedienung erlauben, Import bestätigen), zeigt die App in einem
/// eigenen Fenster über allem anderen.
///
/// Als SwiftUI-Alarm an der Wurzel stritten sie mit den Vollbild-Darstellungen (Willkommen, Laufansicht): Kam die
/// Anfrage des iPhone, während auf dem iPad der Willkommensbildschirm stand, schloss sich dieser von selbst, die
/// Anfrage ging verloren, und ein danach gestartetes Training lief ohne sichtbare Laufansicht. Auch ein Alarm über
/// der obersten Ansicht desselben Fensters blockierte noch, was gleichzeitig aufgehen wollte. Im eigenen Fenster
/// hängt die Rückfrage an nichts, was die App sonst darstellt: Darunter kann aufgehen und zugehen, was will.
@MainActor
enum TopAlert {
    struct Action {
        var title: String
        var style: UIAlertAction.Style = .default
        var handler: () -> Void = {}
    }

    private struct Request {
        var title: String
        var message: String?
        var actions: [Action]
    }

    /// Wartende Rückfragen: immer nur eine gleichzeitig, in der Reihenfolge ihres Eintreffens.
    private static var pending: [Request] = []
    private static var window: UIWindow?

    static func present(title: String, message: String?, actions: [Action]) {
        pending.append(Request(title: title, message: message, actions: actions))
        showNext()
    }

    private static func showNext(attempt: Int = 0) {
        guard window == nil, let next = pending.first else { return }
        guard let scene = activeScene() else {
            // Noch kein Fenster (ganz früh beim Start): kurz warten. Kommt keines, gilt die abbrechende Antwort.
            guard attempt < 40 else {
                pending.removeFirst()
                next.actions.first { $0.style == .cancel }?.handler()
                showNext()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showNext(attempt: attempt + 1) }
            return
        }
        pending.removeFirst()

        let host = UIViewController()
        host.view.backgroundColor = .clear
        let w = UIWindow(windowScene: scene)
        w.windowLevel = .alert + 1
        w.backgroundColor = .clear
        w.rootViewController = host
        w.isHidden = false
        window = w

        let alert = UIAlertController(title: next.title, message: next.message, preferredStyle: .alert)
        for a in next.actions {
            // Bewusst ohne eigene Kennung: Sie erscheint in der Bedienungshilfen-Struktur doppelt (Knopf im Knopf),
            // Tests finden die Knöpfe über ihre Beschriftung.
            alert.addAction(UIAlertAction(title: a.title, style: a.style) { _ in
                a.handler()
                finish()
            })
        }
        host.present(alert, animated: true)
    }

    /// Rückfrage beantwortet: Fenster wieder entfernen, die nächste wartende zeigen.
    private static func finish() {
        window?.isHidden = true
        window = nil
        showNext()
    }

    private static func activeScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first { $0.activationState == .foregroundInactive }
    }
}
