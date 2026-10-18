import XCTest
@testable import MoopCore

final class LearningTests: XCTestCase {
    func testBanksMatchSkillConstraints() {
        XCTAssertEqual(Question.bank(for: .subtraction).count, 55)
        XCTAssertEqual(Question.bank(for: .multiplication).count, 100)
        XCTAssertTrue(Question.bank(for: .addition).allSatisfy { $0.answer <= 10 })
        XCTAssertTrue(Question.bank(for: .subtraction).allSatisfy { $0.answer >= 0 })
        XCTAssertEqual(Question(skill: .multiplication, lhs: 7, rhs: 8).answer, 56)
    }
    func testPassThresholdRoundsUpAndRequiresCompletion() throws {
        let plan = LessonPlan(items: [.init(skill: .addition, count: 7)], passingPercent: 80)
        XCTAssertEqual(plan.requiredCorrect, 6)
        var rng = SystemRandomNumberGenerator()
        var session = try plan.makeSession(using: &rng)
        for _ in 0..<6 { try session.submit(session.currentQuestion!.answer) }
        XCTAssertFalse(session.passed)
        try session.submit(-1)
        XCTAssertTrue(session.passed)
        XCTAssertThrowsError(try session.submit(0))
    }
    func testFailedLessonAndPlanSnapshot() throws {
        var plan = LessonPlan.sample
        var rng = SystemRandomNumberGenerator()
        var session = try plan.makeSession(using: &rng)
        plan.passingPercent = 50
        XCTAssertEqual(session.plan.passingPercent, 80)
        XCTAssertEqual(session.questions.filter { $0.skill == .addition }.count, 10)
        XCTAssertEqual(session.questions.filter { $0.skill == .subtraction }.count, 10)
        while !session.isComplete { try session.submit(-1) }
        XCTAssertFalse(session.passed)
        try session.validate()
    }
    func testResumeAndNoStoredCorrectAnswer() throws {
        var rng = SystemRandomNumberGenerator()
        var session = try LessonPlan.sample.makeSession(using: &rng)
        try session.submit(session.currentQuestion!.answer)
        let data = try JSONEncoder().encode(session)
        let restored = try JSONDecoder().decode(LessonSession.self, from: data)
        XCTAssertEqual(session, restored)
        try restored.validate()
        let questionData = try JSONEncoder().encode(session.questions[0])
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: questionData) as? [String: Any])
        XCTAssertNil(json["answer"])
    }
    func testInvalidPlansAreRejected() {
        XCTAssertThrowsError(try LessonPlan(items: []).validate())
        XCTAssertThrowsError(try LessonPlan(items: [.init(skill: .addition, count: -1)]).validate())
        XCTAssertThrowsError(try LessonPlan(items: [.init(skill: .addition, count: 1)], passingPercent: 101).validate())
        XCTAssertThrowsError(try LessonPlan(items: [.init(skill: .addition, count: 1), .init(skill: .addition, count: 2)]).validate())
    }
}
