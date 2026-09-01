#!/usr/bin/env swift
import CoreGraphics
import Darwin
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let canvasPixels = 1024
private let designUnits: CGFloat = 120

private struct IconGenerationError: Error, CustomStringConvertible {
    let description: String
}

private struct RGB: Equatable {
    let hex: Int

    var red: CGFloat { CGFloat((hex >> 16) & 0xFF) / 255 }
    var green: CGFloat { CGFloat((hex >> 8) & 0xFF) / 255 }
    var blue: CGFloat { CGFloat(hex & 0xFF) / 255 }
    var svg: String { String(format: "#%06X", hex) }

    func cgColor(in colorSpace: CGColorSpace) throws -> CGColor {
        guard
            let color = CGColor(
                colorSpace: colorSpace,
                components: [red, green, blue, 1]
            )
        else {
            throw IconGenerationError(description: "Unable to create sRGB color \(svg)")
        }
        return color
    }
}

private struct Palette {
    let backgroundTop: RGB
    let backgroundBottom: RGB
    let frame: RGB
    let binding: RGB
    let selectedDay: RGB
}

private enum Appearance: CaseIterable {
    case standard
    case dark
    case tinted

    var filename: String {
        switch self {
        case .standard: "AppIcon.png"
        case .dark: "AppIcon-Dark.png"
        case .tinted: "AppIcon-Tinted.png"
        }
    }

    var palette: Palette {
        switch self {
        case .standard:
            Palette(
                backgroundTop: RGB(hex: 0x07101E),
                backgroundBottom: RGB(hex: 0x17243B),
                frame: RGB(hex: 0xC9A86A),
                binding: RGB(hex: 0xE5CD95),
                selectedDay: RGB(hex: 0xF2D69A)
            )
        case .dark:
            Palette(
                backgroundTop: RGB(hex: 0x020611),
                backgroundBottom: RGB(hex: 0x0A1324),
                frame: RGB(hex: 0xE3C582),
                binding: RGB(hex: 0xF4DBA1),
                selectedDay: RGB(hex: 0xFFE7AD)
            )
        case .tinted:
            Palette(
                backgroundTop: RGB(hex: 0xE8E9EB),
                backgroundBottom: RGB(hex: 0xC9CDD2),
                frame: RGB(hex: 0x343943),
                binding: RGB(hex: 0x525966),
                selectedDay: RGB(hex: 0x777F8C)
            )
        }
    }
}

private let svgRelativePath = "Design/AppIcon/TaisetsuAppIcon.svg"
private let assetDirectoryRelativePath = "Taisetsu/Assets.xcassets/AppIcon.appiconset"
private let contentsRelativePath = "\(assetDirectoryRelativePath)/Contents.json"

private func renderImage(for appearance: Appearance) throws -> CGImage {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw IconGenerationError(description: "Unable to create the sRGB color space")
    }

    let bitmapInfo =
        CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    guard
        let context = CGContext(
            data: nil,
            width: canvasPixels,
            height: canvasPixels,
            bitsPerComponent: 8,
            bytesPerRow: canvasPixels * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
    else {
        throw IconGenerationError(description: "Unable to create the icon bitmap context")
    }

    let palette = appearance.palette
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .high

    guard
        let backgroundGradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                try palette.backgroundTop.cgColor(in: colorSpace),
                try palette.backgroundBottom.cgColor(in: colorSpace),
            ] as CFArray,
            locations: [0, 1]
        )
    else {
        throw IconGenerationError(description: "Unable to create the icon background gradient")
    }
    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: 0, y: canvasPixels),
        end: CGPoint(x: canvasPixels, y: 0),
        options: []
    )

    let scale = CGFloat(canvasPixels) / designUnits
    context.saveGState()
    context.translateBy(x: 0, y: CGFloat(canvasPixels))
    context.scaleBy(x: scale, y: -scale)

    let calendarFrame = CGPath(
        roundedRect: CGRect(x: 29, y: 27, width: 62, height: 67),
        cornerWidth: 14,
        cornerHeight: 14,
        transform: nil
    )
    context.addPath(calendarFrame)
    context.setStrokeColor(try palette.frame.cgColor(in: colorSpace))
    context.setLineWidth(7)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()

    let bindingMarks = CGMutablePath()
    bindingMarks.move(to: CGPoint(x: 45, y: 23))
    bindingMarks.addLine(to: CGPoint(x: 45, y: 35))
    bindingMarks.move(to: CGPoint(x: 75, y: 23))
    bindingMarks.addLine(to: CGPoint(x: 75, y: 35))
    context.addPath(bindingMarks)
    context.setStrokeColor(try palette.binding.cgColor(in: colorSpace))
    context.setLineWidth(7)
    context.setLineCap(.round)
    context.strokePath()

    let selectedDay = CGPath(
        roundedRect: CGRect(x: 51, y: 54, width: 18, height: 18),
        cornerWidth: 4,
        cornerHeight: 4,
        transform: nil
    )
    context.addPath(selectedDay)
    context.setFillColor(try palette.selectedDay.cgColor(in: colorSpace))
    context.fillPath()
    context.restoreGState()

    guard let image = context.makeImage() else {
        throw IconGenerationError(description: "Unable to create the rendered icon image")
    }
    return image
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    guard
        let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        )
    else {
        throw IconGenerationError(description: "Unable to create PNG destination: \(url.path)")
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw IconGenerationError(description: "Unable to finalize PNG: \(url.path)")
    }
}

