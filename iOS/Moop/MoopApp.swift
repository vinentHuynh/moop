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
            EntryView()
                .environmentObject(store)
                .tint(Color.moopBlue)
                .preferredColorScheme(.light)
                .alert("Moop", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("OK") { store.error = nil }
                } message: { Text(store.error ?? "") }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab = MoopTab.learn
    @State private var inLesson = false
    @State private var feedback: AnswerFeedback?

    var body: some View {
        let active = store.state.active
        let showResult = active?.isComplete == true && feedback == nil
        let showLesson = active != nil && !showResult && (inLesson || feedback != nil)
        VStack(spacing: 0) {
            if let session = active, showLesson {
                LessonView(session: session, feedback: $feedback, onPause: pause)
            } else if let session = active, showResult {
                ResultView(session: session, onDone: finish, onTryAgain: tryAgain)
            } else {
                Group {
                    switch tab {
                    case .learn: HomeView(onStart: start)
                    case .stars: StarsView()
                    }
                }
                .frame(maxHeight: .infinity)
                MoopTabBar(selection: $tab)
            }
        }
        .background(Color.moopSky.ignoresSafeArea())
    }

    private func start() {
        store.start()
        inLesson = store.state.active != nil
    }

    private func pause() {
        feedback = nil
        inLesson = false
    }

    private func finish() {
        store.dismissResult()
        feedback = nil
        inLesson = false
        tab = .learn
    }

    private func tryAgain() {
        finish()
        start()
    }
}
