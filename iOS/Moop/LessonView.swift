import SwiftUI
import MoopCore

/// The result of the answer just submitted, shown before moving to the next question.
struct AnswerFeedback: Equatable {
    let question: Question
    let submitted: Int
    let wasCorrect: Bool
    let number: Int
    let isLast: Bool
}

struct LessonView: View {
    /// Counting dots are an unscored visual aid. Turn off until a hint scoring policy exists if needed.
    static let countingDotsEnabled = true

    @EnvironmentObject var store: AppStore
    let session: LessonSession
    @Binding var feedback: AnswerFeedback?
    let onPause: () -> Void
    @State private var answer = ""
    @State private var showDots = false

    private var question: Question? { feedback?.question ?? session.currentQuestion }
    private var number: Int { feedback?.number ?? session.attempts.count + 1 }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                // Short screens (iPhone landscape): question beside the keypad so neither is squeezed out.
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        topBar.padding(.top, 8)
                        ScrollView {
                            if let question {
                                problemCard(question).padding(.vertical, 16)
                            }
                        }
                    }
                    ScrollView {
                        controls(keyHeight: 52).padding(.vertical, 8)
                    }
                    .frame(width: 320)
                }
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    ScrollView {
                        if let question {
                            problemCard(question).padding(24)
                        }
                    }
                    controls(keyHeight: 72)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(Color.moopInk)
        .sensoryFeedback(trigger: feedback) { _, new in
            guard let new else { return nil }
            return new.wasCorrect ? .success : .warning
        }
    }

    @ViewBuilder
    private func controls(keyHeight: CGFloat) -> some View {
        if let feedback {
            FeedbackPanel(feedback: feedback, onNext: next)
        } else {
            Keypad(answer: $answer, keyHeight: keyHeight, onCheck: check)
        }
    }

    private var topBar: some View {
        let total = session.questions.count
        let answered = session.attempts.count
        return HStack(spacing: 14) {
            Button(action: onPause) { IconTileLabel(systemName: "pause.fill") }
                .accessibilityLabel("Pause and go home")
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Question \(number) of \(total)")
                    Spacer()
                    Text(question?.skill.kidName ?? "").foregroundStyle(Color.moopInkSoft)
                }
                .font(.moop(.subheadline, weight: .heavy))
                ChunkyProgressBar(value: Double(answered) / Double(max(total, 1)))
                    .accessibilityElement()
                    .accessibilityLabel("Lesson progress")
                    .accessibilityValue("\(answered) of \(total) answered")
            }
        }
    }

    private func problemCard(_ q: Question) -> some View {
        let shown = feedback.map { String($0.submitted) } ?? (answer.isEmpty ? "?" : answer)
        return VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(q.lhs)")
                Text(q.skill.symbol).foregroundStyle(q.skill == .subtraction ? Color.moopBlue : Color.moopOrangeDeep)
                Text("\(q.rhs)")
                Text("=").foregroundStyle(Color.moopInkSoft)
                Text(shown)
                    .foregroundStyle(shown == "?" ? Color.moopFaint : Color.moopInk)
                    .padding(.horizontal, 8)
                    .frame(minWidth: 84, minHeight: 84)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: 0xF6FAFF)))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(answerBorder, lineWidth: 4))
            }
            .font(.moopNumber(60))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(q.spokenPrompt) equals")
            .accessibilityValue(shown == "?" ? "No answer yet" : "Your answer: \(shown)")

            if Self.countingDotsEnabled {
                if showDots { CountingDots(question: q) }
                Button { showDots.toggle() } label: {
                    Label(showDots ? "Hide the dots" : "Show me with dots", systemImage: "circle.grid.2x2.fill")
                        .font(.moop(.subheadline, weight: .heavy))
                        .foregroundStyle(Color.moopInk)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(Color.moopBlueTint))
                }
                .buttonStyle(.plain)
            }
        }
        .moopCard(padding: 24, radius: 32, alignment: .center)
    }

    private var answerBorder: Color {
        if let feedback { return feedback.wasCorrect ? .moopBlue : .moopSun }
        return answer.isEmpty ? .moopLine : .moopOrange
    }

    private func check() {
        guard feedback == nil, let q = session.currentQuestion, let value = Int(answer) else { return }
        let before = session.attempts.count
        store.submit(value)
        guard let updated = store.state.active, updated.attempts.count == before + 1,
              let attempt = updated.attempts.last else { return }
        answer = ""
        feedback = AnswerFeedback(question: q, submitted: attempt.submittedAnswer, wasCorrect: attempt.wasCorrect,
                                  number: before + 1, isLast: updated.isComplete)
    }

    private func next() {
        feedback = nil
        showDots = false
    }
}

