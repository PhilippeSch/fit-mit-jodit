// Hörprobe: rendert die Töne der App in Audiodateien und misst sie.
//
// Diese Datei ist kein Teil der App. `Tools/hoerprobe.sh` hängt sie hinter die aus der App herausgelösten Typen
// (BlockKind, SignalKind, ToneSet, ToneSynth) und übersetzt beides zusammen. So klingt die Hörprobe genau wie die
// App, ohne Simulator und ohne Gerät.
//
// Aufruf (durch das Skript): render <Ausgabeordner> [Namenszusatz] [nur dieses Ton-Set]

let sampleRate = 44_100.0
let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

func samples(_ buffer: AVAudioPCMBuffer?) -> [Float] {
    guard let buffer, let channel = buffer.floatChannelData?[0] else { return [] }
    return Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
}

/// Töne an ihren Zeitpunkten übereinanderlegen. Wie in der App: Jeder Ton hat seine eigene Stimme und klingt
/// weiter, während der nächste einsetzt.
func timeline(_ events: [(at: Double, tone: AVAudioPCMBuffer?)], total: Double) -> [Float] {
    var out = [Float](repeating: 0, count: Int(total * sampleRate))
    for event in events {
        let tone = samples(event.tone)
        let start = Int(event.at * sampleRate)
        for i in 0..<tone.count where start + i < out.count { out[start + i] += tone[i] }
    }
    return out
}

func write(_ signal: [Float], to path: String) throws {
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(signal.count))!
    buffer.frameLength = AVAudioFrameCount(signal.count)
    for i in 0..<signal.count { buffer.floatChannelData![0][i] = signal[i] }
    let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: sampleRate, AVNumberOfChannelsKey: 1,
                                   AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false]
    try AVAudioFile(forWriting: URL(fileURLWithPath: path), settings: settings).write(from: buffer)
}

func rms(_ s: [Float], _ from: Double, _ to: Double) -> Float {
    let lo = min(s.count, Int(from * sampleRate)), hi = min(s.count, Int(to * sampleRate))
    guard hi > lo else { return 0 }
    return (s[lo..<hi].map { $0 * $0 }.reduce(0, +) / Float(hi - lo)).squareRoot()
}

/// Schwerpunkt des Spektrums in den ersten 0.4 s. Tiefer heisst wärmer und voller, höher heisst heller und spitzer.
func centroid(_ s: [Float]) -> Double {
    let n = min(s.count, Int(0.4 * sampleRate))
    var weighted = 0.0, sum = 0.0
    for f in stride(from: 100.0, through: 6000.0, by: 20.0) {
        let c = 2 * cos(2 * Double.pi * f / sampleRate)
        var s1 = 0.0, s2 = 0.0
        for i in 0..<n {
            let s0 = Double(s[i]) + c * s1 - s2
            s2 = s1
            s1 = s0
        }
        let amplitude = max(0, s1 * s1 + s2 * s2 - c * s1 * s2).squareRoot()
        weighted += f * amplitude
        sum += amplitude
    }
    return sum > 0 ? weighted / sum : 0
}

/// Messwerte eines Tons: Dauer, Spitzenpegel, Lautstärke (RMS) in vier Zeitfenstern, Klangfarbe.
/// Anhaltspunkte: Spitze höchstens 0.6. Ein Ton, der nach 0.3 s schon unter einem Zehntel des Anfangs liegt, wirkt
/// wie ein «Ping»; einer, der nach 0.6 bis 1 s noch gut da ist, klingt nach.
func report(_ name: String, _ buffer: AVAudioPCMBuffer?) {
    let s = samples(buffer)
    let peak = s.map { abs($0) }.max() ?? 0
    print(String(format: "  %-22@ %.2f s  Spitze %.2f  RMS 0–0.1 s %.3f  0.1–0.3 s %.3f  0.3–0.6 s %.3f  0.6–1.0 s %.3f  Schwerpunkt %4.0f Hz",
                 name as NSString, Double(s.count) / sampleRate, peak, rms(s, 0, 0.1), rms(s, 0.1, 0.3), rms(s, 0.3, 0.6), rms(s, 0.6, 1.0), centroid(s)))
}

let arguments = CommandLine.arguments
guard arguments.count > 1 else { fatalError("Ausgabeordner fehlt") }
let outputFolder = arguments[1]
let suffix = arguments.count > 2 ? arguments[2] : ""
let only = arguments.count > 3 ? ToneSet(rawValue: arguments[3]) : nil

for set in ToneSet.allCases where only == nil || only == set {
    func tone(_ kind: SignalKind) -> AVAudioPCMBuffer? { ToneSynth.buffer(for: kind, set: set, format: format) }
    let halftime = ToneSynth.halftime(set: set, format: format)
    print("\(set.rawValue)\(suffix)")
    report("Countdown", tone(.countdown(3)))
    report("Start Übung", tone(.blockStart(.work)))
    report("Start Pause", tone(.blockStart(.rest)))
    report("Halbzeit", halftime)
    report("Schluss", tone(.finished))
    // Ablauf der Hörprobe: 3-2-1 und Start einer Übung, 3-2-1 und Start einer Pause, Halbzeit, Schluss.
    let sequence = timeline([(0.3, tone(.countdown(3))), (1.3, tone(.countdown(2))), (2.3, tone(.countdown(1))), (3.3, tone(.blockStart(.work))),
                             (7.3, tone(.countdown(3))), (8.3, tone(.countdown(2))), (9.3, tone(.countdown(1))), (10.3, tone(.blockStart(.rest))),
                             (14.3, halftime), (16.8, tone(.finished))], total: 20.5)
    print(String(format: "  Spitze der überlagerten Töne bei Lautstärke 100 %%: %.2f (muss unter 1.0 bleiben)", sequence.map { abs($0) }.max() ?? 0))
    try write(sequence, to: "\(outputFolder)/\(set.rawValue)\(suffix).wav")
}
