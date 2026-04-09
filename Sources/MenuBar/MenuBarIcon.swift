import Cocoa

/// Creates the ScreenDial menu bar icon as a template `NSImage`.
///
/// The design is a monitor outline with a small half-sun (brightness)
/// symbol at the lower-right corner, slightly overlapping the bezel.
/// This conveys "display + brightness control" at a glance. The image
/// is marked `isTemplate = true`, so AppKit automatically tints it for
/// dark/light menu bars and highlight states — never color it manually.
///
/// All metrics are tuned for an 18pt reference canvas and scale linearly.
enum MenuBarIcon {

    /// Returns a new template image. `size` defaults to `18`, which matches
    /// the standard `NSStatusItem.squareLength` on macOS.
    static func make(size: CGFloat = 18) -> NSImage {
        let nsSize = NSSize(width: size, height: size)
        let image = NSImage(size: nsSize, flipped: true) { rect in
            draw(in: rect)
            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Drawing

    private static func draw(in rect: CGRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let scale = rect.width / 18.0
        let lineWidth = 1.0 * scale
        let cornerRadius = 1.5 * scale

        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        // Monitor body (rounded rectangle)
        let monitorRect = CGRect(
            x: 1.0 * scale,
            y: 2.0 * scale,
            width: 14.0 * scale,
            height: 10.0 * scale
        )
        let monitorPath = CGPath(
            roundedRect: monitorRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2),
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        ctx.addPath(monitorPath)
        ctx.strokePath()

        // Stand neck
        let neckX = 8.0 * scale
        ctx.move(to: CGPoint(x: neckX, y: 12.0 * scale))
        ctx.addLine(to: CGPoint(x: neckX, y: 14.0 * scale))
        ctx.strokePath()

        // Stand base
        ctx.move(to: CGPoint(x: 5.0 * scale, y: 14.0 * scale))
        ctx.addLine(to: CGPoint(x: 11.0 * scale, y: 14.0 * scale))
        ctx.strokePath()

        // Half-sun dial symbol (lower-right, overlapping monitor corner)
        // Represents brightness/display tuning
        let sunCenter = CGPoint(x: 14.0 * scale, y: 12.0 * scale)
        let sunRadius = 2.0 * scale
        let rayLength = 1.5 * scale
        let rayOffset = sunRadius + 0.8 * scale

        // Clear area behind the sun so it doesn't overlap monitor stroke
        ctx.saveGState()
        ctx.setBlendMode(.clear)
        let clearRadius = sunRadius + 2.0 * scale
        ctx.addArc(
            center: sunCenter,
            radius: clearRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        ctx.fillPath()
        ctx.restoreGState()

        // Sun circle (filled)
        ctx.addArc(
            center: sunCenter,
            radius: sunRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        ctx.fillPath()

        // Sun rays (6 rays arranged around, skip bottom-left area for cleanliness)
        let rayAngles: [CGFloat] = [0, .pi / 3, 2 * .pi / 3, .pi, 4 * .pi / 3, 5 * .pi / 3]
        for angle in rayAngles {
            let startX = sunCenter.x + cos(angle) * rayOffset
            let startY = sunCenter.y + sin(angle) * rayOffset
            let endX = sunCenter.x + cos(angle) * (rayOffset + rayLength)
            let endY = sunCenter.y + sin(angle) * (rayOffset + rayLength)
            ctx.move(to: CGPoint(x: startX, y: startY))
            ctx.addLine(to: CGPoint(x: endX, y: endY))
        }
        ctx.strokePath()
    }
}
