import SwiftUI
import MoopCore

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    static let moopInk = Color(hex: 0x1B2559)
    static let moopInkSoft = Color(hex: 0x4A5582)
    static let moopFaint = Color(hex: 0x6E7AA0)
    static let moopSky = Color(hex: 0xEAF4FF)
    static let moopLine = Color(hex: 0xC9DBF2)
    static let moopOrange = Color(hex: 0xFF7A1A)
    static let moopOrangeDeep = Color(hex: 0xC2500A)
    static let moopOrangeTint = Color(hex: 0xFFF1E6)
    static let moopBlue = Color(hex: 0x2F6FEB)
    static let moopBlueDeep = Color(hex: 0x1A4FB8)
    static let moopBlueTint = Color(hex: 0xE3ECFF)
    static let moopBlueEdge = Color(hex: 0xB8CBEF)
    static let moopSun = Color(hex: 0xFFC93C)
    static let moopSunTint = Color(hex: 0xFFF6D9)
    static let moopParentBackground = Color(hex: 0xF7F9FC)
    static let moopParentLine = Color(hex: 0xD8E0EE)
}

extension Font {
    /// Rounded system type scales with Dynamic Type and stands in for a bundled display face.
    static func moop(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static func moopNumber(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Skill {
    var kidName: String {
        switch self {
        case .addition: return "Adding"
        case .subtraction: return "Taking away"
        case .multiplication: return "Times tables"
        }
    }
    var kidDetail: String {
        switch self {
        case .addition: return "Sums up to 10"
        case .subtraction: return "No negative answers"
        case .multiplication: return "Single digits"
        }
    }
    var spokenOperator: String {
        switch self { case .addition: return "plus"; case .subtraction: return "minus"; case .multiplication: return "times" }
    }
    var tileColor: Color {
        switch self { case .addition: return .moopOrange; case .subtraction: return .moopBlue; case .multiplication: return .moopSun }
    }
    var tileText: Color { self == .subtraction ? .white : .moopInk }
    var tint: Color {
        switch self { case .addition: return .moopOrangeTint; case .subtraction: return .moopBlueTint; case .multiplication: return .moopSunTint }
    }
}

extension Question {
    var spokenPrompt: String { "\(lhs) \(skill.spokenOperator) \(rhs)" }
}

// MARK: - Building blocks

/// Large, pressable button with a solid "depth" edge that compresses on tap.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color = .moopOrange
    var depth: Color = .moopOrangeDeep
    var foreground: Color = .moopInk
    var height: CGFloat = 68
    var radius: CGFloat = 24
    var font: Font = .moop(.title2)

    static func key(fill: Color = .white, depth: Color = .moopLine, height: CGFloat = 72) -> ChunkyButtonStyle {
        ChunkyButtonStyle(fill: fill, depth: depth, height: height, radius: 22,
                          font: .moopNumber(height < 60 ? 28 : 34, weight: .semibold))
    }

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonBody(configuration: configuration, style: self)
    }
}

private struct ChunkyButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let style: ChunkyButtonStyle
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let pressed = configuration.isPressed && isEnabled
        let shape = RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        configuration.label
            .font(style.font)
            .foregroundStyle(style.foreground)
            .frame(maxWidth: .infinity, minHeight: style.height)
            .background(shape.fill(style.fill))
            .offset(y: pressed ? 4 : 0)
            .background(shape.fill(style.depth).offset(y: 6))
            .padding(.bottom, 6)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

struct MoopCard: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat
    var alignment: Alignment

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: alignment)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .moopLine, radius: 0, x: 0, y: 5)
            )
    }
}

extension View {
    func moopCard(padding: CGFloat = 20, radius: CGFloat = 28, alignment: Alignment = .leading) -> some View {
        modifier(MoopCard(padding: padding, radius: radius, alignment: alignment))
    }
}

struct Pill: View {
    let text: String
    var fill: Color = .moopBlueTint
    var foreground: Color = .moopInk

    var body: some View {
        Text(text)
            .font(.moop(.subheadline, weight: .heavy))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(fill))
    }
}

struct ChunkyProgressBar: View {
    var value: Double
    var fill: Color = .moopOrange
    var track: Color = .white
    var height: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                if value > 0 {
                    Capsule().fill(fill)
                        .frame(width: max(height, geo.size.width * min(value, 1)))
                }
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.3), value: value)
    }
}

struct SkillSymbolTile: View {
    let skill: Skill
    var size: CGFloat = 44

    var body: some View {
        Text(skill.symbol)
            .font(.moopNumber(size * 0.65))
            .foregroundStyle(skill.tileText)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(skill.tileColor))
            .accessibilityHidden(true)
    }
}

/// White square icon button used in screen headers.
struct IconTileLabel: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(Color.moopInk)
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .moopLine, radius: 0, x: 0, y: 2)
            )
    }
}
