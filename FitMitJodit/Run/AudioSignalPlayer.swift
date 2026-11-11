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
    private let player = AVAudioPlayerNode()
    private let silence = AVAudioPlayerNode()
    private let speech = AVSpeechSynthesizer()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var cache: [String: AVAudioPCMBuffer] = [:]
    private var keepAliveActive = false
    private var unduckTask: Task<Void, Never>?

    override init() {
        super.init()
        engine.attach(player)
        engine.attach(silence)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.connect(silence, to: engine.mainMixerNode, format: format)
        speech.delegate = self
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init)
            MainActor.assumeIsolated {
                if type == .ended, self?.keepAliveActive == true { self?.startKeepAlive() }
            }
        }
    }

    // MARK: Sitzung

    /// Sitzung auf einer eigenen Warteschlange umstellen: setActive kann blockieren und gehört nicht auf den Haupt-Thread.
    private static let sessionQueue = DispatchQueue(label: "ch.fitmitjodit.audiosession")

    private func configure(duck: Bool, then: (@Sendable () -> Void)? = nil) {
        Self.sessionQueue.async {
            let s = AVAudioSession.sharedInstance()
            var opts: AVAudioSession.CategoryOptions = [.mixWithOthers]
            if duck { opts.insert(.duckOthers) }
            try? s.setCategory(.playback, mode: .default, options: opts)
            try? s.setActive(true)
            then?()
        }
    }

    private func deactivate(thenReconfigure: Bool) {
        Self.sessionQueue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            if thenReconfigure {
                let s = AVAudioSession.sharedInstance()
                try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try? s.setActive(true)
            }
        }
    }

    private func ensureEngine() {
        if !engine.isRunning {
            engine.prepare()
            try? engine.start()
        }
    }

    /// Während eines Trainings aufrufen: hält die App im Hintergrund lebendig.
    func startKeepAlive() {
        keepAliveActive = true
        configure(duck: false)
        ensureEngine()
        let frames = AVAudioFrameCount(format.sampleRate)
        if let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) {
            buf.frameLength = frames // Nullen = Stille
            silence.scheduleBuffer(buf, at: nil, options: .loops)
            silence.volume = 0
            silence.play()
        }
    }

    func stopKeepAlive() {
        keepAliveActive = false
        silence.stop()
        player.stop()
        speech.stopSpeaking(at: .immediate)
        engine.stop()
        deactivate(thenReconfigure: false)
    }

    private func duckForAWhile(_ seconds: Double) {
        configure(duck: true)
        unduckTask?.cancel()
        unduckTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled, !self.speech.isSpeaking else { return }
            self.unduck()
        }
    }

    private func unduck() {
        if keepAliveActive {
            // Ohne duckOthers neu aktivieren: andere Musik kehrt auf volle Lautstärke zurück.
            deactivate(thenReconfigure: true)
            ensureEngine()
            if !silence.isPlaying { silence.play() }
        } else {
            deactivate(thenReconfigure: false)
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
            let key = "\(kind)-\(settings.toneSet.rawValue)"
            playTone(ToneSynth.buffer(for: kind, set: settings.toneSet, format: format), key: key, volume: settings.tonesVolume)
        }
    }

    private func playTone(_ make: @autoclosure () -> AVAudioPCMBuffer?, key: String, volume: Double) {
        let buf: AVAudioPCMBuffer
        if let b = cache[key] { buf = b } else if let b = make() { cache[key] = b; buf = b } else { return }
        duckForAWhile(Double(buf.frameLength) / format.sampleRate + 0.4)
        ensureEngine()
        player.volume = Float(volume)
        player.scheduleBuffer(buf, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }
}

extension AudioSignalPlayer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.duckForAWhile(0.3) }
    }
}

/// Synthetische Töne. Drei Sets: sportliche Piepser, Boxglocke, sanfter Gong.
enum ToneSynth {
    struct Partial { var freq: Double; var amp: Double; var decay: Double }

    static func render(_ partials: [Partial], duration: Double, attack: Double = 0.005, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let n = AVAudioFrameCount(duration * sr)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n), let ch = buf.floatChannelData?[0] else { return nil }
        buf.frameLength = n
        let total = partials.reduce(0) { $0 + $1.amp }
        for i in 0..<Int(n) {
            let t = Double(i) / sr
            var v = 0.0
            for p in partials { v += p.amp * sin(2 * .pi * p.freq * t) * exp(-t / p.decay) }
            let env = min(t / attack, 1) * min((duration - t) / 0.01, 1)
            ch[i] = Float(v / max(total, 1) * env * 0.9)
        }
        return buf
    }

    static func buffer(for kind: SignalKind, set: ToneSet, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        switch (set, kind) {
        case (.beeps, .countdown): return render([Partial(freq: 880, amp: 1, decay: 10)], duration: 0.15, format: format)
        case (.beeps, .blockStart(.rest)): return render([Partial(freq: 660, amp: 1, decay: 10)], duration: 0.5, format: format)
        case (.beeps, .blockStart): return render([Partial(freq: 1320, amp: 1, decay: 10)], duration: 0.5, format: format)
        case (.beeps, .finished):
            return concat([render([Partial(freq: 1320, amp: 1, decay: 10)], duration: 0.18, format: format),
                           render([Partial(freq: 0, amp: 0, decay: 1)], duration: 0.08, format: format),
                           render([Partial(freq: 1760, amp: 1, decay: 10)], duration: 0.6, format: format)], format: format)
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
            return concat([render([Partial(freq: 990, amp: 1, decay: 10)], duration: 0.1, format: format),
                           render([Partial(freq: 0, amp: 0, decay: 1)], duration: 0.08, format: format),
                           render([Partial(freq: 990, amp: 1, decay: 10)], duration: 0.1, format: format)], format: format)
        case .boxingBell: return bell(base: 1500, duration: 0.4, format: format)
        case .softGong: return gong(base: 392, duration: 1.0, format: format)
        }
    }

    /// Glocke: unharmonische Teiltöne mit raschem Abklingen.
    static func bell(base: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        render([Partial(freq: base, amp: 1, decay: 0.35), Partial(freq: base * 2.76, amp: 0.5, decay: 0.2),
                Partial(freq: base * 5.4, amp: 0.25, decay: 0.12), Partial(freq: base * 8.93, amp: 0.12, decay: 0.08)],
               duration: duration, attack: 0.002, format: format)
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
