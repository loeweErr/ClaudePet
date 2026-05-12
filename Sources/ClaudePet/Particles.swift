import AppKit

enum ParticleKind {
    case heart, sparkle, star, crumb, dust, note

    var color: NSColor {
        switch self {
        case .heart:   return NSColor(red: 1.00, green: 0.45, blue: 0.65, alpha: 1)
        case .sparkle: return NSColor(red: 1.00, green: 0.86, blue: 0.34, alpha: 1)
        case .star:    return NSColor(red: 0.58, green: 0.84, blue: 1.00, alpha: 1)
        case .crumb:   return NSColor(red: 0.65, green: 0.45, blue: 0.27, alpha: 1)
        case .dust:    return NSColor.white.withAlphaComponent(0.6)
        case .note:    return NSColor(red: 0.75, green: 0.50, blue: 1.00, alpha: 1)
        }
    }
}

struct Particle {
    var pos: NSPoint
    var vel: NSPoint
    var life: TimeInterval
    let maxLife: TimeInterval
    let kind: ParticleKind
    var size: CGFloat
    var spin: CGFloat
    var spinSpeed: CGFloat
}

/// Lightweight particle system. Owned by PetView; ticked by its animation timer.
final class ParticleSystem {
    private(set) var particles: [Particle] = []

    /// Emit a burst of particles at a point in view coordinates.
    func emit(kind: ParticleKind, at point: NSPoint, count: Int = 6,
              speed: CGFloat = 40, life: TimeInterval = 1.4, spread: CGFloat = .pi) {
        for _ in 0..<count {
            let angle = -CGFloat.pi/2 + CGFloat.random(in: -spread/2 ... spread/2)
            let v = speed * CGFloat.random(in: 0.6...1.3)
            let vel = NSPoint(x: cos(angle) * v, y: -sin(angle) * v) // flipped view: -y is up
            let p = Particle(
                pos: point,
                vel: vel,
                life: life,
                maxLife: life,
                kind: kind,
                size: CGFloat.random(in: 4...8),
                spin: CGFloat.random(in: 0..<CGFloat.pi*2),
                spinSpeed: CGFloat.random(in: -3...3)
            )
            particles.append(p)
        }
    }

    func update(dt: TimeInterval) {
        guard !particles.isEmpty else { return }
        for i in particles.indices {
            particles[i].pos.x += particles[i].vel.x * CGFloat(dt)
            particles[i].pos.y += particles[i].vel.y * CGFloat(dt)
            particles[i].vel.y += 30 * CGFloat(dt)            // light gravity in flipped view (positive y = down)
            particles[i].vel.x *= 0.98
            particles[i].spin += particles[i].spinSpeed * CGFloat(dt)
            particles[i].life -= dt
        }
        particles.removeAll { $0.life <= 0 }
    }

    func draw(in ctx: CGContext) {
        for p in particles {
            let alpha = max(0, min(1, p.life / p.maxLife))
            ctx.saveGState()
            ctx.translateBy(x: p.pos.x, y: p.pos.y)
            ctx.rotate(by: p.spin)
            ctx.setFillColor(p.kind.color.withAlphaComponent(alpha).cgColor)
            switch p.kind {
            case .heart:   drawHeart(ctx, size: p.size)
            case .sparkle: drawSparkle(ctx, size: p.size)
            case .star:    drawStar(ctx, size: p.size)
            case .note:    drawNote(ctx, size: p.size)
            case .crumb:
                ctx.fill(CGRect(x: -p.size/2, y: -p.size/2, width: p.size, height: p.size))
            case .dust:
                ctx.fillEllipse(in: CGRect(x: -p.size/2, y: -p.size/2, width: p.size, height: p.size))
            }
            ctx.restoreGState()
        }
    }

    private func drawHeart(_ ctx: CGContext, size: CGFloat) {
        let s = size / 2
        // pixel heart: two top circles + bottom triangle (approximated by rects)
        ctx.fill(CGRect(x: -s,       y: -s*0.6, width: s, height: s))
        ctx.fill(CGRect(x: 0,        y: -s*0.6, width: s, height: s))
        ctx.beginPath()
        ctx.move(to: CGPoint(x: -s, y: -s*0.1))
        ctx.addLine(to: CGPoint(x:  s, y: -s*0.1))
        ctx.addLine(to: CGPoint(x:  0, y:  s))
        ctx.closePath()
        ctx.fillPath()
    }

    private func drawSparkle(_ ctx: CGContext, size: CGFloat) {
        let s = size / 2
        // 4-point sparkle (plus shape with thin arms)
        ctx.fill(CGRect(x: -s*0.2, y: -s,    width: s*0.4, height: s*2))
        ctx.fill(CGRect(x: -s,    y: -s*0.2, width: s*2,   height: s*0.4))
    }

    private func drawStar(_ ctx: CGContext, size: CGFloat) {
        let s = size
        ctx.beginPath()
        for i in 0..<5 {
            let a = -CGFloat.pi/2 + CGFloat(i) * 2 * CGFloat.pi / 5
            let p = CGPoint(x: cos(a) * s, y: sin(a) * s)
            if i == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
            let a2 = a + CGFloat.pi / 5
            ctx.addLine(to: CGPoint(x: cos(a2) * s * 0.4, y: sin(a2) * s * 0.4))
        }
        ctx.closePath()
        ctx.fillPath()
    }

    private func drawNote(_ ctx: CGContext, size: CGFloat) {
        let s = size
        ctx.fillEllipse(in: CGRect(x: -s, y: 0, width: s*0.9, height: s*0.7))
        ctx.fill(CGRect(x: -s*0.18, y: -s*1.2, width: s*0.25, height: s*1.6))
    }
}
