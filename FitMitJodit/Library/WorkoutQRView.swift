import CoreImage.CIFilterBuiltins
import SwiftUI

/// QR-Code eines Trainings: Teilnehmende scannen ihn mit der iPhone-Kamera und haben das Training in ihrer App.
struct WorkoutQRView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let url = ShareCode.url(for: workout), let img = QRCode.image(for: url.absoluteString) {
                        Image(uiImage: img)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                            .frame(maxWidth: 560)
                            .accessibilityLabel(Text("QR-Code für «\(workout.name)»"))
                            .accessibilityIdentifier("qrImage")
                        Text(workout.name)
                            .font(Theme.title(.title, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(DurationFormat.clock(workout.totalSeconds))
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text("Mit der iPhone-Kamera scannen. Das Training erscheint danach in Fit mit Jodit, die App muss installiert sein.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)
                    } else {
                        Text("Der QR-Code konnte nicht erstellt werden.")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(Text("Training teilen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("closeQR")
                }
            }
        }
    }
}

enum QRCode {
    static func image(for text: String) -> UIImage? {
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(text.utf8)
        f.correctionLevel = "M"
        guard let out = f.outputImage else { return nil }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cg = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
