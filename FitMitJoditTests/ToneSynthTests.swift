import AVFoundation
import XCTest
@testable import FitMitJodit

/// Pegel der synthetischen Töne: nicht übersteuert, ohne Knackser, Piepser klingen ab.
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
}
