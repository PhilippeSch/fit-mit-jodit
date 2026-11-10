import CoreTransferable
import Foundation
import UniformTypeIdentifiers

extension UTType {
    /// Eigener Dateityp für exportierte Trainings (.fmjworkout), in Info.plist als exportierter Typ deklariert.
    static let fmjWorkout = UTType(exportedAs: "ch.fitmitjodit.timer.workout", conformingTo: .json)
}

/// Format einer exportierten Trainingsdatei. Versioniert, damit spätere Fassungen alte Dateien lesen können.
struct WorkoutFile: Codable, Transferable, Equatable {
    var format = "ch.fitmitjodit.workout"
    var version = 1
    var workout: Workout

    init(workout: Workout) { self.workout = workout }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .fmjWorkout) { file in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(WorkoutFile.fileName(for: file.workout))
            try file.encoded().write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
        .suggestedFileName { WorkoutFile.fileName(for: $0.workout) }
    }

    static func fileName(for w: Workout) -> String {
        let safe = w.name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-")
        return (safe.isEmpty ? "Training" : safe) + ".fmjworkout"
    }

    func encoded() throws -> Data {
        let e = JSONEncoder.fmj
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try e.encode(self)
    }

    enum ImportError: Error { case unreadable, wrongFormat, newerVersion }

    /// Liest eine Datei und gibt ein Training mit neuen IDs zurück (kein Überschreiben bestehender Trainings).
    static func importWorkout(from data: Data) throws -> Workout {
        guard let file = try? JSONDecoder.fmj.decode(WorkoutFile.self, from: data) else { throw ImportError.unreadable }
        guard file.format == "ch.fitmitjodit.workout" else { throw ImportError.wrongFormat }
        guard file.version <= 1 else { throw ImportError.newerVersion }
        return file.workout.duplicated()
    }

    static func importWorkout(from url: URL) throws -> Workout {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        return try importWorkout(from: Data(contentsOf: url))
    }
}
