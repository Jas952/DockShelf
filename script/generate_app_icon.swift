#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate_app_icon.swift <output.icns>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let fileManager = FileManager.default
let iconsetURL = fileManager.temporaryDirectory
    .appendingPathComponent("DockShelfAppIcon-\(UUID().uuidString)")
    .appendingPathExtension("iconset")

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
defer {
    try? fileManager.removeItem(at: iconsetURL)
}

struct IconSpec {
    let pointSize: Int
    let scale: Int

    var pixels: Int { pointSize * scale }
    var filename: String {
        scale == 1 ? "icon_\(pointSize)x\(pointSize).png" : "icon_\(pointSize)x\(pointSize)@2x.png"
    }
}

let specs = [
    IconSpec(pointSize: 16, scale: 1),
    IconSpec(pointSize: 16, scale: 2),
    IconSpec(pointSize: 32, scale: 1),
    IconSpec(pointSize: 32, scale: 2),
    IconSpec(pointSize: 128, scale: 1),
    IconSpec(pointSize: 128, scale: 2),
    IconSpec(pointSize: 256, scale: 1),
    IconSpec(pointSize: 256, scale: 2),
    IconSpec(pointSize: 512, scale: 1),
    IconSpec(pointSize: 512, scale: 2)
]

func scaled(_ size: CGFloat, _ factor: CGFloat, minimum: CGFloat = 1) -> CGFloat {
    max(minimum, size * factor)
}

func strokePath(_ path: NSBezierPath, color: NSColor, width: CGFloat, dash: [CGFloat]? = nil) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    if let dash {
        path.setLineDash(dash, count: dash.count, phase: 0)
    }
    path.stroke()
}

func fillRounded(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawLine(from start: CGPoint, to end: CGPoint, color: NSColor, width: CGFloat, dash: [CGFloat]? = nil) {
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    strokePath(path, color: color, width: width, dash: dash)
}

func drawGrid(in rect: NSRect, size: CGFloat) {
    let minor = scaled(size, 0.066, minimum: 8)
    let major = minor * 2
    let minorColor = NSColor.white.withAlphaComponent(0.12)
    let majorColor = NSColor.white.withAlphaComponent(0.20)
    let minorWidth = scaled(size, 0.00135, minimum: 0.7)
    let majorWidth = scaled(size, 0.0021, minimum: 0.9)

    var x = rect.minX
    var index = 0
    while x <= rect.maxX {
        drawLine(
            from: CGPoint(x: x, y: rect.minY),
            to: CGPoint(x: x, y: rect.maxY),
            color: index % 2 == 0 ? majorColor : minorColor,
            width: index % 2 == 0 ? majorWidth : minorWidth
        )
        x += major / 2
        index += 1
    }

    var y = rect.minY
    index = 0
    while y <= rect.maxY {
        drawLine(
            from: CGPoint(x: rect.minX, y: y),
            to: CGPoint(x: rect.maxX, y: y),
            color: index % 2 == 0 ? majorColor : minorColor,
            width: index % 2 == 0 ? majorWidth : minorWidth
        )
        y += major / 2
        index += 1
    }
}

func drawAppsGridIcon(in rect: NSRect, color: NSColor, width: CGFloat) {
    let gap = rect.width * 0.16
    let cell = (rect.width - gap) / 2

    for row in 0..<2 {
        for column in 0..<2 {
            let itemRect = NSRect(
                x: rect.minX + CGFloat(column) * (cell + gap),
                y: rect.minY + CGFloat(row) * (cell + gap),
                width: cell,
                height: cell
            )
            let path = NSBezierPath(roundedRect: itemRect, xRadius: cell * 0.22, yRadius: cell * 0.22)
            strokePath(path, color: color, width: width)
        }
    }
}

func drawFolderIcon(in rect: NSRect, color: NSColor, width: CGFloat) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.16))
    path.line(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.56))
    path.curve(
        to: CGPoint(x: rect.minX + rect.width * 0.17, y: rect.maxY - rect.height * 0.40),
        controlPoint1: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.47),
        controlPoint2: CGPoint(x: rect.minX + rect.width * 0.07, y: rect.maxY - rect.height * 0.40)
    )
    path.line(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.40))
    path.line(to: CGPoint(x: rect.minX + rect.width * 0.53, y: rect.maxY - rect.height * 0.27))
    path.line(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY - rect.height * 0.27))
    path.curve(
        to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.42),
        controlPoint1: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.maxY - rect.height * 0.27),
        controlPoint2: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.34)
    )
    path.line(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.16))
    path.curve(
        to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY),
        controlPoint1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.06),
        controlPoint2: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY)
    )
    path.line(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY))
    path.curve(
        to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.16),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY),
        controlPoint2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.06)
    )
    strokePath(path, color: color, width: width)
}