struct Keypad: View {
    @Binding var answer: String
    var keyHeight: CGFloat = 72
    let onCheck: () -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...9, id: \.self) { digitKey($0) }
            Button { if !answer.isEmpty { answer.removeLast() } } label: {
                Image(systemName: "delete.left.fill").font(.system(size: 28, weight: .bold))
            }
            .buttonStyle(ChunkyButtonStyle.key(fill: .moopBlueTint, depth: .moopBlueEdge, height: keyHeight))
            .accessibilityLabel("Delete")
            digitKey(0)
            Button(action: onCheck) {
                Image(systemName: "checkmark").font(.system(size: 30, weight: .black))
            }
            .buttonStyle(ChunkyButtonStyle.key(fill: .moopOrange, depth: .moopOrangeDeep, height: keyHeight))
            .disabled(answer.isEmpty)
            .accessibilityLabel("Check answer")
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        Button {
            if answer == "0" { answer = "" }
            if answer.count < 3 { answer.append(String(digit)) }
        } label: {
            Text("\(digit)")
        }
        .buttonStyle(ChunkyButtonStyle.key(height: keyHeight))
    }
}

struct FeedbackPanel: View {
    let feedback: AnswerFeedback
    let onNext: () -> Void
    private static let cheers = ["Yes! Great job!", "You got it!", "Super math!", "Awesome!", "Nailed it!"]

    var body: some View {
        let q = feedback.question
        let nextTitle = feedback.isLast ? "See how I did" : (feedback.wasCorrect ? "Next question" : "Keep going")
        if feedback.wasCorrect {
            VStack(spacing: 18) {
                HStack(spacing: 16) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(Color.moopBlue)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Color.white))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Self.cheers[feedback.number % Self.cheers.count]).font(.moop(.title))
                        Text("\(q.prompt) = \(q.answer)").font(.moop(.headline))
                    }
                    .accessibilityElement(children: .combine)
                    Spacer(minLength: 0)
                }
                Button(nextTitle, action: onNext)
                    .buttonStyle(ChunkyButtonStyle(fill: .white, depth: .moopBlueDeep, height: 64, radius: 22))
            }
            .foregroundStyle(Color.white)
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Color.moopBlue))
        } else {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    MoopMascot(mood: .oops, size: 72)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nice try!").font(.moop(.title))
                        (Text("\(q.prompt) = ") + Text("\(q.answer)").foregroundStyle(Color.moopOrangeDeep).fontWeight(.heavy)
                         + Text(". We'll look at it together at the end."))
                            .font(.moop(.callout))
                    }
                    .accessibilityElement(children: .combine)
                    Spacer(minLength: 0)
                }
                Button(nextTitle, action: onNext)
                    .buttonStyle(ChunkyButtonStyle(height: 64, radius: 22))
            }
            .foregroundStyle(Color.moopInk)
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Color.moopSun, lineWidth: 4))
        }
    }
}

/// Ten-frame dots for adding and taking away; rows of equal groups for times tables.
struct CountingDots: View {
    let question: Question
    private enum Dot { case orange, blue, gone }

    var body: some View {
        let dots = makeDots()
        let columns = question.skill == .multiplication ? max(question.rhs, 1) : 5
        let size: CGFloat = columns > 7 ? 20 : 24
        if dots.isEmpty {
            Text("No dots here. That's zero!")
                .font(.moop(.callout, weight: .semibold))
                .foregroundStyle(Color.moopInkSoft)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(stride(from: 0, to: dots.count, by: columns)), id: \.self) { start in
                    HStack(spacing: 8) {
                        ForEach(start..<min(start + columns, dots.count), id: \.self) { index in
                            dotView(dots[index], size: size)
                        }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(description)
        }
    }

    private func makeDots() -> [Dot] {
        let q = question
        switch q.skill {
        case .addition:
            return [Dot](repeating: .orange, count: q.lhs) + [Dot](repeating: .blue, count: q.rhs)
        case .subtraction:
            return (0..<q.lhs).map { $0 < q.lhs - q.rhs ? Dot.orange : Dot.gone }
        case .multiplication:
            return (0..<(q.lhs * q.rhs)).map { ($0 / max(q.rhs, 1)) % 2 == 0 ? Dot.orange : Dot.blue }
        }
    }

    @ViewBuilder
    private func dotView(_ dot: Dot, size: CGFloat) -> some View {
        switch dot {
        case .orange: Circle().fill(Color.moopOrange).frame(width: size, height: size)
        case .blue: Circle().fill(Color.moopBlue).frame(width: size, height: size)
        case .gone:
            Circle()
                .strokeBorder(Color.moopFaint, style: StrokeStyle(lineWidth: 3, dash: [4, 3]))
                .frame(width: size, height: size)
        }
    }

    private var description: String {
        let q = question
        switch q.skill {
        case .addition: return "\(q.lhs) orange dots and \(q.rhs) blue dots"
        case .subtraction: return "\(q.lhs) dots with \(q.rhs) taken away"
        case .multiplication: return "\(q.lhs) rows of \(q.rhs) dots"
        }
    }
}
