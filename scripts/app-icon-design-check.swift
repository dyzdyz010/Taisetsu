#!/usr/bin/env swift
import CoreGraphics
import Foundation
import ImageIO

private struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

private struct Pixel {
    let red: Int
    let green: Int
    let blue: Int

    var isMidnightBlue: Bool {
        red < 48 && green < 64 && blue < 88 && blue > green && green > red
    }

    var isChampagneGold: Bool {
        red > 150 && green > 105 && red > green && green > blue && red - blue > 45
    }

    var isLightNeutral: Bool {
        red > 185 && green > 185 && blue > 185
            && abs(red - green) < 18 && abs(green - blue) < 18
    }

    var isDarkNeutral: Bool {
        red < 96 && green < 96 && blue < 112
            && abs(red - green) < 18 && abs(green - blue) < 24
    }

    var isMediumNeutral: Bool {
        red >= 96 && red <= 160 && green >= 96 && green <= 160 && blue >= 96 && blue <= 176
            && abs(red - green) < 18 && abs(green - blue) < 24
    }

    func distance(to other: Pixel) -> Int {
        abs(red - other.red) + abs(green - other.green) + abs(blue - other.blue)
    }
}

private func loadPixels(at path: String) throws -> (width: Int, height: Int, data: Data) {
    let url = URL(fileURLWithPath: path)
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
    else {
        throw CheckFailure(description: "Unable to decode app icon at \(path)")
    }

    let bytesPerRow = image.width * 4
    var data = Data(count: bytesPerRow * image.height)
    let rendered = data.withUnsafeMutableBytes { bytes -> Bool in
        guard
            let context = CGContext(
                data: bytes.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            )
        else {
            return false
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return true
    }

    guard rendered else {
        throw CheckFailure(description: "Unable to normalize app icon pixels")
    }
    return (image.width, image.height, data)
}

private func sample(
    _ image: (width: Int, height: Int, data: Data),
    designX: Double,
    designY: Double
) -> Pixel {
    let x = min(image.width - 1, max(0, Int(designX / 120 * Double(image.width))))
    let y = min(image.height - 1, max(0, Int(designY / 120 * Double(image.height))))
    let offset = (y * image.width + x) * 4
    return image.data.withUnsafeBytes { bytes in
        let pixels = bytes.bindMemory(to: UInt8.self)
        return Pixel(
            red: Int(pixels[offset]),
            green: Int(pixels[offset + 1]),
            blue: Int(pixels[offset + 2])
        )
    }
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw CheckFailure(description: message) }
}

private func run() throws {
    let directory = "Taisetsu/Assets.xcassets/AppIcon.appiconset"
    let standard = try loadPixels(at: "\(directory)/AppIcon.png")
    let dark = try loadPixels(at: "\(directory)/AppIcon-Dark.png")
    let tinted = try loadPixels(at: "\(directory)/AppIcon-Tinted.png")
    try require(
        [standard, dark, tinted].allSatisfy { $0.width == 1024 && $0.height == 1024 },
        "Every icon appearance must be 1024x1024"
    )

    let topCorner = sample(standard, designX: 6, designY: 6)
    let bottomCorner = sample(standard, designX: 114, designY: 114)
    try require(topCorner.isMidnightBlue, "Standard icon must use a midnight-blue background")
    try require(bottomCorner.isMidnightBlue, "Background gradient must remain midnight blue")
    try require(topCorner.distance(to: bottomCorner) >= 18, "Background must retain a visible tonal gradient")

    try require(
        sample(standard, designX: 29, designY: 60).isChampagneGold,
        "Calendar frame must remain champagne gold"
    )
    try require(
        sample(standard, designX: 45, designY: 36).isChampagneGold,
        "Calendar binding marks must remain visibly gold"
    )
    try require(
        sample(standard, designX: 60, designY: 62).isChampagneGold,
        "The selected day must remain visibly gold"
    )
    try require(
        sample(standard, designX: 40, designY: 62).isMidnightBlue,
        "Negative space must separate the selected day from its frame"
    )

    try require(
        sample(dark, designX: 6, designY: 6).isMidnightBlue,
        "Dark icon must retain a midnight-blue background"
    )
    try require(
        sample(dark, designX: 29, designY: 60).isChampagneGold,
        "Dark icon must retain its gold calendar frame"
    )
    try require(
        sample(dark, designX: 45, designY: 36).isChampagneGold,
        "Dark icon must retain its gold binding marks"
    )
    try require(
        sample(dark, designX: 60, designY: 62).isChampagneGold,
        "Dark icon must retain its selected day"
    )

    try require(
        sample(tinted, designX: 6, designY: 6).isLightNeutral,
        "Tinted icon must use a light neutral background"
    )
    try require(
        sample(tinted, designX: 29, designY: 60).isDarkNeutral,
        "Tinted icon must retain a dark calendar frame"
    )
    try require(
        sample(tinted, designX: 45, designY: 36).isDarkNeutral,
        "Tinted icon must retain its binding marks"
    )
    try require(
        sample(tinted, designX: 60, designY: 62).isMediumNeutral,
        "Tinted icon must retain a distinct selected day"
    )
}

do {
    try run()
    print("App icon visual contract is satisfied.")
} catch {
    FileHandle.standardError.write(Data("App icon design check failed: \(error)\n".utf8))
    exit(EXIT_FAILURE)
}
