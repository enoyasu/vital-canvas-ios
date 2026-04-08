import SwiftUI

struct ArtworkCanvasView: View {
    let artwork: CanvasArtwork
    let image: UIImage?
    var cornerRadius: CGFloat = 0

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                PlaceholderGardenView(artwork: artwork)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
    }
}

// Lightweight SwiftUI fallback when image is nil
struct PlaceholderGardenView: View {
    let artwork: CanvasArtwork

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(seed: artwork.seed)
            let w = size.width, h = size.height

            // Background
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.04, green: 0.04, blue: 0.13)))

            // Flow curves
            for _ in 0..<8 {
                let startX = rng.nextDouble(in: 0...w)
                let startY = rng.nextDouble(in: h * 0.2...h)
                let cp1X = rng.nextDouble(in: 0...w)
                let cp1Y = rng.nextDouble(in: 0...h)
                let cp2X = rng.nextDouble(in: 0...w)
                let cp2Y = rng.nextDouble(in: 0...h)
                let endX = rng.nextDouble(in: 0...w)
                let endY = rng.nextDouble(in: 0...h)

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addCurve(to: CGPoint(x: endX, y: endY),
                              control1: CGPoint(x: cp1X, y: cp1Y),
                              control2: CGPoint(x: cp2X, y: cp2Y))

                let hue = 0.6 + artwork.sleepNormalized * 0.05
                let alpha = rng.nextDouble(in: 0.05...0.15)
                ctx.stroke(path, with: .color(Color(hue: hue, saturation: 0.5, brightness: 0.5, opacity: alpha)), lineWidth: 1.5)
            }

            // Particles
            for _ in 0..<30 {
                let x = rng.nextDouble(in: 0...w)
                let y = rng.nextDouble(in: 0...h)
                let r = rng.nextDouble(in: 1...3)
                let alpha = rng.nextDouble(in: 0.05...0.15)
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                         with: .color(Color(hue: 0.65, saturation: 0.3, brightness: 0.9, opacity: alpha)))
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }
}
