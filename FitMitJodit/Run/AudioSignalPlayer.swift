import AVFoundation
import Foundation

/// Erzeugt alle Töne synthetisch (keine fremden Sounddateien) und spielt sie über AVAudioEngine.
/// Musik anderer Apps (z. B. Spotify) wird während Ton und Ansage kurz leiser (Ducking) und kehrt danach zurück.
///
/// Hintergrund: Läuft ein Training, hält die App eine Audiositzung (UIBackgroundModes `audio`) mit
/// einer stillen Spur aktiv, damit Timer und Signale weiterlaufen, wenn Spotify im Vordergrund ist.
/// Begründung und Restrisiko für die App-Prüfung: siehe docs/BERICHT.md.
@MainActor
final class AudioSignalPlayer: NSObject, SignalSink {
    private let engine = AVAudioEngine()
    /// Vier Stimmen für die Töne, reihum belegt: Ein Glockenschlag klingt weiter, während der nächste einsetzt.
    /// Mit nur einer Stimme schnitte jeder Ton den Nachklang des vorherigen ab.
    private let voices = (0..<4).map { _ in AVAudioPlayerNode() }
    private var nextVoice = 0
    private let silence = AVAudioPlayerNode()
    private let speech = AVSpeechSynthesizer()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var cache: [String: AVAudioPCMBuffer] = [:]
    private var keepAliveActive = false
    private var unduckTask: Task<Void, Never>?

