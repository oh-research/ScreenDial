import Cocoa

/// Creates the ScreenDial menu bar icon as a template `NSImage`.
///
/// The design is a rounded-rectangle screen enclosing a dial — the app's
/// signature motif. A faint tick ring sits behind the dial face; the
/// outline, needle, and pivot carry the visual weight. All metrics scale
/// from an 18pt reference canvas (the standard `NSStatusItem.squareLength`).
///
/// The image is marked `isTemplate = true`, so AppKit automatically tints
/// it for dark/light menu bars and highlight states — never color it
/// manually.
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

        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setFillColor(NSColor.black.cgColor)

        drawScreenBorder(ctx, scale: scale)
        drawTickRing(ctx, scale: scale)
        drawDial(ctx, scale: scale)
    }

    private static func drawScreenBorder(_ ctx: CGContext, scale: CGFloat) {
        let lineWidth = 1.0 * scale
        let cornerRadius = 3.0 * scale
        let inset = 1.0 * scale
        let outer = CGRect(
            x: inset,
            y: inset,
            width: 18 * scale - inset * 2,
            height: 18 * scale - inset * 2
        ).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = CGPath(
            roundedRect: outer,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        ctx.setAlpha(1.0)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(path)
        ctx.strokePath()
    }

    private static func drawTickRing(_ ctx: CGContext, scale: CGFloat) {
        let center = CGPoint(x: 9 * scale, y: 9 * scale)
        let innerRadius = 5.5 * scale
        let outerRadius = 6.2 * scale
        let tickCount = 12

        ctx.setAlpha(0.35)
        ctx.setLineWidth(0.6 * scale)
        for i in 0..<tickCount {
            let angle = CGFloat(i) * (.pi * 2) / CGFloat(tickCount)
            let dx = cos(angle)
            let dy = sin(angle)
            ctx.move(to: CGPoint(
                x: center.x + dx * innerRadius,
                y: center.y + dy * innerRadius
            ))
            ctx.addLine(to: CGPoint(
                x: center.x + dx * outerRadius,
                y: center.y + dy * outerRadius
            ))
        }
        ctx.strokePath()
        ctx.setAlpha(1.0)
    }

    private static func drawDial(_ ctx: CGContext, scale: CGFloat) {
        let center = CGPoint(x: 9 * scale, y: 9 * scale)
        let radius = 4.5 * scale

        // Dial face outline
        ctx.setLineWidth(1.0 * scale)
        ctx.addArc(
            center: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        ctx.strokePath()

        // Needle pointing upper-right (flipped coords: negative y = up)
        let angle = -CGFloat.pi / 4
        let tip = CGPoint(
            x: center.x + cos(angle) * (radius - 0.8 * scale),
            y: center.y + sin(angle) * (radius - 0.8 * scale)
        )
        ctx.setLineWidth(1.6 * scale)
        ctx.move(to: center)
        ctx.addLine(to: tip)
        ctx.strokePath()

        // Pivot dot
        ctx.addArc(
            center: center,
            radius: 0.7 * scale,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        ctx.fillPath()
    }
}
