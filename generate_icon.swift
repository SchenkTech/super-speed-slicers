#!/usr/bin/env swift
// generate_icon.swift — run with: swift generate_icon.swift
// Generates the 1024×1024 Super Speed Slicers app icon.

import CoreGraphics
import CoreText
import ImageIO
import Foundation

let size: CGFloat = 1024
let center = CGPoint(x: size / 2, y: size / 2)

// Create context
let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil,
    width:  Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: Int(size) * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

ctx.saveGState()

// ── Background ──────────────────────────────────────────────────────────────
// Deep navy-to-black radial gradient
let bgColors = [
    CGColor(red: 0.10, green: 0.12, blue: 0.25, alpha: 1),
    CGColor(red: 0.03, green: 0.03, blue: 0.08, alpha: 1)
]
let bgLocations: [CGFloat] = [0, 1]
let bgGradient = CGGradient(colorsSpace: colorSpace,
                             colors: bgColors as CFArray,
                             locations: bgLocations)!

ctx.drawRadialGradient(bgGradient,
                        startCenter: CGPoint(x: size * 0.5, y: size * 0.62),
                        startRadius: 0,
                        endCenter:   CGPoint(x: size * 0.5, y: size * 0.5),
                        endRadius:   size * 0.72,
                        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

// ── Subtle speed lines in background ───────────────────────────────────────
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.04))
ctx.setLineWidth(1.5)
for i in 0..<14 {
    let y = size * 0.18 + CGFloat(i) * (size * 0.64 / 13)
    let xOff = (CGFloat(i) - 6.5) * 8
    ctx.move(to: CGPoint(x: 80 + xOff, y: y))
    ctx.addLine(to: CGPoint(x: size - 80 + xOff, y: y))
}
ctx.strokePath()

// ── Glow disc behind knives ─────────────────────────────────────────────────
let glowColors = [
    CGColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 0.28),
    CGColor(red: 1.0, green: 0.75, blue: 0.0,  alpha: 0.0)
]
let glowLocations: [CGFloat] = [0, 1]
let glowGradient = CGGradient(colorsSpace: colorSpace,
                               colors: glowColors as CFArray,
                               locations: glowLocations)!