    override init() {
        super.init()
        for voice in voices {
            engine.attach(voice)
            engine.connect(voice, to: engine.mainMixerNode, format: format)
        }
        engine.attach(silence)
        engine.connect(silence, to: engine.mainMixerNode, format: format)
        speech.delegate = self
        // Kategorie einmal synchron setzen (mischbar), bevor irgendetwas abgespielt wird.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init)
            MainActor.assumeIsolated {
                if type == .ended, self?.keepAliveActive == true { self?.resumeAudio() }
            }
        }
        // Ändert sich die Audio-Hardware (Kopfhörer, Bluetooth), stoppt die Engine: während eines Trainings neu starten.
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                if self?.keepAliveActive == true { self?.resumeAudio() }
            }
        }
    }

    // MARK: Sitzung

    /// Sitzung auf einer eigenen Warteschlange umstellen: setActive kann blockieren und gehört nicht auf den Haupt-Thread.
    /// Engine und Stille-Spur werden erst danach (wieder auf dem Main-Thread) gestartet.
    private static let sessionQueue = DispatchQueue(label: "ch.fitmitjodit.audiosession")

    private func session(deactivateFirst: Bool, duck: Bool, active: Bool, then: (@MainActor () -> Void)? = nil) {
        Self.sessionQueue.async {
            let s = AVAudioSession.sharedInstance()
            if deactivateFirst { try? s.setActive(false, options: .notifyOthersOnDeactivation) }
            if active {
                var opts: AVAudioSession.CategoryOptions = [.mixWithOthers]
                if duck { opts.insert(.duckOthers) }
                try? s.setCategory(.playback, mode: .default, options: opts)
                try? s.setActive(true)
            }
            if let then { DispatchQueue.main.async { MainActor.assumeIsolated { then() } } }
        }
    }

    private func ensureEngine() {
        if !engine.isRunning {
            engine.prepare()
            try? engine.start()
        }
    }

    private lazy var silenceBuffer: AVAudioPCMBuffer? = {
        let frames = AVAudioFrameCount(format.sampleRate)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)
        buf?.frameLength = frames // Nullen = Stille
        return buf
    }()

    /// Engine und Stille-Spur (wieder) starten; die Stille wird nur einmal eingereiht.
    private func resumeAudio() {
        guard keepAliveActive else { return }
        ensureEngine()
        if !silence.isPlaying, let buf = silenceBuffer {
            silence.stop()
            silence.scheduleBuffer(buf, at: nil, options: .loops)
            silence.volume = 0
            silence.play()
        }
    }

    /// Während eines Trainings aufrufen: hält die App im Hintergrund lebendig. Mehrfache Aufrufe sind harmlos.
    func startKeepAlive() {
        cancelPendingStop()
        guard !keepAliveActive else { return }
        keepAliveActive = true
        session(deactivateFirst: false, duck: false, active: true) { [weak self] in self?.resumeAudio() }
    }

    private var stopTask: Task<Void, Never>?

    private func cancelPendingStop() {
        stopTask?.cancel()
        stopTask = nil
    }

    /// Training beendet: Schlusston und «Geschafft» ausklingen lassen, dann die Sitzung freigeben.
    func finishKeepAlive(after seconds: Double = 3.5) {
        cancelPendingStop()
        stopTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled else { return }
            self.stopKeepAlive()
        }
    }

    /// Sofort stoppen (Training abgebrochen).
    func stopKeepAlive() {
        cancelPendingStop()
        guard keepAliveActive else { return }
        keepAliveActive = false
        unduckTask?.cancel()
        isDucked = false
        silence.stop()
        voices.forEach { $0.stop() }
        toneEnds = .distantPast
        speech.stopSpeaking(at: .immediate)
        engine.stop()
        session(deactivateFirst: true, duck: false, active: false)
    }

    /// Musik anderer Apps ist gerade leiser gestellt.
    private var isDucked = false

    /// Bis wann der zuletzt gestartete Ton noch klingt.
    private var toneEnds = Date.distantPast

    /// Musik leiser stellen und `seconds` nach dem letzten Aufruf wieder freigeben.
    /// Die Sitzung wird nur beim Wechsel umgestellt: Bei 3-2-1 hat das früher jede Sekunde
    /// Sitzung und Engine neu gestartet – Knacksen und Lautstärkesprünge waren die Folge.
    /// Solange noch ein Ton klingt, wird nicht freigegeben (auch nicht nach dem Ende einer Ansage): Beim Freigeben
    /// stellt iOS die Sitzung um, die Engine hält kurz an und schnitte den Nachklang ab.
    private func duckForAWhile(_ seconds: Double) {
        if !isDucked {
            isDucked = true
            session(deactivateFirst: false, duck: true, active: true) { [weak self] in self?.resumeAudio() }
        }
        let wait = max(seconds, toneEnds.timeIntervalSinceNow + 0.4)
        unduckTask?.cancel()
        unduckTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard let self, !Task.isCancelled, !self.speech.isSpeaking else { return }
            self.unduck()
        }
    }

    private func unduck() {
        isDucked = false
        if keepAliveActive {
            // Ohne duckOthers neu aktivieren: andere Musik kehrt auf volle Lautstärke zurück.
            // setActive(false) stoppt die Engine – darum erst danach wieder starten.
            session(deactivateFirst: true, duck: false, active: true) { [weak self] in self?.resumeAudio() }
        } else {
            session(deactivateFirst: true, duck: false, active: false)
        }
    }

    // MARK: SignalSink

    func play(_ kind: SignalKind, settings: SignalSettings) {
        switch kind {
        case .announcement(let text):
            guard settings.voiceEnabled else { return }
            duckForAWhile(2.5)
            let u = AVSpeechUtterance(string: text)
            u.voice = VoiceCatalog.voice(identifier: settings.voiceIdentifier)
            u.volume = Float(settings.voiceVolume)
            // Etwas ruhiger als Standard, mit kurzer Pause davor: wirkt natürlicher und ist im Kurs besser verständlich.
            u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
            u.preUtteranceDelay = 0.05
            speech.speak(u)
        case .halftime:
            guard settings.halftimeEnabled else { return }
            playTone(ToneSynth.halftime(set: settings.toneSet, format: format), key: "half-\(settings.toneSet.rawValue)",
                     volume: settings.halftimeVolume)
        case .countdown, .blockStart, .finished:
            guard settings.tonesEnabled else { return }
            playTone(ToneSynth.buffer(for: kind, set: settings.toneSet, format: format), key: Self.key(kind, settings.toneSet),
                     volume: settings.tonesVolume)
        }
    }

    /// Schlüssel im Zwischenspeicher. 3, 2 und 1 sind derselbe Ton.
    nonisolated static func key(_ kind: SignalKind, _ set: ToneSet) -> String {
        if case .countdown = kind { return "countdown-\(set.rawValue)" }
        return "\(kind)-\(set.rawValue)"
    }

    private var prepared: Set<ToneSet> = []

    /// Töne des gewählten Sets im Hintergrund berechnen (beim Start eines Trainings), damit schon der erste
    /// Schlag pünktlich kommt: Die Glocke mit Hall braucht je Ton einige Millisekunden Rechenzeit.
    func prepare(_ settings: SignalSettings) {
        let set = settings.toneSet
        guard settings.tonesEnabled || settings.halftimeEnabled, !prepared.contains(set) else { return }
        prepared.insert(set)
        Task.detached(priority: .userInitiated) {
            guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }
            let kinds: [SignalKind] = [.countdown(3), .blockStart(.work), .blockStart(.rest), .blockStart(.prep), .finished]
            var made = kinds.map { (Self.key($0, set), ToneBox(ToneSynth.buffer(for: $0, set: set, format: format))) }
            made.append(("half-\(set.rawValue)", ToneBox(ToneSynth.halftime(set: set, format: format))))
            let result = made
            await MainActor.run {
                for (key, box) in result where self.cache[key] == nil { self.cache[key] = box.buffer }
            }
        }
    }

    private func playTone(_ make: @autoclosure () -> AVAudioPCMBuffer?, key: String, volume: Double) {
        let buf: AVAudioPCMBuffer
        if let b = cache[key] { buf = b } else if let b = make() { cache[key] = b; buf = b } else { return }
        let length = Double(buf.frameLength) / format.sampleRate
        toneEnds = max(toneEnds, Date().addingTimeInterval(length))
        // Kurze Töne: bis über den nächsten Countdown-Ton hinaus leise lassen (Abstand 1 s), damit 3-2-1 und
        // Startton eine Phase bilden. Lange Töne: bis sie verklungen sind (siehe `duckForAWhile`).
        duckForAWhile(min(length, 1.0) + 1.2)
        ensureEngine() // Kategorie ist seit dem Start mischbar gesetzt
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.volume = Float(volume)
        voice.scheduleBuffer(buf, at: nil, options: .interrupts)
        if !voice.isPlaying { voice.play() }
    }
}

