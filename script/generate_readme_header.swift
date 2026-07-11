#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let media = root.appendingPathComponent("docs/media")
let outputURL = media.appendingPathComponent("readme-header.png")

func loadImage(_ name: String) -> NSImage {
    let url = media.appendingPathComponent(name)
    guard let image = NSImage(contentsOf: url) else {
        fatalError("Unable to load \(url.path)")
    }
    return image
}

func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .center,
    lineSpacing: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineSpacing = lineSpacing
    (text as NSString).draw(
        in: rect,
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    )
}

func drawBadge(title: String, detail: String, color: NSColor, in rect: NSRect) {
    let path = NSBezierPath(roundedRect: rect, xRadius: 13, yRadius: 13)
    NSColor(calibratedWhite: 0.09, alpha: 0.94).setFill()
    path.fill()
    color.withAlphaComponent(0.72).setStroke()
    path.lineWidth = 1.2
    path.stroke()

    drawText(
        title.uppercased(),
        in: NSRect(x: rect.minX + 15, y: rect.minY + 18, width: rect.width - 30, height: 15),
        font: .systemFont(ofSize: 10, weight: .semibold),
        color: color,
        alignment: .left
    )
    drawText(
        detail,
        in: NSRect(x: rect.minX + 15, y: rect.minY + 5, width: rect.width - 30, height: 18),
        font: .systemFont(ofSize: 14, weight: .semibold),
        color: .white,
        alignment: .left
    )
}

let canvasSize = NSSize(width: 1944, height: 809)
let background = loadImage("readme-header-background.png")
let icon = loadImage("app-icon.png")
let launcher = loadImage("launcher-panel.png")
let settings = loadImage("settings.png")

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to create README header canvas")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

NSGraphicsContext.current?.imageInterpolation = .high
background.draw(in: NSRect(origin: .zero, size: canvasSize))

NSColor(calibratedWhite: 0.02, alpha: 0.34).setFill()
NSBezierPath(roundedRect: NSRect(x: 55, y: 44, width: 1834, height: 721), xRadius: 32, yRadius: 32).fill()

let brandRect = NSRect(x: 88, y: 159, width: 338, height: 550)
NSColor(calibratedWhite: 0.03, alpha: 0.54).setFill()
let brandPath = NSBezierPath(roundedRect: brandRect, xRadius: 26, yRadius: 26)
brandPath.fill()
NSColor(calibratedRed: 0.23, green: 0.57, blue: 0.95, alpha: 0.34).setStroke()
brandPath.lineWidth = 1.2
brandPath.stroke()

icon.draw(in: NSRect(x: 183, y: 482, width: 148, height: 148))
drawText(
    "DockShelf",
    in: NSRect(x: 110, y: 399, width: 294, height: 65),
    font: .systemFont(ofSize: 48, weight: .bold),
    color: .white
)
drawText(
    "Your apps, grouped\nand one gesture away.",
    in: NSRect(x: 116, y: 322, width: 282, height: 60),
    font: .systemFont(ofSize: 20, weight: .medium),
    color: NSColor(calibratedWhite: 0.82, alpha: 1),
    lineSpacing: 5
)

let interfaceHeight: CGFloat = 620
let launcherWidth = interfaceHeight * launcher.size.width / launcher.size.height
let settingsWidth = interfaceHeight * settings.size.width / settings.size.height
let interfaceY: CGFloat = 130

launcher.draw(
    in: NSRect(x: 468, y: interfaceY, width: launcherWidth, height: interfaceHeight),
    from: .zero,
    operation: .sourceOver,
    fraction: 1
)
settings.draw(
    in: NSRect(x: 755, y: interfaceY, width: settingsWidth, height: interfaceHeight),
    from: .zero,
    operation: .sourceOver,
    fraction: 1
)

drawBadge(
    title: "Built with",
    detail: "Swift 5.9",
    color: NSColor(calibratedRed: 0.94, green: 0.31, blue: 0.20, alpha: 1),
    in: NSRect(x: 116, y: 89, width: 142, height: 49)
)
drawBadge(
    title: "Designed for",
    detail: "macOS 13+",
    color: NSColor(calibratedRed: 0.40, green: 0.70, blue: 1.0, alpha: 1),
    in: NSRect(x: 270, y: 89, width: 142, height: 49)
)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.86]) else {
    fatalError("Unable to encode README header")
}

try png.write(to: outputURL, options: .atomic)
print(outputURL.path)
