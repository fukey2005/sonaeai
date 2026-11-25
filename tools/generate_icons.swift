import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let sourceURL = root.appendingPathComponent("assets/branding/app_icon_v3.png")
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let artwork = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Missing icon artwork: \(sourceURL.path)")
}

// Deterministic resizing only. An opaque Core Graphics RGB context avoids
// AppKit's unsupported three-channel bitmap drawing in command-line tools.
func save(_ relative: String, _ size: Int, inset: CGFloat = 0) throws {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    guard let context = CGContext(data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: size * 4, space: space, bitmapInfo: bitmapInfo) else {
        fatalError("Cannot create RGB icon context")
    }
    context.interpolationQuality = .high
    context.setFillColor(red: 1, green: 218.0/255.0, blue: 0, alpha: 1)
    let square = CGRect(x: 0, y: 0, width: size, height: size)
    context.fill(square)
    context.draw(artwork, in: square.insetBy(dx: CGFloat(size)*inset, dy: CGFloat(size)*inset))
    // Reject blank or black conversion results before replacing any asset.
    let bytes = context.data!.assumingMemoryBound(to: UInt8.self)
    var darkest = 765, lightest = 0
    for y in stride(from: 0, to: size, by: max(1, size / 32)) {
        for x in stride(from: 0, to: size, by: max(1, size / 32)) {
            let i = y * context.bytesPerRow + x * 4
            let sum = Int(bytes[i]) + Int(bytes[i+1]) + Int(bytes[i+2])
            darkest = min(darkest, sum); lightest = max(lightest, sum)
        }
    }
    guard darkest < 200, lightest > 400, let image = context.makeImage() else {
        fatalError("Icon conversion lost its artwork or color: \(relative)")
    }
    let destination = root.appendingPathComponent(relative)
    try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let writer = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("Cannot write \(relative)")
    }
    CGImageDestinationAddImage(writer, image, nil)
    guard CGImageDestinationFinalize(writer) else { fatalError("PNG write failed") }
}

let iconDirectory = "ios/Runner/Assets.xcassets/AppIcon.appiconset/"
let contents = try Data(contentsOf: root.appendingPathComponent(iconDirectory + "Contents.json"))
let catalog = try JSONSerialization.jsonObject(with: contents) as! [String: Any]
for item in catalog["images"] as! [[String: String]] {
    if let filename = item["filename"], let dimensions = item["size"], let rawScale = item["scale"] {
        let points = Double(dimensions.components(separatedBy: "x")[0])!
        let scale = Double(rawScale.replacingOccurrences(of: "x", with: ""))!
        try save(iconDirectory + filename, Int(points * scale))
    }
}
for (density, size) in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)] {
    try save("android/app/src/main/res/mipmap-\(density)/ic_launcher.png", size)
}
for size in [192,512] {
    try save("web/icons/Icon-\(size).png", size)
    try save("web/icons/Icon-maskable-\(size).png", size, inset: 0.12)
}
try save("web/favicon.png", 32)
try save("assets/branding/app_icon_1024.png", 1024)
print("Generated and verified opaque, nonblank app icons for iOS, Android and web.")
