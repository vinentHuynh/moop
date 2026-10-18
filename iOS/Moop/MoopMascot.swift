import SwiftUI

/// Moop, the app's mascot, drawn on a 140×130 grid so it scales crisply at any size.
struct MoopMascot: View {
    enum Mood { case happy, cheering, oops }

    var mood: Mood = .happy
    var size: CGFloat = 132

    var body: some View {
        Canvas { context, canvasSize in
            context.scaleBy(x: canvasSize.width / 140, y: canvasSize.height / 130)
            draw(in: &context)
        }
        .frame(width: size, height: size * 130 / 140)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        let ink = Color.moopInk
        let line = StrokeStyle(lineWidth: 4, lineCap: .round)

        if mood == .cheering {
            var arms = Path()
            arms.move(to: p(28, 70)); arms.addLine(to: p(8, 44))
            arms.move(to: p(112, 70)); arms.addLine(to: p(132, 44))
            context.stroke(arms, with: .color(.moopOrange), style: StrokeStyle(lineWidth: 10, lineCap: .round))
        }

        var stem = Path()
        stem.move(to: p(70, 26))
        stem.addCurve(to: p(83, 12), control1: p(70, 16), control2: p(76, 11))
        context.stroke(stem, with: .color(ink), style: line)
        let leaf = Path(ellipseIn: CGRect(x: 79, y: 8, width: 18, height: 10))
            .applying(rotation(-20, around: p(88, 13)))
        context.fill(leaf, with: .color(.moopBlue))

        var blob = Path()
        blob.move(to: p(70, 26))
        blob.addCurve(to: p(116, 82), control1: p(102, 26), control2: p(118, 54))
        blob.addCurve(to: p(70, 118), control1: p(114, 106), control2: p(96, 118))
        blob.addCurve(to: p(24, 82), control1: p(44, 118), control2: p(26, 106))
        blob.addCurve(to: p(70, 26), control1: p(22, 54), control2: p(38, 26))
        blob.closeSubpath()
        context.fill(blob, with: .color(.moopOrange))
        context.fill(Path(ellipseIn: CGRect(x: 40, y: 80, width: 60, height: 32)), with: .color(Color(hex: 0xFFB27A)))
        for x: CGFloat in [42, 98] {
            context.fill(circle(x, 81, 5), with: .color(Color(hex: 0xE8463C).opacity(0.3)))
        }

        switch mood {
        case .cheering:
            var eyes = Path()
            eyes.move(to: p(46, 66)); eyes.addQuadCurve(to: p(64, 66), control: p(55, 56))
            eyes.move(to: p(76, 66)); eyes.addQuadCurve(to: p(94, 66), control: p(85, 56))
            context.stroke(eyes, with: .color(ink), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            var mouth = Path()
            mouth.move(to: p(54, 80))
            mouth.addQuadCurve(to: p(86, 80), control: p(70, 100))
            mouth.closeSubpath()
            context.fill(mouth, with: .color(ink))
        case .happy, .oops:
            for x: CGFloat in [55, 85] {
                context.fill(circle(x, 66, 11), with: .color(.white))
                context.fill(circle(x + 1.5, 68, 5.5), with: .color(ink))
                context.fill(circle(x + 3.5, 65, 2), with: .color(.white))
            }
            var mouth = Path()
            if mood == .happy {
                mouth.move(to: p(60, 84)); mouth.addQuadCurve(to: p(80, 84), control: p(70, 93))
            } else {
                mouth.move(to: p(61, 88)); mouth.addQuadCurve(to: p(79, 88), control: p(70, 84))
            }
            context.stroke(mouth, with: .color(ink), style: line)
        }
    }

    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
    }

    private func rotation(_ degrees: CGFloat, around c: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: c.x, y: c.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -c.x, y: -c.y)
    }
}