extension AudioSignalPlayer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.duckForAWhile(0.3) }
    }
}

/// Trägt einen fertig berechneten Ton vom Hintergrund auf den Haupt-Thread (der Puffer wird danach nur gelesen).
private struct ToneBox: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer?
    init(_ buffer: AVAudioPCMBuffer?) { self.buffer = buffer }
}

/// Synthetische Töne. Vier Sets: Glocke, sportliche Piepser, Boxglocke, sanfter Gong.
enum ToneSynth {
    struct Partial { var freq: Double; var amp: Double; var decay: Double }

    /// Spitzenpegel aller Töne. Früher 0.9 (fast Vollaussteuerung): Ein reiner Sinus so laut bringt kleine
    /// Lautsprecher an die Grenze, der Begrenzer von iOS greift hart ein und es klingt verzerrt und schrill.
    static let peakLevel = 0.6

    static func render(_ partials: [Partial], duration: Double, attack: Double = 0.012, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let n = AVAudioFrameCount(duration * sr)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n), let ch = buf.floatChannelData?[0] else { return nil }
        buf.frameLength = n
        let total = partials.reduce(0) { $0 + $1.amp }
        for i in 0..<Int(n) {
            let t = Double(i) / sr
            var v = 0.0
            for p in partials { v += p.amp * sin(2 * .pi * p.freq * t) * exp(-t / p.decay) }
            // Weiche Ein- und Ausblendung (Sinus-Rampen) gegen Knackser am Anfang und Ende.
            let fadeIn = t < attack ? sin(.pi / 2 * t / attack) : 1
            let rest = duration - t
            let fadeOut = rest < 0.02 ? sin(.pi / 2 * max(rest, 0) / 0.02) : 1
            ch[i] = Float(v / max(total, 1) * fadeIn * fadeOut * peakLevel)
        }
        return buf
    }

    static func buffer(for kind: SignalKind, set: ToneSet, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        switch (set, kind) {
        // Piepser klingen ab (statt flachem Dauerton) und haben eine leise Oktave dazu: voller, weniger stechend.
        case (.beeps, .countdown): return beep(880, duration: 0.18, decay: 0.12, format: format)
        case (.beeps, .blockStart(.rest)): return beep(660, duration: 0.5, decay: 0.3, format: format)
        case (.beeps, .blockStart): return beep(1046, duration: 0.5, decay: 0.3, format: format)
        case (.beeps, .finished):
            return concat([beep(1046, duration: 0.18, decay: 0.12, format: format),
                           render([Partial(freq: 0, amp: 0, decay: 1)], duration: 0.08, format: format),
                           beep(1318, duration: 0.6, decay: 0.35, format: format)], format: format)
        // Glocke: drei gleiche Schläge (3-2-1), der Schlusston liegt höher und klingt länger aus. Start einer Übung
        // eine Quinte über dem Countdown, Start einer Pause eine grosse Terz darüber (hörbar ruhiger).
        // Jeder Schlag klingt mit Hall über den nächsten hinaus nach (eigene Stimme je Schlag, siehe `playTone`).
        case (.chime, .countdown):
            return strikes([Strike(at: 0, base: ChimeNote.count, ring: 5.0)], duration: 2.0, fade: 0.7, format: format)
        case (.chime, .blockStart(.rest)):
            return strikes([Strike(at: 0, base: ChimeNote.rest, ring: 7.0)], duration: 2.6, fade: 1.0, format: format)
        case (.chime, .blockStart):
            return strikes([Strike(at: 0, base: ChimeNote.start, ring: 7.0)], duration: 2.6, fade: 1.0, format: format)
        case (.chime, .finished):
            // Grundton, Quinte, Oktave: Jeder Schlag klingt in den nächsten hinein, der letzte klingt aus.
            return strikes([Strike(at: 0, base: ChimeNote.count, ring: 5.0), Strike(at: 0.3, base: ChimeNote.start, ring: 5.0),
                            Strike(at: 0.6, base: ChimeNote.high, ring: 7.0)], duration: 3.3, fade: 1.0, format: format)
        case (.boxingBell, .countdown): return bell(base: 1200, duration: 0.35, format: format)
        case (.boxingBell, .finished):
            return concat([bell(base: 900, duration: 0.5, format: format), bell(base: 900, duration: 0.5, format: format),
                           bell(base: 900, duration: 1.2, format: format)], format: format)
        case (.boxingBell, _): return bell(base: 900, duration: 1.2, format: format)
        case (.softGong, .countdown):
            return render([Partial(freq: 523, amp: 1, decay: 0.2), Partial(freq: 1046, amp: 0.3, decay: 0.15)], duration: 0.4, attack: 0.02, format: format)
        case (.softGong, _): return gong(base: 196, duration: 2.0, format: format)
        default: return nil
        }
    }

    static func halftime(set: ToneSet, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        switch set {
        case .beeps:
            return concat([beep(988, duration: 0.12, decay: 0.1, format: format),
                           render([Partial(freq: 0, amp: 0, decay: 1)], duration: 0.08, format: format),
                           beep(988, duration: 0.12, decay: 0.1, format: format)], format: format)
        // Zwei leichte, hohe Schläge: klar anders als Countdown und Start.
        case .chime:
            return strikes([Strike(at: 0, base: ChimeNote.high, ring: 2.5), Strike(at: 0.2, base: ChimeNote.high, ring: 2.5)],
                           duration: 1.6, fade: 0.6, format: format)
        case .boxingBell: return bell(base: 1500, duration: 0.4, format: format)
        case .softGong: return gong(base: 392, duration: 1.0, format: format)
        }
    }

    /// Piepser: Grundton mit leiser Oktave, klingt ab.
    static func beep(_ freq: Double, duration: Double, decay: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        render([Partial(freq: freq, amp: 1, decay: decay), Partial(freq: freq * 2, amp: 0.15, decay: decay * 0.6)],
               duration: duration, format: format)
    }

    /// Glocke: unharmonische Teiltöne mit raschem Abklingen.
    static func bell(base: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        render([Partial(freq: base, amp: 1, decay: 0.35), Partial(freq: base * 2.76, amp: 0.5, decay: 0.2),
                Partial(freq: base * 5.4, amp: 0.25, decay: 0.12), Partial(freq: base * 8.93, amp: 0.12, decay: 0.08)],
               duration: duration, attack: 0.002, format: format)
    }

    // MARK: Glocke

    /// Schlagtöne des Sets «Glocke» (A-Dur): Countdown a', Start einer Pause cis'', Start einer Übung e'',
    /// Halbzeit und Schluss a''.
    enum ChimeNote {
        static let count = 440.0
        static let rest = 554.37
        static let start = 659.26
        static let high = 880.0
    }

    /// Teiltöne einer gestimmten Glocke: Frequenz im Verhältnis zum Schlagton, Anteil, und Lebensdauer im
    /// Verhältnis zum tiefsten Teilton. Aufbau wie bei einer gegossenen Glocke: Unteroktave, Schlagton, Terz,
    /// Quinte, Oktave, darüber Teiltöne für den Anschlag. Die hohen klingen rasch ab, die tiefen tragen den
    /// Nachklang: Darum tönt es nach Glocke und nicht nach Piepser. Unteroktave, Schlagton und Oktave sind doppelt
    /// und ganz leicht gegeneinander verstimmt: Das Schweben macht den Klang voll und lebendig. Die Terz ist gross
    /// (Dur-Glocke): heller und freundlicher als die Moll-Terz einer Kirchenglocke.
    private static let chimePartials: [(ratio: Double, amp: Double, life: Double)] = [
        (0.5, 0.45, 1.0), (0.5015, 0.2, 0.95), (1.0, 1.0, 0.85), (1.003, 0.3, 0.8), (1.25, 0.35, 0.55),
        (1.5, 0.25, 0.5), (2.0, 0.75, 0.5), (2.006, 0.25, 0.45), (2.5, 0.2, 0.35), (3.0, 0.3, 0.3),
        (4.0, 0.2, 0.2), (5.33, 0.1, 0.12), (6.67, 0.06, 0.08),
    ]

    /// Ein Glockenschlag: Beginn in Sekunden, Schlagton in Hz, `ring` = Zeit, in der der tiefste Teilton von
    /// selbst verklingen würde (60 dB).
    struct Strike { var at: Double; var base: Double; var ring: Double }

    /// Anteil des Halls am Glockenklang (Energie des Nachhalls im Verhältnis zum trockenen Klang).
    /// 1.0 = gleich viel Nachhall wie trockener Klang: grosser Raum. Von Philippe am 12.11.2026 nach Hörproben so
    /// gewählt (0.45 war zu trocken).
    static let chimeHall = 1.0

    /// Glockenschläge übereinandergelegt, mit Hall: Jeder klingt weiter, während der nächste einsetzt. In den
    /// letzten `fade` Sekunden wird der Nachklang ausgeblendet. Das Ergebnis wird auf den Spitzenpegel normiert
    /// (die Summe vieler Teiltöne hat sonst keinen festen Pegel).
    static func strikes(_ list: [Strike], duration: Double, fade: Double, hall: Double = chimeHall,
                        format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let n = Int(duration * sr)
        guard n > 0, let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n)),
              let ch = buf.floatChannelData?[0] else { return nil }
        buf.frameLength = AVAudioFrameCount(n)
        var mix = [Double](repeating: 0, count: n)
        let endLevel = 1.0 / 1024 // Hüllkurve fällt in der Lebensdauer um 60 dB und endet genau bei null
        let attack = 0.006 // weicher Anschlag wie mit einem Filzklöppel
        for s in list {
            let first = Int(s.at * sr)
            for p in chimePartials {
                let life = s.ring * p.life
                let last = min(n, first + Int(life * sr))
                guard first < last else { continue }
                let w = 2 * Double.pi * s.base * p.ratio / sr
                let k = 10 * log(2.0) / (life * sr)
                for i in first..<last {
                    let j = Double(i - first)
                    let t = j / sr
                    let env = (exp(-k * j) - endLevel) / (1 - endLevel)
                    let fadeIn = t < attack ? sin(.pi / 2 * t / attack) : 1
                    mix[i] += p.amp * sin(w * j) * env * fadeIn
                }
            }
        }
        if hall > 0 { mix = withHall(mix, sampleRate: sr, amount: hall) }
        let tail = min(Int(fade * sr), n / 2)
        for i in 0..<tail { mix[n - 1 - i] *= sin(.pi / 2 * Double(i) / Double(tail)) }
        let peak = mix.reduce(0) { max($0, abs($1)) }
        let scale = peak > 0 ? peakLevel / peak : 0
        for i in 0..<n { ch[i] = Float(mix[i] * scale) }
        return buf
    }

    /// Hall eines grossen Raums, selbst gerechnet (keine fremden Dateien): acht parallele Kammfilter mit
    /// Höhendämpfung, dahinter vier Allpässe (Aufbau nach Schroeder und Moorer, wie im frei verfügbaren «Freeverb»).
    /// Der Nachhall setzt 20 ms nach dem Anschlag ein, damit der Schlag selbst klar bleibt, und wird so
    /// zugemischt, dass seine Energie `amount` mal der des trockenen Klangs entspricht.
    static func withHall(_ dry: [Double], sampleRate: Double, amount: Double) -> [Double] {
        let n = dry.count
        let scale = sampleRate / 44_100
        let room = 0.88 // Rückkopplung der Kammfilter: rund 1.7 s Nachhallzeit
        let damp = 0.3 // Höhen klingen im Raum schneller ab als Tiefen
        var wet = [Double](repeating: 0, count: n)
        for length in [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617] {
            var line = [Double](repeating: 0, count: max(1, Int(Double(length) * scale)))
            var pos = 0
            var low = 0.0
            for i in 0..<n {
                let out = line[pos]
                low = out * (1 - damp) + low * damp
                line[pos] = dry[i] + low * room
                pos += 1
                if pos == line.count { pos = 0 }
                wet[i] += out
            }
        }
        for length in [556, 441, 341, 225] {
            var line = [Double](repeating: 0, count: max(1, Int(Double(length) * scale)))
            var pos = 0
            for i in 0..<n {
                let delayed = line[pos]
                line[pos] = wet[i] + delayed * 0.5
                pos += 1
                if pos == line.count { pos = 0 }
                wet[i] = delayed - wet[i]
            }
        }
        func energy(_ x: [Double]) -> Double { x.reduce(0) { $0 + $1 * $1 } }
        let wetEnergy = energy(wet)
        guard wetEnergy > 0 else { return dry }
        let gain = (amount * energy(dry) / wetEnergy).squareRoot()
        let delay = Int(0.02 * sampleRate)
        var out = dry
        if delay < n { for i in delay..<n { out[i] += wet[i - delay] * gain } }
        return out
    }

    static func gong(base: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        render([Partial(freq: base, amp: 1, decay: 0.9), Partial(freq: base * 1.5, amp: 0.4, decay: 0.7),
                Partial(freq: base * 2.0, amp: 0.5, decay: 0.6), Partial(freq: base * 2.98, amp: 0.2, decay: 0.4)],
               duration: duration, attack: 0.03, format: format)
    }

    static func concat(_ parts: [AVAudioPCMBuffer?], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let bufs = parts.compactMap { $0 }
        let n = bufs.reduce(0) { $0 + $1.frameLength }
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n), let dst = out.floatChannelData?[0] else { return nil }
        var off = 0
        for b in bufs {
            guard let src = b.floatChannelData?[0] else { continue }
            for i in 0..<Int(b.frameLength) { dst[off + i] = src[i] }
            off += Int(b.frameLength)
        }
        out.frameLength = n
        return out
    }
}
