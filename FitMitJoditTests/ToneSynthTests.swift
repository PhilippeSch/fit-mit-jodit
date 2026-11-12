import AVFoundation
import XCTest
@testable import FitMitJodit

/// Pegel der synthetischen Töne: nicht übersteuert, ohne Knackser, Piepser klingen ab.
/// Set «Glocke»: Schlusston höher als der Countdown, Schläge klingen nach, Hall.
final class ToneSynthTests: XCTestCase {
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private func samples(_ buf: AVAudioPCMBuffer?) -> [Float] {
        guard let buf, let ch = buf.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: ch, count: Int(buf.frameLength)))
    }

    private var allTones: [(String, AVAudioPCMBuffer?)] {
        let kinds: [SignalKind] = [.countdown(3), .countdown(1), .blockStart(.work), .blockStart(.rest), .blockStart(.prep), .finished]
        var out: [(String, AVAudioPCMBuffer?)] = []
        for set in ToneSet.allCases {
            for k in kinds { out.append(("\(set)-\(k)", ToneSynth.buffer(for: k, set: set, format: format))) }
            out.append(("\(set)-halftime", ToneSynth.halftime(set: set, format: format)))
        }
        return out
    }

    func testNoToneExceedsPeakLevel() {
        for (name, buf) in allTones {
            let s = samples(buf)
            XCTAssertFalse(s.isEmpty, name)
            let peak = s.map { abs($0) }.max() ?? 0
            XCTAssertLessThanOrEqual(Double(peak), ToneSynth.peakLevel + 0.001, name)
            XCTAssertLessThanOrEqual(Double(peak), 0.7, "\(name): zu nahe an Vollaussteuerung")
        }
    }

    func testTonesStartAndEndSilently() {
        for (name, buf) in allTones {
            let s = samples(buf)
            guard let first = s.first, let last = s.last else { return XCTFail(name) }
            XCTAssertLessThan(abs(first), 0.01, "\(name): Knacks am Anfang")
            XCTAssertLessThan(abs(last), 0.01, "\(name): Knacks am Ende")
        }
    }

    func testCountdownBeepDecays() {
        let s = samples(ToneSynth.buffer(for: .countdown(3), set: .beeps, format: format))
        let q = s.count / 4
        func rms(_ part: ArraySlice<Float>) -> Float { (part.map { $0 * $0 }.reduce(0, +) / Float(part.count)).squareRoot() }
        XCTAssertLessThan(rms(s[(3 * q)...]), rms(s[..<q]) * 0.6, "Countdown-Piepser soll abklingen, nicht flach durchtönen")
    }

    // MARK: Glocke

    /// Stärkste Frequenz in den ersten 0.1 s (Goertzel über ein Raster von 5 Hz zwischen 200 und 3000 Hz).
    /// Das Fenster ist bewusst kurz: Es löst rund 10 Hz auf, damit trifft das 5-Hz-Raster jeden Teilton.
    /// Mit einem längeren Fenster fiele ein Teilton zwischen zwei Rasterpunkten fast ganz heraus.
    private func dominantFrequency(_ s: [Float]) -> Double {
        let sampleRate = 44_100.0
        let n = min(s.count, Int(0.1 * sampleRate))
        var best = (freq: 0.0, power: 0.0)
        for f in stride(from: 200.0, through: 3000.0, by: 5.0) {
            let c = 2 * cos(2 * Double.pi * f / sampleRate)
            var s1 = 0.0, s2 = 0.0
            for i in 0..<n {
                let s0 = Double(s[i]) + c * s1 - s2
                s2 = s1
                s1 = s0
            }
            let power = s1 * s1 + s2 * s2 - c * s1 * s2
            if power > best.power { best = (f, power) }
        }
        return best.freq
    }

    private func rms(_ s: [Float], from: Double, to: Double) -> Float {
        let lo = min(s.count, Int(from * 44_100)), hi = min(s.count, Int(to * 44_100))
        guard hi > lo else { return 0 }
        return (s[lo..<hi].map { $0 * $0 }.reduce(0, +) / Float(hi - lo)).squareRoot()
    }

    func testChimeLastToneIsHigherThanCountdown() {
        let count = dominantFrequency(samples(ToneSynth.buffer(for: .countdown(1), set: .chime, format: format)))
        let work = dominantFrequency(samples(ToneSynth.buffer(for: .blockStart(.work), set: .chime, format: format)))
        let prep = dominantFrequency(samples(ToneSynth.buffer(for: .blockStart(.prep), set: .chime, format: format)))
        let rest = dominantFrequency(samples(ToneSynth.buffer(for: .blockStart(.rest), set: .chime, format: format)))
        XCTAssertEqual(count, ToneSynth.ChimeNote.count, accuracy: 10, "Countdown auf dem Schlagton d''")
        XCTAssertGreaterThan(work, count * 1.4, "Start einer Übung: deutlich höher (Quinte)")
        XCTAssertEqual(prep, work, accuracy: 1)
        XCTAssertGreaterThan(rest, count * 1.2, "Start einer Pause: ebenfalls höher (grosse Terz)")
        XCTAssertLessThan(rest, work, "Pause tiefer als Übung, damit man die beiden unterscheidet")
    }

    func testChimeCountdownIsTheSameForThreeTwoOne() {
        let three = samples(ToneSynth.buffer(for: .countdown(3), set: .chime, format: format))
        XCTAssertEqual(three, samples(ToneSynth.buffer(for: .countdown(2), set: .chime, format: format)))
        XCTAssertEqual(three, samples(ToneSynth.buffer(for: .countdown(1), set: .chime, format: format)))
    }

    func testChimeRingsOnWhileTheNextStrikeComes() {
        let count = samples(ToneSynth.buffer(for: .countdown(3), set: .chime, format: format))
        let start = samples(ToneSynth.buffer(for: .blockStart(.work), set: .chime, format: format))
        // Klingt nach (kein kurzer «Ping»): Wenn nach 1 s der nächste Schlag kommt, ist der vorherige noch gut hörbar.
        XCTAssertGreaterThan(rms(count, from: 0.6, to: 1.0), rms(count, from: 0, to: 0.1) * 0.1, "Countdown-Schlag klingt nach")
        XCTAssertGreaterThan(rms(start, from: 1.0, to: 1.5), rms(start, from: 0, to: 0.1) * 0.1, "Schlusston klingt lange aus")
        XCTAssertGreaterThan(start.count, count.count, "Schlusston klingt länger als ein Countdown-Schlag")
        // Vier Stimmen, reihum: Ein Schlag muss verklungen sein, bevor seine Stimme wieder drankommt (nach 4 s).
        // Der Schlusston des Trainings muss enden, bevor die Audiositzung freigegeben wird (nach 3.5 s).
        let kinds: [SignalKind] = [.countdown(1), .blockStart(.work), .blockStart(.rest), .finished]
        for kind in kinds {
            let length = Double(samples(ToneSynth.buffer(for: kind, set: .chime, format: format)).count) / 44_100
            XCTAssertLessThanOrEqual(length, 3.5, "\(kind)")
        }
    }

    func testHallAddsATailWithoutBlurringTheStrike() {
        // Ein einzelner Impuls: Der Hall setzt erst nach 20 ms ein und klingt dann aus.
        var impulse = [Double](repeating: 0, count: 44_100)
        impulse[0] = 1
        let wet = ToneSynth.withHall(impulse, sampleRate: 44_100, amount: 0.45)
        XCTAssertEqual(wet[0], 1, accuracy: 1e-9, "der Anschlag selbst bleibt unverändert")
        XCTAssertEqual(wet[1..<Int(0.02 * 44_100)].map { abs($0) }.max() ?? 1, 0, accuracy: 1e-12, "20 ms Abstand bis zum Hall")
        let tail = wet[1...].reduce(0) { $0 + $1 * $1 }
        XCTAssertEqual(tail, 0.45, accuracy: 0.01, "Energie des Nachhalls im gewünschten Verhältnis zum trockenen Klang")
        func energy(_ from: Double, _ to: Double) -> Double { wet[Int(from * 44_100)..<Int(to * 44_100)].reduce(0) { $0 + $1 * $1 } }
        XCTAssertGreaterThan(energy(0.02, 0.3), energy(0.3, 0.6), "Hall klingt ab")
        XCTAssertGreaterThan(energy(0.3, 0.6), energy(0.6, 0.9))
        XCTAssertGreaterThan(energy(0.6, 0.9), 0, "Nachhall ist nach 0.6 s noch da (grosser Raum)")

        // Am Glockenschlag: Mit Hall ist nach dem Anschlag mehr Klang da als trocken.
        let strike = [ToneSynth.Strike(at: 0, base: ToneSynth.ChimeNote.count, ring: 5)]
        let dry = samples(ToneSynth.strikes(strike, duration: 2, fade: 0.7, hall: 0, format: format))
        let hall = samples(ToneSynth.strikes(strike, duration: 2, fade: 0.7, format: format))
        XCTAssertGreaterThan(rms(hall, from: 0.1, to: 0.6), rms(dry, from: 0.1, to: 0.6) * 1.1)
        XCTAssertEqual(ToneSynth.chimeHall, 1.0, "gewählter Hall-Anteil (Hörprobe «noch mehr Hall»)")
    }

    func testCountdownSharesOneCachedTone() {
        XCTAssertEqual(AudioSignalPlayer.key(.countdown(3), .chime), AudioSignalPlayer.key(.countdown(1), .chime))
        XCTAssertNotEqual(AudioSignalPlayer.key(.countdown(3), .chime), AudioSignalPlayer.key(.countdown(3), .beeps))
        XCTAssertNotEqual(AudioSignalPlayer.key(.blockStart(.work), .chime), AudioSignalPlayer.key(.blockStart(.rest), .chime))
    }
}
