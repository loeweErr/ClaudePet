import AppKit

enum CatPose {
    case idle, sleep, wave, work, eat, play
}

/// Pixel-art cat renderer. View box is 64×80; the view scales this up.
/// Coords use top-left origin (Y down) — view sets isFlipped = true.
enum CatRenderer {

    // ===== Color palette (sourced from the active skin) =====
    // Names are kept (orange/cream/etc.) for legacy reasons even though the
    // active skin may map them to non-orange / non-cream colors.
    private static var p: CatPalette { SkinManager.shared.active.palette }
    static var orange:      NSColor { p.primaryColor }
    static var orangeDark:  NSColor { p.primaryDarkColor }
    static var orangeLight: NSColor { p.primaryLightColor }
    static var cream:       NSColor { p.bellyColor }
    static var pink:        NSColor { p.cheekColor }
    static var pinkDeep:    NSColor { p.cheekDeepColor }
    static var eye:         NSColor { p.eyeColor }
    static var white:       NSColor { p.highlightColor }
    static var irisGreen:   NSColor { p.irisColor }
    static var gear:        NSColor { p.accentColor }

    // ===== Geometry helpers =====
    /// Draw a filled rect in viewBox coords.
    static func rect(_ ctx: CGContext, _ x: CGFloat, _ y: CGFloat,
                     _ w: CGFloat, _ h: CGFloat,
                     _ color: NSColor, alpha: CGFloat = 1) {
        ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
        ctx.fill(CGRect(x: x, y: y, width: w, height: h))
    }