ctx.drawRadialGradient(glowGradient,
                        startCenter: center, startRadius: 0,
                        endCenter:   center, endRadius:   size * 0.38,
                        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

// ── Helper: draw one knife (blade pointing up) ──────────────────────────────
func drawKnife(in ctx: CGContext,
               cx: CGFloat, cy: CGFloat,
               angle: CGFloat,
               length: CGFloat) {

    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: angle)

    let bladeW:   CGFloat = length * 0.075
    let bladeL:   CGFloat = length * 0.60
    let handleW:  CGFloat = length * 0.10
    let handleL:  CGFloat = length * 0.32
    let guardW:   CGFloat = length * 0.16
    let guardH:   CGFloat = length * 0.045
    let tipH:     CGFloat = length * 0.11  // pointed tip above blade rect

    // ---- Blade fill (silver gradient) ----
    let bladeColors = [
        CGColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1),
        CGColor(red: 0.55, green: 0.60, blue: 0.68, alpha: 1),
        CGColor(red: 0.80, green: 0.82, blue: 0.88, alpha: 1)
    ]
    let bladeLocs: [CGFloat] = [0, 0.45, 1]
    let bladeGrad = CGGradient(colorsSpace: colorSpace,
                                colors: bladeColors as CFArray,
                                locations: bladeLocs)!

    // Full blade path = rectangle + triangle tip
    let bladePath = CGMutablePath()
    bladePath.move(to:    CGPoint(x: -bladeW / 2, y: 0))
    bladePath.addLine(to: CGPoint(x:  bladeW / 2, y: 0))
    bladePath.addLine(to: CGPoint(x:  bladeW * 0.3, y: bladeL))
    // Tip
    bladePath.addLine(to: CGPoint(x:  0,           y: bladeL + tipH))
    bladePath.addLine(to: CGPoint(x: -bladeW * 0.3, y: bladeL))
    bladePath.closeSubpath()

    ctx.saveGState()
    ctx.addPath(bladePath)
    ctx.clip()
    ctx.drawLinearGradient(bladeGrad,
                            start: CGPoint(x: -bladeW, y: 0),
                            end:   CGPoint(x:  bladeW, y: 0),
                            options: [])
    ctx.restoreGState()

    // Blade edge highlight (bright white line on right edge)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.65))
    ctx.setLineWidth(bladeW * 0.14)
    ctx.move(to:    CGPoint(x:  bladeW * 0.28, y: bladeL * 0.05))
    ctx.addLine(to: CGPoint(x:  bladeW * 0.20, y: bladeL))
    ctx.addLine(to: CGPoint(x:  0,              y: bladeL + tipH))
    ctx.strokePath()

    // Blade outline
    ctx.setStrokeColor(CGColor(red: 0.25, green: 0.28, blue: 0.35, alpha: 0.8))
    ctx.setLineWidth(2.5)
    ctx.addPath(bladePath)
    ctx.strokePath()

    // ---- Guard ----
    let guardRect = CGRect(x: -guardW / 2, y: -guardH / 2, width: guardW, height: guardH)
    let guardColors = [
        CGColor(red: 1.0, green: 0.80, blue: 0.10, alpha: 1),
        CGColor(red: 0.85, green: 0.55, blue: 0.0, alpha: 1)
    ]
    let guardLocs: [CGFloat] = [0, 1]
    let guardGrad = CGGradient(colorsSpace: colorSpace,
                                colors: guardColors as CFArray,
                                locations: guardLocs)!
    ctx.saveGState()
    let guardPath = CGPath(roundedRect: guardRect, cornerWidth: guardH * 0.35,
                           cornerHeight: guardH * 0.35, transform: nil)
    ctx.addPath(guardPath)
    ctx.clip()
    ctx.drawLinearGradient(guardGrad,
                            start: CGPoint(x: 0,  y: -guardH),
                            end:   CGPoint(x: 0,  y:  guardH),
                            options: [])
    ctx.restoreGState()
    ctx.setStrokeColor(CGColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1))
    ctx.setLineWidth(2)
    ctx.addPath(guardPath)
    ctx.strokePath()

    // ---- Handle ----
    let handleRect = CGRect(x: -handleW / 2, y: -guardH / 2 - handleL,
                             width: handleW, height: handleL)
    let handleColors = [
        CGColor(red: 0.22, green: 0.12, blue: 0.06, alpha: 1),
        CGColor(red: 0.42, green: 0.22, blue: 0.10, alpha: 1),
        CGColor(red: 0.22, green: 0.12, blue: 0.06, alpha: 1)
    ]
    let handleLocs: [CGFloat] = [0, 0.5, 1]
    let handleGrad = CGGradient(colorsSpace: colorSpace,
                                 colors: handleColors as CFArray,
                                 locations: handleLocs)!
    ctx.saveGState()
    let handlePath = CGPath(roundedRect: handleRect,
                             cornerWidth: handleW * 0.25,
                             cornerHeight: handleW * 0.25, transform: nil)
    ctx.addPath(handlePath)
    ctx.clip()
    ctx.drawLinearGradient(handleGrad,
                            start: CGPoint(x: -handleW, y: 0),
                            end:   CGPoint(x:  handleW, y: 0),
                            options: [])
    ctx.restoreGState()

    // Handle wrapping lines (grip texture)
    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.30))
    ctx.setLineWidth(2.0)
    let wrapCount = 5
    for i in 0..<wrapCount {
        let wy = -guardH / 2 - handleL * 0.12 - CGFloat(i) * (handleL * 0.72 / CGFloat(wrapCount - 1))
        ctx.move(to:    CGPoint(x: -handleW / 2, y: wy))
        ctx.addLine(to: CGPoint(x:  handleW / 2, y: wy))
    }
    ctx.strokePath()

    // Handle outline
    ctx.setStrokeColor(CGColor(red: 0.10, green: 0.05, blue: 0.02, alpha: 0.9))
    ctx.setLineWidth(2.5)
    ctx.addPath(handlePath)
    ctx.strokePath()

    // Pommel (bottom cap)
    let pommelR: CGFloat = handleW * 0.6
    let pommelY = -guardH / 2 - handleL - pommelR * 0.5
    let pommelColors = [
        CGColor(red: 1.0, green: 0.80, blue: 0.10, alpha: 1),
        CGColor(red: 0.70, green: 0.45, blue: 0.0, alpha: 1)
    ]
    let pommelLocs: [CGFloat] = [0, 1]
    let pommelGrad = CGGradient(colorsSpace: colorSpace,
                                 colors: pommelColors as CFArray,
                                 locations: pommelLocs)!
    let pommelRect = CGRect(x: -pommelR, y: pommelY - pommelR,
                             width: pommelR * 2, height: pommelR * 2)
    ctx.saveGState()
    ctx.addEllipse(in: pommelRect)
    ctx.clip()
    ctx.drawLinearGradient(pommelGrad,
                            start: CGPoint(x: 0, y: pommelY - pommelR),
                            end:   CGPoint(x: 0, y: pommelY + pommelR),
                            options: [])
    ctx.restoreGState()
    ctx.setStrokeColor(CGColor(red: 0.5, green: 0.3, blue: 0.0, alpha: 1))
    ctx.setLineWidth(2)
    ctx.addEllipse(in: pommelRect)
    ctx.strokePath()

    ctx.restoreGState()
}

