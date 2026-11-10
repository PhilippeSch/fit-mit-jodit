// Überträgt die EXIF-Drehung von Screenshots in die Pixel und entfernt Metadaten,
// damit App Store Connect Querformat-Bilder mit den richtigen Massen bekommt.
// Aufruf: swift Tools/normalize_screenshots.swift fastlane/screenshots
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "fastlane/screenshots"
let fm = FileManager.default
let files = (fm.enumerator(atPath: root)?.compactMap { $0 as? String } ?? []).filter { $0.hasSuffix(".png") }
for rel in files {
    let url = URL(fileURLWithPath: root).appendingPathComponent(rel)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else { continue }
    let w = props[kCGImagePropertyPixelWidth] as? Int ?? 0
    let h = props[kCGImagePropertyPixelHeight] as? Int ?? 0
    let opts: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                 kCGImageSourceCreateThumbnailWithTransform: true,
                                 kCGImageSourceThumbnailMaxPixelSize: max(w, h)]
    guard let img = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary),
          let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { continue }
    CGImageDestinationAddImage(dst, img, nil)
    CGImageDestinationFinalize(dst)
    print("\(rel): \(img.width)x\(img.height)")
}
