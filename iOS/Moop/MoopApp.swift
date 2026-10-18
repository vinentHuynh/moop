import SwiftUI
import MoopCore

struct SavedState: Codable {
    var schemaVersion = 1
    var plan = LessonPlan.sample
    var active: LessonSession?
    var history: [LessonSession] = []
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var state = SavedState()
    @Published var error: String?
    private let url: URL
    private var readable = true

    init() {
        url = URL.applicationSupportDirectory.appending(path: "moop-state.json")
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let saved = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: url))
                guard saved.schemaVersion == 1 else { throw LearningError.invalidSession }
                try saved.plan.validate()
                try saved.active?.validate()
                for session in saved.history { try session.validate() }
                state = saved
            }
        } catch {
            readable = false
            self.error = "Could not load saved progress. The original file has been preserved. \(error.localizedDescription)"
        }
    }

    private func commit(_ next: SavedState) {
        guard readable else { error = "Saved progress needs recovery before changes can be made."; return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(next).write(to: url, options: .atomic)
            state = next
        } catch { self.error = "Could not save progress: \(error.localizedDescription)" }
    }

    func savePlan(_ plan: LessonPlan) {
        do { try plan.validate(); var next = state; next.plan = plan; commit(next) }
        catch { self.error = error.localizedDescription }
    }

    func start() {
        guard state.active == nil else { return }
        do {
            var rng = SystemRandomNumberGenerator()
            var next = state
            next.active = try next.plan.makeSession(using: &rng)
            commit(next)
        } catch { self.error = error.localizedDescription }
    }

    func submit(_ answer: Int) {
        guard var lesson = state.active else { return }
        do {
            try lesson.submit(answer)
            var next = state
            next.active = lesson
            if lesson.isComplete && !next.history.contains(where: { $0.id == lesson.id }) {
                next.history.append(lesson)
            }
            commit(next)
        } catch { self.error = error.localizedDescription }
    }

    func dismissResult() {
        guard state.active?.isComplete == true else { return }
        var next = state; next.active = nil; commit(next)
    }
}

@main
struct MoopApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            TabView {
                LessonView().tabItem { Label("Learn", systemImage: "number") }
                PlanView().tabItem { Label("Plan", systemImage: "slider.horizontal.3") }
                ProgressViewScreen().tabItem { Label("Progress", systemImage: "chart.bar") }
            }
            .tint(.indigo)
            .environmentObject(store)
            .alert("Moop", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
        }
    }
}

struct LessonView: View {
    @EnvironmentObject var store: AppStore
    @State private var answer = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Label("Learning prototype · app blocking is not active", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let session = store.state.active {
                        if let question = session.currentQuestion {
                            Text("Question \(session.attempts.count + 1) of \(session.questions.count)").font(.headline)
                            ProgressView(value: Double(session.attempts.count), total: Double(session.questions.count))
                            Text(question.skill.title).foregroundStyle(.secondary)
                            Text(question.prompt).font(.system(size: 48, weight: .bold, design: .rounded))
                            TextField("Your answer", text: $answer)
                                .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Your answer")
                            Button("Submit answer") {
                                if let value = Int(answer.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                    store.submit(value); answer = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(Int(answer.trimmingCharacters(in: .whitespacesAndNewlines)) == nil)
                        } else {
                            Image(systemName: session.passed ? "checkmark.seal.fill" : "arrow.clockwise.circle")
                                .font(.system(size: 56)).foregroundStyle(.indigo)
                            Text(session.passed ? "Lesson passed!" : "Let's keep practicing").font(.title.bold())
                            Text("\(session.correctCount) / \(session.questions.count) correct · \(session.plan.requiredCorrect) needed")
                            if session.passed {
                                Text("Your plan awards \(session.plan.allowanceMinutes) minutes. Device restrictions are not connected in this prototype.")
                            }
                            ForEach(Array(session.questions.enumerated()), id: \.offset) { index, question in
                                if !session.attempts[index].wasCorrect {
                                    VStack(alignment: .leading) {
                                        Text("\(question.prompt) = \(question.answer)").bold()
                                        Text("Your answer: \(session.attempts[index].submittedAnswer)").foregroundStyle(.secondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            Button("Finish review") { store.dismissResult() }.buttonStyle(.borderedProminent)
                        }
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 64)).foregroundStyle(.indigo)
                        Text("A little math. A little more freedom.").font(.largeTitle.bold())
                        Text("\(store.state.plan.questionCount) questions · \(store.state.plan.passingPercent)% to pass")
                        Button("Start lesson") { answer = ""; store.start() }.buttonStyle(.borderedProminent)
                    }
                }.padding(24).frame(maxWidth: 600)
            }.navigationTitle("moop")
        }
    }
}

struct PlanView: View {
    @EnvironmentObject var store: AppStore
    @State private var addition = 10
    @State private var subtraction = 10
    @State private var multiplication = 0
    @State private var percent = 80
    @State private var minutes = 30
    var draft: LessonPlan {
        LessonPlan(items: [.init(skill: .addition, count: addition), .init(skill: .subtraction, count: subtraction),
                           .init(skill: .multiplication, count: multiplication)], passingPercent: percent, allowanceMinutes: minutes)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Developer prototype: this editor is not protected by parent authentication. Do not use it as a parental-control product yet.")
                }
                Section("Question allocation") {
                    Stepper("Addition: \(addition)", value: $addition, in: 0...50)
                    Stepper("Subtraction: \(subtraction)", value: $subtraction, in: 0...50)
                    Stepper("Multiplication: \(multiplication)", value: $multiplication, in: 0...50)
                    Text("\(draft.questionCount) total · maximum 100")
                }
                Section("Passing and allowance") {
                    Stepper("Passing score: \(percent)%", value: $percent, in: 1...100)
                    Stepper("Allowance: \(minutes) minutes", value: $minutes, in: 1...240)
                    Text("Requires \(draft.requiredCorrect) correct answers.")
                    Text("Allowance is configuration only until Screen Time integration is complete.").font(.caption)
                }
                Button("Save for next lesson") { store.savePlan(draft) }
                    .disabled(!(1...100).contains(draft.questionCount))
                Text("An active lesson keeps its original plan.").font(.caption)
            }
            .navigationTitle("Lesson plan")
            .onAppear {
                let plan = store.state.plan
                addition = plan.items.first { $0.skill == .addition }?.count ?? 0
                subtraction = plan.items.first { $0.skill == .subtraction }?.count ?? 0
                multiplication = plan.items.first { $0.skill == .multiplication }?.count ?? 0
                percent = plan.passingPercent; minutes = plan.allowanceMinutes
            }
        }
    }
}

struct ProgressViewScreen: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        NavigationStack {
            List {
                Section("Completed lessons") {
                    if store.state.history.isEmpty { Text("Complete a lesson to see progress here.") }
                    ForEach(store.state.history.reversed()) { lesson in
                        VStack(alignment: .leading) {
                            Text(lesson.passed ? "Passed" : "Practice needed").bold()
                            Text("\(lesson.correctCount)/\(lesson.questions.count) · required \(lesson.plan.passingPercent)%")
                            Text(lesson.startedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }.navigationTitle("Progress")
        }
    }
}
