import SwiftUI
import CoreGraphics

// nonisolated so generate() can be called from Task.detached (background thread)
final class ArtworkGenerator {

    struct ArtParams {
        var brightness: Double      // sleep (-2 to +2)
        var smoothness: Double      // hrv
        var restingHR: Double       // restingHR normalized (already inverted)
        var density: Double         // activity
        var stillness: Double       // mindfulness
        var seed: Int
    }

    static func makeParams(normalized: BaselineCalculator.NormalizedParams, seed: Int) -> ArtParams {
        ArtParams(
            brightness: normalized.sleep,
            smoothness: normalized.hrv,
            restingHR: normalized.restingHR,
            density: normalized.activity,
            stillness: normalized.mindfulness,
            seed: seed
        )
    }

    static func generate(params: ArtParams, size: CGSize = CGSize(width: 1024, height: 1024)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawGarden(in: ctx.cgContext, size: size, params: params)
        }
    }

    // MARK: - Garden Renderer

    private static func drawGarden(in ctx: CGContext, size: CGSize, params: ArtParams) {
        var rng = SeededRandom(seed: params.seed)
        let w = size.width, h = size.height

        // --- Background gradient ---
        let bgDarkness = 0.04 + max(0, params.brightness) * 0.03
        let bgHue = 0.66 + params.stillness * 0.04 // slightly warmer/cooler based on mindfulness
        let bgColor1 = UIColor(hue: bgHue, saturation: 0.7, brightness: bgDarkness, alpha: 1)
        let bgColor2 = UIColor(hue: bgHue + 0.05, saturation: 0.6, brightness: bgDarkness + 0.06, alpha: 1)

        let gradColors = [bgColor1.cgColor, bgColor2.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: gradColors as CFArray,
                                   locations: [0, 1])!
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: 0),
                               end: CGPoint(x: w * 0.3, y: h),
                               options: [])

        // --- Mist layer (sleep → clarity/brightness) ---
        let mistAlpha = max(0, 0.25 - params.brightness * 0.08)
        if mistAlpha > 0 {
            drawMist(in: ctx, size: size, alpha: mistAlpha, rng: &rng)
        }

        // --- Flow curves (HRV → smoothness) ---
        let flowCount = 6 + Int(abs(params.density) * 3)
        for _ in 0..<flowCount {
            drawFlowCurve(in: ctx, size: size, params: params, rng: &rng)
        }

        // --- Organic growth elements (activity → density/spread) ---
        let growthCount = max(0, Int(20 + params.density * 30))
        for _ in 0..<growthCount {
            drawGrowthElement(in: ctx, size: size, params: params, rng: &rng)
        }

        // --- Still water plane (mindfulness → stillness) ---
        if params.stillness > -0.5 {
            drawStillWater(in: ctx, size: size, params: params, rng: &rng)
        }

        // --- Ambient particles (restingHR → subtle unrest) ---
        let particleCount = Int(40 + abs(params.restingHR) * 60)
        for _ in 0..<particleCount {
            drawParticle(in: ctx, size: size, params: params, rng: &rng)
        }

        // --- Subtle glow ---
        drawGlow(in: ctx, size: size, params: params, rng: &rng)
    }

    // MARK: - Drawing Elements

    private static func drawMist(in ctx: CGContext, size: CGSize, alpha: Double, rng: inout SeededRandom) {
        let w = size.width, h = size.height
        for _ in 0..<3 {
            let x = rng.nextDouble(in: 0...w)
            let y = rng.nextDouble(in: 0...h)
            let r = rng.nextDouble(in: w * 0.3...w * 0.8)
            let mistGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 0.9, alpha: alpha * 0.4).cgColor,
                    UIColor(white: 0.9, alpha: 0).cgColor
                ] as CFArray,
                locations: [0, 1])!
            ctx.drawRadialGradient(mistGradient,
                                   startCenter: CGPoint(x: x, y: y), startRadius: 0,
                                   endCenter: CGPoint(x: x, y: y), endRadius: r,
                                   options: [])
        }
    }

    private static func drawFlowCurve(in ctx: CGContext, size: CGSize, params: ArtParams, rng: inout SeededRandom) {
        let w = size.width, h = size.height
        let smoothness = max(0.1, (params.smoothness + 2) / 4.0) // 0..1

        let startX = rng.nextDouble(in: -w * 0.2...w * 0.2)
        let startY = rng.nextDouble(in: h * 0.2...h * 0.9)

        // Control point variation increases with low HRV (rougher curves)
        let cp1Jitter = (1 - smoothness) * w * 0.4
        let cp1X = startX + w * 0.25 + rng.nextDouble(in: -cp1Jitter...cp1Jitter)
        let cp1Y = startY - rng.nextDouble(in: h * 0.05...h * 0.35)
        let cp2X = startX + w * 0.6 + rng.nextDouble(in: -cp1Jitter...cp1Jitter)
        let cp2Y = startY + rng.nextDouble(in: -h * 0.2...h * 0.2)
        let endX = startX + w * (0.8 + rng.nextDouble(in: -0.2...0.4))
        let endY = startY + rng.nextDouble(in: -h * 0.1...h * 0.1)

        let hue = 0.6 + params.brightness * 0.05 + rng.nextDouble(in: -0.05...0.05)
        let sat = 0.3 + smoothness * 0.4
        let bri = 0.2 + params.brightness * 0.08 + rng.nextDouble(in: 0...0.15)
        let alpha = rng.nextDouble(in: 0.04...0.18)
        let lineWidth = rng.nextDouble(in: 0.5...3.5) * (0.5 + smoothness)

        ctx.saveGState()
        ctx.setStrokeColor(UIColor(hue: hue, saturation: sat, brightness: bri, alpha: alpha).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: startX, y: startY))
        path.addCurve(to: CGPoint(x: endX, y: endY),
                      control1: CGPoint(x: cp1X, y: cp1Y),
                      control2: CGPoint(x: cp2X, y: cp2Y))
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
    }

    private static func drawGrowthElement(in ctx: CGContext, size: CGSize, params: ArtParams, rng: inout SeededRandom) {
        let w = size.width, h = size.height
        let density = (params.density + 2) / 4.0 // 0..1

        let x = rng.nextDouble(in: 0...w)
        let y = rng.nextDouble(in: h * 0.3...h)
        let scale = rng.nextDouble(in: 3...15) * (0.5 + density * 0.8)

        let hue = 0.28 + params.brightness * 0.04 + rng.nextDouble(in: -0.08...0.08)
        let sat = 0.25 + density * 0.35
        let bri = 0.15 + params.brightness * 0.06 + rng.nextDouble(in: 0...0.12)
        let alpha = rng.nextDouble(in: 0.06...0.25)

        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.rotate(by: rng.nextDouble(in: -0.5...0.5))
        ctx.setFillColor(UIColor(hue: hue, saturation: sat, brightness: bri, alpha: alpha).cgColor)

        // Draw a leaf/petal shape
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: -scale))
        path.addCurve(to: CGPoint(x: 0, y: scale),
                      control1: CGPoint(x: scale * 0.8, y: -scale * 0.3),
                      control2: CGPoint(x: scale * 0.8, y: scale * 0.3))
        path.addCurve(to: CGPoint(x: 0, y: -scale),
                      control1: CGPoint(x: -scale * 0.5, y: scale * 0.3),
                      control2: CGPoint(x: -scale * 0.5, y: -scale * 0.3))
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()
    }

    private static func drawStillWater(in ctx: CGContext, size: CGSize, params: ArtParams, rng: inout SeededRandom) {
        let w = size.width, h = size.height
        let stillness = (params.stillness + 2) / 4.0
        let waterY = h * (0.55 + stillness * 0.1)
        let waterHeight = h * (0.08 + stillness * 0.06)

        let waterGradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                UIColor(hue: 0.6, saturation: 0.4, brightness: 0.2, alpha: 0.0).cgColor,
                UIColor(hue: 0.63, saturation: 0.5, brightness: 0.25, alpha: 0.15 + stillness * 0.1).cgColor,
                UIColor(hue: 0.6, saturation: 0.4, brightness: 0.2, alpha: 0.0).cgColor
            ] as CFArray,
            locations: [0, 0.5, 1])!

        ctx.drawLinearGradient(waterGradient,
                               start: CGPoint(x: 0, y: waterY - waterHeight),
                               end: CGPoint(x: 0, y: waterY + waterHeight),
                               options: [])

        // Gentle ripples if not very still
        if params.stillness < 0.8 {
            let rippleCount = max(1, Int((1 - stillness) * 5))
            for i in 0..<rippleCount {
                let rippleY = waterY + Double(i) * (waterHeight / Double(rippleCount))
                let rippleAlpha = 0.04 * stillness
                ctx.saveGState()
                ctx.setStrokeColor(UIColor(white: 0.8, alpha: rippleAlpha).cgColor)
                ctx.setLineWidth(0.5)
                let ripplePath = CGMutablePath()
                ripplePath.move(to: CGPoint(x: 0, y: rippleY))
                let midX = w / 2 + rng.nextDouble(in: -w * 0.2...w * 0.2)
                ripplePath.addCurve(to: CGPoint(x: w, y: rippleY),
                                    control1: CGPoint(x: midX * 0.5, y: rippleY - 5),
                                    control2: CGPoint(x: midX * 1.5, y: rippleY + 5))
                ctx.addPath(ripplePath)
                ctx.strokePath()
                ctx.restoreGState()
            }
        }
    }

    private static func drawParticle(in ctx: CGContext, size: CGSize, params: ArtParams, rng: inout SeededRandom) {
        let w = size.width, h = size.height
        let unrest = abs(params.restingHR)

        let x = rng.nextDouble(in: 0...w)
        let y = rng.nextDouble(in: 0...h)
        let r = rng.nextDouble(in: 0.5...3.0) * (1 + unrest * 0.5)
        let alpha = rng.nextDouble(in: 0.02...0.12)

        let hue = 0.65 + rng.nextDouble(in: -0.1...0.1)
        let sat = 0.2 + unrest * 0.3

        ctx.saveGState()
        ctx.setFillColor(UIColor(hue: hue, saturation: sat, brightness: 0.8, alpha: alpha).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        ctx.restoreGState()
    }

    private static func drawGlow(in ctx: CGContext, size: CGSize, params: ArtParams, rng: inout SeededRandom) {
        let w = size.width, h = size.height
        let glowX = w * (0.3 + rng.nextDouble(in: 0...0.4))
        let glowY = h * rng.nextDouble(in: 0.1...0.5)
        let glowRadius = w * (0.25 + params.brightness * 0.05 + rng.nextDouble(in: 0...0.15))
        let glowAlpha = max(0.03, 0.08 + params.brightness * 0.04)

        let glowHue = 0.62 + params.stillness * 0.06
        let glowGradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                UIColor(hue: glowHue, saturation: 0.5, brightness: 0.7, alpha: glowAlpha).cgColor,
                UIColor(hue: glowHue, saturation: 0.3, brightness: 0.4, alpha: 0).cgColor
            ] as CFArray,
            locations: [0, 1])!
        ctx.drawRadialGradient(glowGradient,
                               startCenter: CGPoint(x: glowX, y: glowY), startRadius: 0,
                               endCenter: CGPoint(x: glowX, y: glowY), endRadius: glowRadius,
                               options: [])
    }
}
