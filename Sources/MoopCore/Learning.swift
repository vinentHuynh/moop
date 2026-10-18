import Foundation

public enum Skill: String, Codable, CaseIterable, Identifiable, Sendable {
    case addition = "ADD02", subtraction = "SUB02", multiplication = "MUL04"
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .addition: return "Single-digit addition · sums up to 10"
        case .subtraction: return "Single-digit subtraction · no negatives"
        case .multiplication: return "Single-digit multiplication"
        }
    }
    public var symbol: String {
        switch self { case .addition: return "+"; case .subtraction: return "−"; case .multiplication: return "×" }
    }
}

public struct Question: Codable, Identifiable, Equatable, Sendable {
    public let skill: Skill
    public let lhs: Int
    public let rhs: Int
    public let evaluatorVersion: Int
    public var id: String { "\(skill.rawValue)-v\(evaluatorVersion)-\(lhs)-\(rhs)" }
    public var prompt: String { "\(lhs) \(skill.symbol) \(rhs)" }
    // Computed properties are intentionally not encoded into stored questions.
    public var answer: Int {
        switch skill { case .addition: return lhs + rhs; case .subtraction: return lhs - rhs; case .multiplication: return lhs * rhs }
    }
    public init(skill: Skill, lhs: Int, rhs: Int) {
        self.skill = skill; self.lhs = lhs; self.rhs = rhs; self.evaluatorVersion = 1
    }
    public static func bank(for skill: Skill) -> [Question] {
        (0...9).flatMap { a in
            (0...9).compactMap { b -> Question? in
                if skill == .addition && a + b > 10 { return nil }
                if skill == .subtraction && b > a { return nil }
                return Question(skill: skill, lhs: a, rhs: b)
            }
        }
    }
}

public enum LearningError: Error, LocalizedError {
    case invalidPlan, exhausted, invalidSession
    public var errorDescription: String? {
        switch self {
        case .invalidPlan: return "Choose 1–100 questions, a passing score from 1–100%, and an allowance from 1–240 minutes. Counts must be nonnegative and skills unique."
        case .exhausted: return "This lesson is already complete."
        case .invalidSession: return "The saved lesson is invalid or uses an unsupported version."
        }
    }
}

public struct PlanItem: Codable, Equatable, Sendable {
    public var skill: Skill
    public var count: Int
    public init(skill: Skill, count: Int) { self.skill = skill; self.count = count }
}

public struct LessonPlan: Codable, Equatable, Sendable {
    public var items: [PlanItem]
    public var passingPercent: Int
    public var allowanceMinutes: Int
    public init(items: [PlanItem], passingPercent: Int = 80, allowanceMinutes: Int = 30) {
        self.items = items; self.passingPercent = passingPercent; self.allowanceMinutes = allowanceMinutes
    }
    public static var sample: LessonPlan {
        LessonPlan(items: [.init(skill: .addition, count: 10), .init(skill: .subtraction, count: 10)])
    }
    public var questionCount: Int { items.reduce(0) { $0 + $1.count } }
    public var requiredCorrect: Int { (questionCount * passingPercent + 99) / 100 }
    public func validate() throws {
        guard items.allSatisfy({ (0...100).contains($0.count) }),
              Set(items.map(\.skill)).count == items.count,
              (1...100).contains(questionCount), (1...100).contains(passingPercent),
              (1...240).contains(allowanceMinutes) else { throw LearningError.invalidPlan }
    }
    public func makeSession<R: RandomNumberGenerator>(using rng: inout R) throws -> LessonSession {
        try validate()
        var questions: [Question] = []
        for item in items {
            var remaining = item.count
            while remaining > 0 {
                let bank = Question.bank(for: item.skill).shuffled(using: &rng)
                let selected = Array(bank.prefix(remaining))
                questions += selected
                remaining -= selected.count
            }
        }
        return LessonSession(plan: self, questions: questions.shuffled(using: &rng))
    }
}

public struct AnswerAttempt: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let questionID: String
    public let submittedAnswer: Int
    public let wasCorrect: Bool
    public let submittedAt: Date
}

public struct LessonSession: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let plan: LessonPlan
    public let questions: [Question]
    public private(set) var attempts: [AnswerAttempt]
    public let startedAt: Date
    public private(set) var completedAt: Date?
    init(plan: LessonPlan, questions: [Question]) {
        id = UUID(); self.plan = plan; self.questions = questions
        attempts = []; startedAt = Date(); completedAt = nil
    }
    public var isComplete: Bool { attempts.count == questions.count }
    public var correctCount: Int { attempts.filter(\.wasCorrect).count }
    public var passed: Bool { isComplete && correctCount >= plan.requiredCorrect }
    public var currentQuestion: Question? { isComplete ? nil : questions[attempts.count] }
    public mutating func submit(_ answer: Int, at date: Date = Date()) throws {
        guard let question = currentQuestion else { throw LearningError.exhausted }
        attempts.append(AnswerAttempt(id: UUID(), questionID: question.id, submittedAnswer: answer,
                                      wasCorrect: answer == question.answer, submittedAt: date))
        if isComplete { completedAt = date }
    }
    public func validate() throws {
        try plan.validate()
        guard questions.count == plan.questionCount, attempts.count <= questions.count,
              (completedAt != nil) == isComplete,
              questions.allSatisfy({ Question.bank(for: $0.skill).contains($0) }) else { throw LearningError.invalidSession }
        for item in plan.items {
            guard questions.filter({ $0.skill == item.skill }).count == item.count else { throw LearningError.invalidSession }
        }
        for (index, attempt) in attempts.enumerated() {
            let question = questions[index]
            guard attempt.questionID == question.id,
                  attempt.wasCorrect == (attempt.submittedAnswer == question.answer) else { throw LearningError.invalidSession }
        }
    }
}