func drawPeopleIcon(in rect: NSRect, color: NSColor, width: CGFloat) {
    let headRadius = rect.width * 0.14
    let centers = [
        CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.25),
        CGPoint(x: rect.minX + rect.width * 0.27, y: rect.maxY - rect.height * 0.34),
        CGPoint(x: rect.maxX - rect.width * 0.27, y: rect.maxY - rect.height * 0.34)
    ]

    for center in centers {
        let headRect = NSRect(
            x: center.x - headRadius,
            y: center.y - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        )
        strokePath(NSBezierPath(ovalIn: headRect), color: color, width: width)
    }

    let body = NSBezierPath()
    body.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.08))
    body.curve(
        to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.08),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.44),
        controlPoint2: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY + rect.height * 0.44)
    )
    strokePath(body, color: color, width: width)
}

func drawGearIcon(in rect: NSRect, color: NSColor, width: CGFloat) {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outerRadius = min(rect.width, rect.height) * 0.42
    let innerRadius = outerRadius * 0.70
    let toothCount = 8
    let gear = NSBezierPath()

    for index in 0..<(toothCount * 2) {
        let angle = CGFloat(index) * .pi / CGFloat(toothCount) - .pi / 2
        let radius = index % 2 == 0 ? outerRadius : innerRadius
        let point = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )

        if index == 0 {
            gear.move(to: point)
        } else {
            gear.line(to: point)
        }
    }

    gear.close()
    strokePath(gear, color: color, width: width)

    let hubRadius = outerRadius * 0.26
    let hubRect = NSRect(x: center.x - hubRadius, y: center.y - hubRadius, width: hubRadius * 2, height: hubRadius * 2)
    strokePath(NSBezierPath(ovalIn: hubRect), color: color, width: width)
}

func drawArrow(size: CGFloat, from start: CGPoint, to end: CGPoint, color: NSColor) {
    let width = scaled(size, 0.013, minimum: 2.2)
    drawLine(from: start, to: end, color: color, width: width, dash: [scaled(size, 0.026), scaled(size, 0.018)])

    let arrowLength = scaled(size, 0.050, minimum: 9)
    let arrowHeight = scaled(size, 0.036, minimum: 7)
    let tip = end

    let arrow = NSBezierPath()
    arrow.move(to: CGPoint(x: tip.x - arrowLength, y: tip.y + arrowHeight))
    arrow.line(to: tip)
    arrow.line(to: CGPoint(x: tip.x - arrowLength, y: tip.y - arrowHeight))
    strokePath(arrow, color: color, width: width)
}

