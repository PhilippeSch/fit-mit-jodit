import SwiftUI

/// iPhone als Fernbedienung fürs iPad: zeigt das Training auf dem iPad und hält die Verbindung, solange offen.
struct RemotePadView: View {
    @Environment(\.dismiss) private var dismiss
    let link = RemoteLink.shared

    var body: some View {
        NavigationStack {
            SwiftUI.TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
                VStack(spacing: 20) {
                    HStack {
                        Circle().fill(link.isConnected ? .green : .red).frame(width: 10, height: 10)
                        Text(link.isConnected ? String(localized: "Verbunden mit \(link.peerName ?? "")") : String(localized: "Kein iPad verbunden"))
                            .font(.subheadline)
                    }
                    .accessibilityElement(children: .combine)
                    if let snap = link.remoteSnapshot {
                        let st = snap.state(at: ctx.date)
                        Text(st.step?.displayName ?? "").font(.title.bold())
                        Text(DurationFormat.clock(st.displaySeconds))
                            .font(Theme.countdownFont(size: 96))
                            .foregroundStyle(Theme.color(for: st.step?.kind ?? .prep))
                        if let r = snap.roundText(at: ctx.date) { Text(r).font(.headline) }
                        HStack(spacing: 28) {
                            button("backward.end.fill", String(localized: "Block zurück")) { link.sendCommand(.skipBack) }
                            button(st.isPaused ? "play.fill" : "pause.fill", st.isPaused ? String(localized: "Weiter") : String(localized: "Pause")) {
                                link.sendCommand(.togglePause)
                            }
                            button("forward.end.fill", String(localized: "Block vor")) { link.sendCommand(.skipForward) }
                        }
                        Button(role: .destructive) { link.sendCommand(.stop) } label: { Label("Training auf dem iPad beenden", systemImage: "stop.fill") }
                    } else {
                        ContentUnavailableView(String(localized: "Auf dem iPad läuft kein Training"), systemImage: "ipad",
                                               description: Text("Starte das Training auf dem iPad. Die Uhr steuert es dann über dieses iPhone."))
                    }
                    Spacer()
                    Text("Lass diese Ansicht offen, damit die Apple Watch das iPad steuern kann.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle(Text("iPad steuern"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(String(localized: "Fertig")) { dismiss() } } }
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }

    private func button(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title.bold()).frame(width: 64, height: 64)
                .background(.quaternary, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .disabled(!link.isConnected)
    }
}
