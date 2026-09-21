#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: make_app_icon.swift OUTPUT.png\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()

func drawSymbol(
    _ name: String,
    description: String,
    pointSize: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    in rect: NSRect
) throws {
    let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        .applying(NSImage.SymbolConfiguration(hierarchicalColor: color))
    guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: description)?
        .withSymbolConfiguration(configuration) else {
        throw NSError(
            domain: "KeyHarborIconGenerator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not load SF Symbol: \(name)"]
        )
    }
    symbol.draw(
        in: rect,
        from: .zero,
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: nil
    )
}

do {
    try drawSymbol(
        "keyboard",
        description: "Keyboard",
        pointSize: 510,
        weight: .medium,
        color: .systemBlue,
        in: NSRect(x: 150, y: 225, width: 700, height: 520)
    )
    try drawSymbol(
        "arrow.triangle.2.circlepath",
        description: "Switch applications",
        pointSize: 170,
        weight: .bold,
        color: .systemMint,
        in: NSRect(x: 650, y: 620, width: 230, height: 230)
    )
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode the icon.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try png.write(to: outputURL, options: .atomic)
print(outputURL.path)
