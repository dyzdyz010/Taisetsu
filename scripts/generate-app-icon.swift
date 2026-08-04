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
    let background: RGB
    let mark: RGB
    let dot: RGB
    let dotOpacity: CGFloat
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
                background: RGB(hex: 0xF1ECE4),
                mark: RGB(hex: 0x303047),
                dot: RGB(hex: 0xD95C49),
                dotOpacity: 1
            )
        case .dark:
            Palette(
                background: RGB(hex: 0x252743),
                mark: RGB(hex: 0xF1ECE4),
                dot: RGB(hex: 0xE56D59),
                dotOpacity: 1
            )
        case .tinted:
            Palette(
                background: RGB(hex: 0xDED6CC),
                mark: RGB(hex: 0x453C45),
                dot: RGB(hex: 0x453C45),
                dotOpacity: 0.42
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
    context.setFillColor(try palette.background.cgColor(in: colorSpace))
    context.fill(CGRect(x: 0, y: 0, width: canvasPixels, height: canvasPixels))

    let scale = CGFloat(canvasPixels) / designUnits
    context.saveGState()
    context.translateBy(x: 0, y: CGFloat(canvasPixels))
    context.scaleBy(x: scale, y: -scale)

    let embracingArcs = CGMutablePath()
    embracingArcs.move(to: CGPoint(x: 45, y: 30))
    embracingArcs.addCurve(
        to: CGPoint(x: 29, y: 69),
        control1: CGPoint(x: 29, y: 40),
        control2: CGPoint(x: 25, y: 55)
    )
    embracingArcs.addCurve(
        to: CGPoint(x: 49, y: 92),
        control1: CGPoint(x: 32, y: 79),
        control2: CGPoint(x: 39, y: 87)
    )
    embracingArcs.move(to: CGPoint(x: 75, y: 30))
    embracingArcs.addCurve(
        to: CGPoint(x: 91, y: 69),
        control1: CGPoint(x: 91, y: 40),
        control2: CGPoint(x: 95, y: 55)
    )
    embracingArcs.addCurve(
        to: CGPoint(x: 71, y: 92),
        control1: CGPoint(x: 88, y: 79),
        control2: CGPoint(x: 81, y: 87)
    )

    context.addPath(embracingArcs)
    context.setStrokeColor(try palette.mark.cgColor(in: colorSpace))
    context.setLineWidth(8)
    context.setLineCap(.round)
    context.strokePath()

    context.setAlpha(palette.dotOpacity)
    context.setFillColor(try palette.dot.cgColor(in: colorSpace))
    context.fillEllipse(in: CGRect(x: 47, y: 48, width: 26, height: 26))
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
          <rect width="120" height="120" fill="\(palette.background.svg)"/>
          <path d="M45 30C29 40 25 55 29 69c3 10 10 18 20 23M75 30c16 10 20 25 16 39-3 10-10 18-20 23" fill="none" stroke="\(palette.mark.svg)" stroke-width="8" stroke-linecap="round"/>
          <circle cx="60" cy="61" r="13" fill="\(palette.dot.svg)"/>
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
