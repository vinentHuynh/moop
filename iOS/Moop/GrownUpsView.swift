import SwiftUI
import MoopCore

struct GrownUpsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            Group {
                if unlocked {
                    PlanEditorView()
                } else {
                    GrownUpsGate { unlocked = true }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.moopParentBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(unlocked ? "Lock" : "Back") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .tint(Color.moopBlueDeep)
    }
}

/// A press-and-hold check that keeps young children out of the settings. It is not a security lock.
struct GrownUpsGate: View {
    static let holdSeconds = 3.0
    let onUnlock: () -> Void
    @State private var holding = false

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 72, height: 72)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.moopInk))
                .accessibilityHidden(true)
            Text("Grown-ups only").font(.moop(.title, weight: .semibold))
            Text("Change missions, passing scores and play time.")
                .font(.moop(.body, weight: .semibold))
                .foregroundStyle(Color.moopInkSoft)
                .multilineTextAlignment(.center)
            Spacer()
            ZStack {
                Circle().stroke(Color.moopParentLine, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: holding ? 1 : 0)
                    .stroke(Color.moopInk, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(holding ? .linear(duration: Self.holdSeconds) : .easeOut(duration: 0.2), value: holding)
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.moopInk)
            }
            .frame(width: 120, height: 120)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: Self.holdSeconds, maximumDistance: 40, perform: onUnlock,
                                onPressingChanged: { holding = $0 })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Grown-ups: press and hold for 3 seconds")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onUnlock() }
            Text("Press and hold for 3 seconds").font(.moop(.headline, weight: .heavy))
            Text("This is a simple grown-up check, not a lock. A parent PIN is still to come.")
                .font(.moop(.footnote, weight: .semibold))
                .foregroundStyle(Color.moopInkSoft)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.moopInk)
        .padding(32)
    }
}

struct PlanEditorView: View {
    @EnvironmentObject var store: AppStore
    @State private var counts: [Skill: Int] = [:]
    @State private var percent = 80
    @State private var minutes = 30
    @State private var saved = false
    @State private var loaded = false

    private var draft: LessonPlan {
        LessonPlan(items: Skill.allCases.map { PlanItem(skill: $0, count: counts[$0] ?? 0) },
                   passingPercent: percent, allowanceMinutes: minutes)
    }
    private var isValid: Bool { (1...100).contains(draft.questionCount) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Mission plan").font(.moop(.largeTitle, weight: .semibold))
                summary
                VStack(spacing: 0) {
                    ForEach(Array(Skill.allCases.enumerated()), id: \.element) { index, skill in
                        if index > 0 { Divider().overlay(Color.moopParentLine) }
                        SkillStepperRow(skill: skill, count: binding(for: skill))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.moopParentLine, lineWidth: 1.5))
                chipGroup("Passing score", options: options([60, 70, 80, 90, 100], including: percent),
                          selection: $percent) { "\($0)%" }
                chipGroup("Play time earned", options: options([15, 30, 45, 60], including: minutes),
                          selection: $minutes) { "\($0) min" }
                VStack(spacing: 8) {
                    Button(saved ? "Saved for the next mission" : "Save plan", action: save)
                        .buttonStyle(ChunkyButtonStyle(fill: saved ? .moopBlueTint : .moopInk,
                                                       depth: saved ? .moopBlueEdge : Color(hex: 0x0E1433),
                                                       foreground: saved ? .moopBlueDeep : .white,
                                                       height: 60, radius: 20, font: .moop(.title3, weight: .semibold)))
                        .disabled(!isValid)
                    Text(isValid ? "A mission already in progress keeps its old plan." : "Choose between 1 and 100 questions in total.")
                        .font(.moop(.footnote, weight: .semibold))
                        .foregroundStyle(Color.moopInkSoft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Text("Developer prototype: this area is not protected by a parent PIN, and earned play time does not change device limits yet.")
                    .font(.moop(.caption, weight: .semibold))
                    .foregroundStyle(Color.moopInkSoft)
            }
            .foregroundStyle(Color.moopInk)
            .padding(20)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: load)
        .onChange(of: draft) { saved = false }
    }

    private var summary: some View {
        let accent = Color.moopSun
        return (Text("Your child answers ")
                + Text("\(draft.questionCount) questions").fontWeight(.heavy).foregroundStyle(accent)
                + Text(" and needs ")
                + Text("\(draft.requiredCorrect) right").fontWeight(.heavy).foregroundStyle(accent)
                + Text(" to earn ")
                + Text("\(minutes) minutes").fontWeight(.heavy).foregroundStyle(accent)
                + Text(" of play."))
            .font(.moop(.callout, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.moopInk))
    }

    private func chipGroup(_ title: String, options: [Int], selection: Binding<Int>,
                           label: @escaping (Int) -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.moop(.subheadline, weight: .heavy))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                ForEach(options, id: \.self) { option in
                    let on = selection.wrappedValue == option
                    Button { selection.wrappedValue = option } label: {
                        Text(label(option))
                            .font(.moop(.callout, weight: .heavy))
                            .foregroundStyle(on ? Color.white : Color.moopInk)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? Color.moopInk : Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(on ? Color.clear : Color.moopParentLine, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private func options(_ presets: [Int], including current: Int) -> [Int] {
        Array(Set(presets + [current])).sorted()
    }

    private func binding(for skill: Skill) -> Binding<Int> {
        Binding(get: { counts[skill] ?? 0 }, set: { counts[skill] = min(max($0, 0), 50) })
    }

    private func load() {
        guard !loaded else { return }
        let plan = store.state.plan
        counts = Dictionary(plan.items.map { ($0.skill, $0.count) }, uniquingKeysWith: { first, _ in first })
        percent = plan.passingPercent
        minutes = plan.allowanceMinutes
        loaded = true
    }

    private func save() {
        let plan = draft
        store.savePlan(plan)
        saved = store.state.plan == plan
    }
}

struct SkillStepperRow: View {
    let skill: Skill
    @Binding var count: Int

    var body: some View {
        HStack(spacing: 10) {
            SkillSymbolTile(skill: skill, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.kidName).font(.moop(.headline, weight: .heavy))
                Text(skill.kidDetail)
                    .font(.moop(.footnote, weight: .semibold))
                    .foregroundStyle(Color.moopInkSoft)
            }
            Spacer(minLength: 4)
            stepButton("minus", disabled: count <= 0) { count -= 1 }
            Text("\(count)")
                .font(.moopNumber(22, weight: .semibold))
                .monospacedDigit()
                .frame(minWidth: 34)
            stepButton("plus", disabled: count >= 50) { count += 1 }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(skill.kidName) questions")
        .accessibilityValue("\(count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: count += 1
            case .decrement: count -= 1
            @unknown default: break
            }
        }
    }

    private func stepButton(_ icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Color.moopInk)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.moopParentBackground))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.moopParentLine, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}