let knifeLen: CGFloat = size * 0.72

// Draw drop shadows first
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 14, height: -14), blur: 32,
              color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.65))
// Left knife (tilted ~45° left)
drawKnife(in: ctx, cx: center.x, cy: center.y,
          angle: -CGFloat.pi / 4,
          length: knifeLen)
// Right knife (tilted ~45° right)
drawKnife(in: ctx, cx: center.x, cy: center.y,
          angle: CGFloat.pi / 4,
          length: knifeLen)
ctx.restoreGState()

// Draw knives on top (no shadow)
drawKnife(in: ctx, cx: center.x, cy: center.y,
          angle: -CGFloat.pi / 4,
          length: knifeLen)
drawKnife(in: ctx, cx: center.x, cy: center.y,
          angle: CGFloat.pi / 4,
          length: knifeLen)

// ── Speed slash marks ────────────────────────────────────────────────────────
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 0.8, alpha: 0.18))
ctx.setLineWidth(4)
ctx.setLineCap(.round)
let slashes: [(CGPoint, CGPoint)] = [
    (CGPoint(x: size * 0.08, y: size * 0.52), CGPoint(x: size * 0.28, y: size * 0.42)),
    (CGPoint(x: size * 0.06, y: size * 0.60), CGPoint(x: size * 0.20, y: size * 0.52)),
    (CGPoint(x: size * 0.72, y: size * 0.58), CGPoint(x: size * 0.92, y: size * 0.48)),
    (CGPoint(x: size * 0.74, y: size * 0.66), CGPoint(x: size * 0.94, y: size * 0.58)),
]
for (a, b) in slashes {
    ctx.move(to: a); ctx.addLine(to: b)
}
ctx.strokePath()

// ── Title text at the bottom ─────────────────────────────────────────────────
let title     = "SUPER SPEED" as CFString
let titleSub  = "SLICERS"     as CFString
let titleFont = CTFontCreateWithName("AvenirNext-Heavy" as CFString, size * 0.095, nil)
let subFont   = CTFontCreateWithName("AvenirNext-Heavy" as CFString, size * 0.130, nil)

func drawCenteredText(_ text: CFString, font: CTFont, color: CGColor,
                      y: CGFloat, context: CGContext) {
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: color
    ]
    let attrString = CFAttributedStringCreate(nil, text, attrs as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attrString)
    let bounds = CTLineGetBoundsWithOptions(line, [])
    let x = (size - bounds.width) / 2
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, context)
}

// Shadow pass
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 3, height: -3), blur: 8,
              color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.8))
drawCenteredText(title,    font: titleFont,
                 color: CGColor(red: 1.0, green: 0.85, blue: 0.10, alpha: 1),
                 y: size * 0.145, context: ctx)
drawCenteredText(titleSub, font: subFont,
                 color: CGColor(red: 1.0, green: 0.85, blue: 0.10, alpha: 1),
                 y: size * 0.055, context: ctx)
ctx.restoreGState()

// ── Outer rounded-rect border vignette ─────────────────────────────────────
let vigColors = [
    CGColor(red: 0, green: 0, blue: 0, alpha: 0),
    CGColor(red: 0, green: 0, blue: 0, alpha: 0.45)
]
let vigLocs: [CGFloat] = [0, 1]
let vigGrad = CGGradient(colorsSpace: colorSpace,
                          colors: vigColors as CFArray,
                          locations: vigLocs)!
ctx.drawRadialGradient(vigGrad,
                        startCenter: center, startRadius: size * 0.28,
                        endCenter:   center, endRadius:   size * 0.72,
                        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

ctx.restoreGState()

// ── Save PNG ─────────────────────────────────────────────────────────────────
let image = ctx.makeImage()!
let outPath = "SuperSpeedSlicers/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
let url     = URL(fileURLWithPath: outPath)
let dest    = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)

print("✅  Icon written to \(outPath)")
