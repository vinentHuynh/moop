import SwiftUI
import MoopCore

struct ResultView: View {
    let session: LessonSession
    let onDone: () -> Void
    let onTryAgain: () -> Void

    private var correct: Int { session.correctCount }
    private var required: Int { session.plan.requiredCorrect }
    private var total: Int { session.questions.count }
    private var mistakes: [Int] { session.attempts.indices.filter { !session.attempts[$0].wasCorrect } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                if session.passed { rewardTicket } else { goalCard }
                mistakesSection
            }
            .padding(24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.moopInk)
        .safeAreaInset(edge: .bottom) {
            actions
                .frame(maxWidth: 600)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
                .background(Color.moopSky)
        }
    }

    private var header: some View {
        let missing = max(required - correct, 0)
        return VStack(spacing: 6) {
            MoopMascot(mood: session.passed ? .cheering : .happy, size: 150)
            Text(session.passed ? "Mission complete!" : (missing <= 2 ? "So close!" : "Good practice!"))
                .font(.moop(.largeTitle))
            Group {
                if session.passed {
                    Text("You got \(correct) of \(total) right. You needed \(required).")
                } else {
                    Text("Your brain got stronger today. Just \(missing) more right unlocks play time.")
                }
            }
            .font(.moop(.headline, weight: .semibold))
            .foregroundStyle(Color.moopInkSoft)
            .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    private var rewardTicket: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.moopInk)
                    .frame(width: 60, height: 60)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.moopSun))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(session.plan.allowanceMinutes) minutes").font(.moop(.title))
                    Text("of play time earned").font(.moop(.headline)).foregroundStyle(Color(hex: 0xD4DCF5))
                }
                .accessibilityElement(children: .combine)
            }
            Text("Prototype: device limits aren't connected yet.")
                .font(.moop(.footnote, weight: .semibold))
                .foregroundStyle(Color(hex: 0xD4DCF5))
        }
        .foregroundStyle(Color.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.moopInk))
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                (Text("\(correct) ").font(.moopNumber(30)) + Text("right").font(.moop(.headline)).foregroundStyle(Color.moopInkSoft))
                Spacer()
                Text("Goal: \(required)").font(.moop(.subheadline, weight: .heavy)).foregroundStyle(Color.moopInkSoft)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.moopSky)
                    if correct > 0 {
                        Capsule().fill(Color.moopOrange).frame(width: geo.size.width * fraction(correct))
                    }
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.moopInk)
                        .frame(width: 4, height: 34)
                        .offset(x: geo.size.width * fraction(required) - 2)
                }
            }
            .frame(height: 22)
            .padding(.vertical, 6)
            .accessibilityElement()
            .accessibilityLabel("\(correct) right. Goal is \(required).")
            VStack(alignment: .leading, spacing: 6) {
                ForEach(session.plan.items.filter { $0.count > 0 }, id: \.skill) { item in
                    Pill(text: "\(item.skill.kidName): \(correctCount(for: item.skill)) of \(item.count)", fill: item.skill.tint)
                }
            }
        }
        .moopCard()
    }

    @ViewBuilder
    private var mistakesSection: some View {
        if mistakes.isEmpty {
            Text("Perfect score! Not a single tricky one.")
                .font(.moop(.title3, weight: .semibold))
                .moopCard(alignment: .center)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(mistakes.count == 1 ? "Let's look at 1 tricky one" : "Let's look at \(mistakes.count) tricky ones")
                    .font(.moop(.title3, weight: .semibold))
                ForEach(mistakes, id: \.self) { index in
                    let q = session.questions[index]
                    let said = session.attempts[index].submittedAnswer
                    HStack {
                        (Text("\(q.prompt) = ") + Text("\(q.answer)").foregroundStyle(Color.moopBlueDeep))
                            .font(.moopNumber(28))
                        Spacer()
                        Text("You said \(said)")
                            .font(.moop(.subheadline))
                            .foregroundStyle(Color.moopInkSoft)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .moopLine, radius: 0, x: 0, y: 3)
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(q.spokenPrompt) equals \(q.answer). You said \(said).")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if session.passed {
            Button("Yay, all done!", action: onDone).buttonStyle(ChunkyButtonStyle())
        } else {
            VStack(spacing: 4) {
                Button(action: onTryAgain) {
                    Label("Try a new mission", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(ChunkyButtonStyle())
                Button("Maybe later", action: onDone)
                    .font(.moop(.headline, weight: .heavy))
                    .foregroundStyle(Color.moopBlueDeep)
                    .frame(minHeight: 44)
            }
        }
    }

    private func fraction(_ value: Int) -> CGFloat {
        CGFloat(min(max(Double(value) / Double(max(total, 1)), 0), 1))
    }

    private func correctCount(for skill: Skill) -> Int {
        session.attempts.indices.filter { session.questions[$0].skill == skill && session.attempts[$0].wasCorrect }.count
    }
}