func drawIcon(pixels: Int) throws -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(pixels)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.26)
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.020)
    shadow.shadowBlurRadius = size * 0.040
    shadow.set()

    let bodyRect = rect.insetBy(dx: size * 0.095, dy: size * 0.095)
    let cornerRadius = size * 0.205
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGradient(colors: [
        NSColor(calibratedRed: 0.055, green: 0.245, blue: 0.590, alpha: 1),
        NSColor(calibratedRed: 0.090, green: 0.390, blue: 0.850, alpha: 1),
        NSColor(calibratedRed: 0.105, green: 0.500, blue: 0.980, alpha: 1)
    ])?.draw(in: bodyPath, angle: -36)

    NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

    bodyPath.addClip()

    drawGrid(in: bodyRect.insetBy(dx: size * 0.020, dy: size * 0.020), size: size)

    let outlineColor = NSColor.white.withAlphaComponent(0.68)
    let blueprintColor = NSColor.white.withAlphaComponent(0.78)
    let faintColor = NSColor.white.withAlphaComponent(0.32)
    let lineWidth = scaled(size, 0.0065, minimum: 1.25)
    let panelWidth = size * 0.265
    let panelRect = NSRect(
        x: bodyRect.maxX - panelWidth - size * 0.048,
        y: bodyRect.minY + size * 0.080,
        width: panelWidth,
        height: bodyRect.height - size * 0.160
    )
    let leftBlueprintRect = NSRect(
        x: bodyRect.minX + size * 0.070,
        y: panelRect.minY,
        width: panelRect.minX - bodyRect.minX - size * 0.115,
        height: panelRect.height
    )

    let innerOutline = NSBezierPath(roundedRect: bodyRect.insetBy(dx: size * 0.042, dy: size * 0.042), xRadius: size * 0.155, yRadius: size * 0.155)
    strokePath(innerOutline, color: outlineColor.withAlphaComponent(0.40), width: scaled(size, 0.0042, minimum: 0.9))

    let planPath = NSBezierPath(roundedRect: leftBlueprintRect, xRadius: size * 0.065, yRadius: size * 0.065)
    strokePath(
        planPath,
        color: outlineColor.withAlphaComponent(0.62),
        width: lineWidth,
        dash: [scaled(size, 0.035), scaled(size, 0.020)]
    )

    let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: size * 0.070, yRadius: size * 0.070)
    fillRounded(panelRect, radius: size * 0.070, color: NSColor(calibratedWhite: 1, alpha: 0.055))
    strokePath(panelPath, color: blueprintColor, width: lineWidth)

    drawArrow(
        size: size,
        from: CGPoint(x: leftBlueprintRect.minX + size * 0.018, y: bodyRect.midY),
        to: CGPoint(x: panelRect.minX - size * 0.030, y: bodyRect.midY),
        color: outlineColor
    )

    drawLine(
        from: CGPoint(x: panelRect.minX - size * 0.006, y: panelRect.minY + size * 0.015),
        to: CGPoint(x: panelRect.minX - size * 0.006, y: panelRect.maxY - size * 0.015),
        color: faintColor,
        width: scaled(size, 0.0035, minimum: 0.8)
    )

    let iconSize = panelRect.width * 0.30
    let iconX = panelRect.midX - iconSize / 2
    let iconColor = NSColor.white.withAlphaComponent(0.88)
    let iconWidth = scaled(size, 0.0072, minimum: 1.35)
    let iconCenters = [
        panelRect.maxY - panelRect.height * 0.155,
        panelRect.maxY - panelRect.height * 0.365,
        panelRect.maxY - panelRect.height * 0.585,
        panelRect.maxY - panelRect.height * 0.805
    ]

    drawAppsGridIcon(
        in: NSRect(x: iconX, y: iconCenters[0] - iconSize / 2, width: iconSize, height: iconSize),
        color: iconColor,
        width: iconWidth
    )
    drawFolderIcon(
        in: NSRect(x: iconX - iconSize * 0.06, y: iconCenters[1] - iconSize * 0.39, width: iconSize * 1.12, height: iconSize * 0.82),
        color: iconColor,
        width: iconWidth
    )
    drawPeopleIcon(
        in: NSRect(x: iconX - iconSize * 0.08, y: iconCenters[2] - iconSize * 0.44, width: iconSize * 1.16, height: iconSize * 0.88),
        color: iconColor,
        width: iconWidth
    )
    drawGearIcon(
        in: NSRect(x: iconX - iconSize * 0.01, y: iconCenters[3] - iconSize * 0.50, width: iconSize * 1.02, height: iconSize * 1.02),
        color: iconColor,
        width: iconWidth
    )

    strokePath(bodyPath, color: NSColor.white.withAlphaComponent(0.30), width: scaled(size, 0.006, minimum: 1))

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

for spec in specs {
    let data = try drawIcon(pixels: spec.pixels)
    try data.write(to: iconsetURL.appendingPathComponent(spec.filename), options: .atomic)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    fputs("iconutil failed\n", stderr)
    exit(process.terminationStatus)
}