private func makeSVG() -> String {
    let palette = Appearance.standard.palette
    return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!-- Generated by scripts/generate-app-icon.swift. -->
        <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 120 120">
          <defs>
            <linearGradient id="midnight" x1="0" y1="0" x2="120" y2="120" gradientUnits="userSpaceOnUse">
              <stop offset="0" stop-color="\(palette.backgroundTop.svg)"/>
              <stop offset="1" stop-color="\(palette.backgroundBottom.svg)"/>
            </linearGradient>
          </defs>
          <rect width="120" height="120" fill="url(#midnight)"/>
          <rect x="29" y="27" width="62" height="67" rx="14" fill="none" stroke="\(palette.frame.svg)" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M45 23V35M75 23V35" fill="none" stroke="\(palette.binding.svg)" stroke-width="7" stroke-linecap="round"/>
          <rect x="51" y="54" width="18" height="18" rx="4" fill="\(palette.selectedDay.svg)"/>
        </svg>

        """
}

private func makeContentsJSON() -> String {
    """
    {
      "images" : [
        {
          "filename" : "AppIcon.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "dark"
            }
          ],
          "filename" : "AppIcon-Dark.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "tinted"
            }
          ],
          "filename" : "AppIcon-Tinted.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """
}

private func writeOutputs(to root: URL) throws {
    let fileManager = FileManager.default
    let svgURL = root.appendingPathComponent(svgRelativePath)
    let assetDirectory = root.appendingPathComponent(assetDirectoryRelativePath, isDirectory: true)
    try fileManager.createDirectory(
        at: svgURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try fileManager.createDirectory(at: assetDirectory, withIntermediateDirectories: true)

    try Data(makeSVG().utf8).write(to: svgURL, options: .atomic)
    try Data(makeContentsJSON().utf8).write(
        to: root.appendingPathComponent(contentsRelativePath),
        options: .atomic
    )

    for appearance in Appearance.allCases {
        let outputURL = assetDirectory.appendingPathComponent(appearance.filename)
        try writePNG(try renderImage(for: appearance), to: outputURL)
    }
}

private func decodedImage(at url: URL) throws -> CGImage {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw IconGenerationError(description: "Unable to decode image: \(url.path)")
    }
    return image
}

private func normalizedPixels(of image: CGImage) throws -> Data {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw IconGenerationError(description: "Unable to create the sRGB comparison color space")
    }

    let bytesPerRow = image.width * 4
    var pixels = Data(count: bytesPerRow * image.height)
    let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
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
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
        )
        return true
    }

    guard rendered else {
        throw IconGenerationError(description: "Unable to normalize icon pixels")
    }
    return pixels
}

private func validateOpaque1024Image(_ image: CGImage, name: String) throws {
    guard image.width == canvasPixels, image.height == canvasPixels else {
        throw IconGenerationError(description: "\(name) must be 1024x1024")
    }

    switch image.alphaInfo {
    case .none, .noneSkipFirst, .noneSkipLast:
        break
    default:
        throw IconGenerationError(description: "\(name) must not contain an alpha channel")
    }
}

private func compareFile(at relativePath: String, root: URL, generatedRoot: URL) throws {
    let committedURL = root.appendingPathComponent(relativePath)
    let generatedURL = generatedRoot.appendingPathComponent(relativePath)
    guard FileManager.default.fileExists(atPath: committedURL.path) else {
        throw IconGenerationError(description: "Missing generated asset: \(relativePath)")
    }
    guard try Data(contentsOf: committedURL) == Data(contentsOf: generatedURL) else {
        throw IconGenerationError(
            description:
                "Generated asset is stale: \(relativePath). Run swift scripts/generate-app-icon.swift"
        )
    }
}

private func comparePNG(
    named filename: String,
    root: URL,
    generatedRoot: URL
) throws {
    let relativePath = "\(assetDirectoryRelativePath)/\(filename)"
    let committedImage = try decodedImage(at: root.appendingPathComponent(relativePath))
    let generatedImage = try decodedImage(at: generatedRoot.appendingPathComponent(relativePath))
    try validateOpaque1024Image(committedImage, name: filename)
    try validateOpaque1024Image(generatedImage, name: filename)

    guard try normalizedPixels(of: committedImage) == normalizedPixels(of: generatedImage) else {
        throw IconGenerationError(
            description:
                "Generated icon pixels are stale: \(filename). Run swift scripts/generate-app-icon.swift"
        )
    }
}

private func checkOutputs(at root: URL) throws {
    let fileManager = FileManager.default
    let temporaryRoot = fileManager.temporaryDirectory
        .appendingPathComponent("TaisetsuAppIcon-\(UUID().uuidString)", isDirectory: true)
    defer { try? fileManager.removeItem(at: temporaryRoot) }

    try writeOutputs(to: temporaryRoot)
    try compareFile(at: svgRelativePath, root: root, generatedRoot: temporaryRoot)
    try compareFile(at: contentsRelativePath, root: root, generatedRoot: temporaryRoot)
    for appearance in Appearance.allCases {
        try comparePNG(named: appearance.filename, root: root, generatedRoot: temporaryRoot)
    }
}

private func run() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.isEmpty || arguments == ["--check"] else {
        throw IconGenerationError(description: "Usage: swift scripts/generate-app-icon.swift [--check]")
    }

    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    if arguments == ["--check"] {
        try checkOutputs(at: root)
        print("App icon generated outputs are current.")
    } else {
        try writeOutputs(to: root)
        print("Generated \(svgRelativePath) and three 1024px app icon assets.")
    }
}

do {
    try run()
} catch {
    FileHandle.standardError.write(Data("App icon generation failed: \(error)\n".utf8))
    exit(EXIT_FAILURE)
}