    /// Draw a filled polygon in viewBox coords.
    static func poly(_ ctx: CGContext, _ pts: [(CGFloat, CGFloat)], _ color: NSColor) {
        ctx.setFillColor(color.cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
        for p in pts.dropFirst() { ctx.addLine(to: CGPoint(x: p.0, y: p.1)) }
        ctx.closePath()
        ctx.fillPath()
    }

    // ===== Main entry =====
    static func draw(pose: CatPose, ctx: CGContext, scale: CGFloat,
                     blink: Bool, gearAngle: CGFloat, waveAngle: CGFloat,
                     bobOffset: CGFloat) {
        ctx.saveGState()
        // Translate (in view points) then scale viewBox to view bounds.
        ctx.translateBy(x: 0, y: bobOffset)
        ctx.scaleBy(x: scale, y: scale)

        switch pose {
        case .idle:  drawIdle(ctx, blink: blink)
        case .sleep: drawSleep(ctx)
        case .wave:  drawWave(ctx, waveAngle: waveAngle)
        case .work:  drawWork(ctx, gearAngle: gearAngle)
        case .eat:   drawEat(ctx, bobOffset: bobOffset)
        case .play:  drawPlay(ctx, waveAngle: waveAngle)
        }
        ctx.restoreGState()
    }

    // ===== IDLE pose =====
    static func drawIdle(_ ctx: CGContext, blink: Bool) {
        // Tail (behind body)
        rect(ctx, 50, 48, 4, 4, orange)
        rect(ctx, 54, 44, 4, 4, orange)
        rect(ctx, 58, 40, 4, 4, orange)
        rect(ctx, 58, 36, 4, 4, orange)
        rect(ctx, 54, 32, 4, 4, orangeLight)

        // Body
        rect(ctx, 10, 40, 40, 28, orange)
        rect(ctx, 14, 36, 32, 4,  orange)
        rect(ctx, 14, 36, 32, 2,  orangeLight)
        rect(ctx, 18, 46, 24, 18, cream)             // belly

        // Front paws
        rect(ctx, 14, 64, 8, 6, orange)
        rect(ctx, 38, 64, 8, 6, orange)
        rect(ctx, 14, 68, 8, 2, cream)
        rect(ctx, 38, 68, 8, 2, cream)

        // Ears
        poly(ctx, [(10,16),(10,4),(20,14)], orange)
        poly(ctx, [(54,16),(54,4),(44,14)], orange)
        poly(ctx, [(13,14),(13,8),(17,13)], pink)
        poly(ctx, [(51,14),(51,8),(47,13)], pink)

        // Head
        rect(ctx, 10, 14, 44, 26, orange)
        rect(ctx, 12, 14, 40, 2,  orangeLight)
        rect(ctx, 14, 30, 4, 2,   pink, alpha: 0.6)  // cheek
        rect(ctx, 46, 30, 4, 2,   pink, alpha: 0.6)

        // Stripes
        for cx in [20.0, 28.0, 34.0, 42.0] as [CGFloat] {
            rect(ctx, cx, 14, 2, 4, orangeDark, alpha: 0.5)
        }
        rect(ctx, 16, 38, 2, 3, orangeDark, alpha: 0.4)
        rect(ctx, 44, 38, 2, 3, orangeDark, alpha: 0.4)

        // Eyes
        if blink {
            rect(ctx, 18, 26, 8, 2, eye)
            rect(ctx, 38, 26, 8, 2, eye)
        } else {
            rect(ctx, 18, 22, 8, 8, eye)            // eye background
            rect(ctx, 38, 22, 8, 8, eye)
            rect(ctx, 20, 24, 4, 4, irisGreen)      // iris
            rect(ctx, 40, 24, 4, 4, irisGreen)
            rect(ctx, 21, 25, 2, 2, eye)            // pupil
            rect(ctx, 41, 25, 2, 2, eye)
            rect(ctx, 22, 24, 1, 1, white)          // highlight
            rect(ctx, 42, 24, 1, 1, white)
        }

        // Nose
        poly(ctx, [(30,32),(34,32),(32,35)], pinkDeep)
        // Mouth
        rect(ctx, 30, 35, 1, 2, eye)
        rect(ctx, 33, 35, 1, 2, eye)
        rect(ctx, 28, 37, 3, 1, eye)
        rect(ctx, 33, 37, 3, 1, eye)

        // Whiskers
        rect(ctx, 6, 30, 6, 1, cream, alpha: 0.8)
        rect(ctx, 6, 33, 6, 1, cream, alpha: 0.8)
        rect(ctx, 52, 30, 6, 1, cream, alpha: 0.8)
        rect(ctx, 52, 33, 6, 1, cream, alpha: 0.8)
    }

    // ===== SLEEP pose =====
    static func drawSleep(_ ctx: CGContext) {
        // Curled tail
        rect(ctx, 46, 56, 4, 4, orange)
        rect(ctx, 50, 56, 4, 4, orange)
        rect(ctx, 54, 56, 4, 4, orange)
        rect(ctx, 56, 52, 4, 4, orangeLight)

        // Curled body
        rect(ctx, 14, 48, 44, 20, orange)
        rect(ctx, 10, 52, 4, 12,  orange)
        rect(ctx, 58, 52, 4, 12,  orange)
        rect(ctx, 14, 46, 44, 2,  orangeLight)
        rect(ctx, 20, 56, 32, 10, cream)              // belly

        // Stripes on body
        for cx in [20.0, 28.0, 36.0, 44.0] as [CGFloat] {
            rect(ctx, cx, 48, 3, 3, orangeDark, alpha: 0.4)
        }

        // Tucked head
        rect(ctx, 16, 38, 20, 14, orange)
        poly(ctx, [(16,40),(16,32),(22,40)], orange)
        poly(ctx, [(36,40),(36,32),(30,40)], orange)
        poly(ctx, [(18,38),(18,34),(20,38)], pink)
        poly(ctx, [(33,38),(33,34),(31,38)], pink)

        // Closed eyes
        rect(ctx, 18, 44, 4, 1, eye)
        rect(ctx, 30, 44, 4, 1, eye)
        rect(ctx, 25, 47, 2, 1, pinkDeep)

        // Z Z Z
        drawText(ctx, "z", 40, 32, size: 8, color: white, alpha: 0.85)
        drawText(ctx, "Z", 46, 26, size: 11, color: white, alpha: 0.7)
        drawText(ctx, "z", 52, 18, size: 14, color: white, alpha: 0.5)
    }

    // ===== WAVE pose =====
    static func drawWave(_ ctx: CGContext, waveAngle: CGFloat) {
        // Tail
        rect(ctx, 50, 48, 4, 4, orange)
        rect(ctx, 54, 44, 4, 4, orange)
        rect(ctx, 58, 40, 4, 4, orange)
        rect(ctx, 58, 36, 4, 4, orange)
        rect(ctx, 54, 32, 4, 4, orangeLight)

        // Body
        rect(ctx, 10, 40, 40, 28, orange)
        rect(ctx, 14, 36, 32, 4, orange)
        rect(ctx, 14, 36, 32, 2, orangeLight)
        rect(ctx, 18, 46, 24, 18, cream)
        rect(ctx, 14, 64, 8, 6, orange)
        rect(ctx, 14, 68, 8, 2, cream)

        // Raised waving arm (rotated around pivot)
        ctx.saveGState()
        ctx.translateBy(x: 45, y: 42)
        ctx.rotate(by: waveAngle * .pi / 180)
        ctx.translateBy(x: -45, y: -42)
        rect(ctx, 42, 22, 6, 20, orange)
        rect(ctx, 40, 18, 10, 6, orange)
        ctx.restoreGState()

        // Head
        poly(ctx, [(10,16),(10,4),(20,14)], orange)
        poly(ctx, [(54,16),(54,4),(44,14)], orange)
        poly(ctx, [(13,14),(13,8),(17,13)], pink)
        poly(ctx, [(51,14),(51,8),(47,13)], pink)
        rect(ctx, 10, 14, 44, 26, orange)
        rect(ctx, 12, 14, 40, 2,  orangeLight)

        for cx in [20.0, 28.0, 34.0, 42.0] as [CGFloat] {
            rect(ctx, cx, 14, 2, 4, orangeDark, alpha: 0.5)
        }

        // Happy curved eyes
        drawCurvedEye(ctx, cx: 22, cy: 25)
        drawCurvedEye(ctx, cx: 42, cy: 25)

        // Pink cheeks
        rect(ctx, 14, 30, 4, 3, pink, alpha: 0.7)
        rect(ctx, 46, 30, 4, 3, pink, alpha: 0.7)

        // Nose + smile
        poly(ctx, [(30,32),(34,32),(32,35)], pinkDeep)
        drawSmile(ctx)
    }

    private static func drawCurvedEye(_ ctx: CGContext, cx: CGFloat, cy: CGFloat) {
        // ^^ shape
        rect(ctx, cx-3, cy,   1, 1, eye)
        rect(ctx, cx-2, cy-1, 1, 1, eye)
        rect(ctx, cx-1, cy-2, 1, 1, eye)
        rect(ctx, cx,   cy-2, 1, 1, eye)
        rect(ctx, cx+1, cy-2, 1, 1, eye)
        rect(ctx, cx+2, cy-1, 1, 1, eye)
        rect(ctx, cx+3, cy,   1, 1, eye)
    }

    private static func drawSmile(_ ctx: CGContext) {
        rect(ctx, 28, 37, 1, 1, eye)
        rect(ctx, 29, 38, 1, 1, eye)
        rect(ctx, 30, 39, 4, 1, eye)
        rect(ctx, 34, 38, 1, 1, eye)
        rect(ctx, 35, 37, 1, 1, eye)
    }

    // ===== WORK pose (focused, gear spinning above head) =====
    static func drawWork(_ ctx: CGContext, gearAngle: CGFloat) {
        // Alert tail (straight up)
        rect(ctx, 54, 44, 4, 4, orange)
        rect(ctx, 56, 36, 4, 8, orange)
        rect(ctx, 56, 28, 4, 8, orange)
        rect(ctx, 56, 22, 4, 6, orangeLight)

        rect(ctx, 10, 40, 40, 28, orange)
        rect(ctx, 14, 36, 32, 4,  orange)
        rect(ctx, 14, 36, 32, 2,  orangeLight)
        rect(ctx, 18, 46, 24, 18, cream)
        rect(ctx, 14, 64, 8, 6,   orange)
        rect(ctx, 38, 64, 8, 6,   orange)
        rect(ctx, 14, 68, 8, 2,   cream)
        rect(ctx, 38, 68, 8, 2,   cream)

        poly(ctx, [(10,16),(10,4),(20,14)], orange)
        poly(ctx, [(54,16),(54,4),(44,14)], orange)
        poly(ctx, [(13,14),(13,8),(17,13)], pink)
        poly(ctx, [(51,14),(51,8),(47,13)], pink)
        rect(ctx, 10, 14, 44, 26, orange)
        rect(ctx, 12, 14, 40, 2, orangeLight)

        for cx in [20.0, 28.0, 34.0, 42.0] as [CGFloat] {
            rect(ctx, cx, 14, 2, 4, orangeDark, alpha: 0.5)
        }

        // Wide focused eyes
        rect(ctx, 18, 22, 8, 10, eye)
        rect(ctx, 38, 22, 8, 10, eye)
        rect(ctx, 20, 24, 4, 6, irisGreen)
        rect(ctx, 40, 24, 4, 6, irisGreen)
        rect(ctx, 21, 26, 2, 3, eye)
        rect(ctx, 41, 26, 2, 3, eye)
        rect(ctx, 22, 24, 1, 1, white)
        rect(ctx, 42, 24, 1, 1, white)

        poly(ctx, [(30,34),(34,34),(32,37)], pinkDeep)
        rect(ctx, 30, 38, 4, 1, eye)

        // Spinning gear above head
        ctx.saveGState()
        ctx.translateBy(x: 32, y: -2)
        ctx.rotate(by: gearAngle * .pi / 180)
        // Gear ring (approximated by overlapping rects + center hole)
        ctx.setStrokeColor(gear.cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: CGRect(x: -5, y: -5, width: 10, height: 10))
        // Teeth
        rect(ctx, -1, -8, 2, 3, gear)
        rect(ctx, -1,  5, 2, 3, gear)
        rect(ctx, -8, -1, 3, 2, gear)
        rect(ctx,  5, -1, 3, 2, gear)
        ctx.restoreGState()
    }

    // ===== EAT pose (head bowed over a bowl) =====
    static func drawEat(_ ctx: CGContext, bobOffset: CGFloat) {
        // Tail (gently curled)
        rect(ctx, 50, 50, 4, 4, orange)
        rect(ctx, 54, 46, 4, 4, orange)
        rect(ctx, 58, 42, 4, 4, orange)

        // Body (a bit lower, head bowed)
        rect(ctx, 10, 44, 40, 24, orange)
        rect(ctx, 14, 40, 32, 4, orange)
        rect(ctx, 14, 40, 32, 2, orangeLight)
        rect(ctx, 18, 50, 24, 14, cream)

        // Front paws braced
        rect(ctx, 14, 64, 8, 6, orange)
        rect(ctx, 38, 64, 8, 6, orange)
        rect(ctx, 14, 68, 8, 2, cream)
        rect(ctx, 38, 68, 8, 2, cream)

        // Head bowed (lower than idle)
        poly(ctx, [(10,22),(10,10),(20,20)], orange)
        poly(ctx, [(54,22),(54,10),(44,20)], orange)
        poly(ctx, [(13,20),(13,14),(17,19)], pink)
        poly(ctx, [(51,20),(51,14),(47,19)], pink)
        rect(ctx, 10, 20, 44, 24, orange)
        rect(ctx, 12, 20, 40, 2, orangeLight)

        for cx in [20.0, 28.0, 34.0, 42.0] as [CGFloat] {
            rect(ctx, cx, 20, 2, 4, orangeDark, alpha: 0.5)
        }

        // Closed eyes (eating peacefully)
        rect(ctx, 18, 32, 8, 2, eye)
        rect(ctx, 38, 32, 8, 2, eye)

        // Tongue/mouth open
        rect(ctx, 30, 38, 4, 1, pinkDeep)
        rect(ctx, 28, 39, 8, 2, pink)
        rect(ctx, 28, 39, 8, 1, pinkDeep, alpha: 0.6)

        // Whiskers
        rect(ctx, 6, 36, 6, 1, cream, alpha: 0.8)
        rect(ctx, 52, 36, 6, 1, cream, alpha: 0.8)

        // The bowl (under the head)
        let bowlColor = NSColor(red: 0.42, green: 0.62, blue: 0.80, alpha: 1)
        let bowlDark  = NSColor(red: 0.26, green: 0.42, blue: 0.60, alpha: 1)
        let foodColor = NSColor(red: 0.78, green: 0.52, blue: 0.34, alpha: 1)
        // bowl base (trapezoid look via stacked rects)
        rect(ctx, 18, 60, 28, 2, bowlDark)
        rect(ctx, 20, 62, 24, 6, bowlColor)
        rect(ctx, 22, 68, 20, 2, bowlDark)
        // food inside
        rect(ctx, 22, 58, 20, 4, foodColor)
        rect(ctx, 24, 56, 4, 2,  foodColor)
        rect(ctx, 30, 56, 4, 2,  foodColor)
        rect(ctx, 36, 56, 4, 2,  foodColor)
    }

    // ===== PLAY pose (sitting up, paw raised at yarn) =====
    static func drawPlay(_ ctx: CGContext, waveAngle: CGFloat) {
        // Tail held up alertly
        rect(ctx, 54, 44, 4, 4, orange)
        rect(ctx, 56, 36, 4, 8, orange)
        rect(ctx, 56, 28, 4, 8, orange)
        rect(ctx, 56, 24, 4, 4, orangeLight)

        // Body (sitting upright, taller, narrower)
        rect(ctx, 16, 42, 28, 26, orange)
        rect(ctx, 20, 38, 20, 4,  orange)
        rect(ctx, 20, 38, 20, 2,  orangeLight)
        rect(ctx, 22, 48, 16, 14, cream)

        // Two back legs at the bottom
        rect(ctx, 18, 64, 10, 6, orange)
        rect(ctx, 32, 64, 10, 6, orange)
        rect(ctx, 18, 68, 10, 2, cream)
        rect(ctx, 32, 68, 10, 2, cream)

        // Standing paw (under body)
        rect(ctx, 18, 50, 6, 14, orange)
        rect(ctx, 18, 64, 6, 4,  orange)

        // Raised paw (animated bat)
        ctx.saveGState()
        ctx.translateBy(x: 42, y: 44)
        ctx.rotate(by: waveAngle * .pi / 180)
        ctx.translateBy(x: -42, y: -44)
        rect(ctx, 38, 26, 6, 20, orange)
        rect(ctx, 36, 22, 10, 6, orange)
        ctx.restoreGState()

        // Head
        poly(ctx, [(14,18),(14,6), (24,16)], orange)
        poly(ctx, [(48,18),(48,6), (38,16)], orange)
        poly(ctx, [(17,16),(17,10),(21,15)], pink)
        poly(ctx, [(45,16),(45,10),(41,15)], pink)
        rect(ctx, 14, 16, 34, 24, orange)
        rect(ctx, 16, 16, 30, 2,  orangeLight)

        for cx in [18.0, 24.0, 30.0, 36.0] as [CGFloat] {
            rect(ctx, cx, 16, 2, 4, orangeDark, alpha: 0.5)
        }

        // Wide excited eyes
        rect(ctx, 18, 24, 8, 10, eye)
        rect(ctx, 34, 24, 8, 10, eye)
        rect(ctx, 20, 26, 4, 6,  irisGreen)
        rect(ctx, 36, 26, 4, 6,  irisGreen)
        rect(ctx, 21, 28, 2, 3,  eye)
        rect(ctx, 37, 28, 2, 3,  eye)
        rect(ctx, 22, 26, 1, 1,  white)
        rect(ctx, 38, 26, 1, 1,  white)

        // Open mouth (mrr!)
        poly(ctx, [(28,34),(32,34),(30,37)], pinkDeep)
        rect(ctx, 27, 38, 6, 2, pinkDeep, alpha: 0.7)

        // Yarn ball to the right
        let yarn = NSColor(red: 0.85, green: 0.46, blue: 0.46, alpha: 1)
        let yarnDark = NSColor(red: 0.62, green: 0.28, blue: 0.28, alpha: 1)
        ctx.saveGState()
        ctx.translateBy(x: 52, y: 30)
        ctx.fillEllipse(in: CGRect(x: -5, y: -5, width: 10, height: 10))
        ctx.setFillColor(yarn.cgColor)
        ctx.fillEllipse(in: CGRect(x: -5, y: -5, width: 10, height: 10))
        ctx.setStrokeColor(yarnDark.cgColor)
        ctx.setLineWidth(0.6)
        ctx.move(to: .init(x: -4, y: -2)); ctx.addLine(to: .init(x:  4, y: 2));  ctx.strokePath()
        ctx.move(to: .init(x: -4, y:  1)); ctx.addLine(to: .init(x:  4, y: -3)); ctx.strokePath()
        ctx.move(to: .init(x: -3, y:  3)); ctx.addLine(to: .init(x:  4, y: 0));  ctx.strokePath()
        ctx.restoreGState()
    }

    // ===== Text helper for ZZZ =====
    private static func drawText(_ ctx: CGContext, _ text: String,
                                 _ x: CGFloat, _ y: CGFloat,
                                 size: CGFloat,
                                 color: NSColor, alpha: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Menlo-Bold", size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .bold),
            .foregroundColor: color.withAlphaComponent(alpha)
        ]
        let s = NSAttributedString(string: text, attributes: attrs)
        // Need to draw using NSGraphicsContext, not raw CGContext for AttributedString
        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx
        s.draw(at: NSPoint(x: x, y: y))
        NSGraphicsContext.restoreGraphicsState()
    }
}
