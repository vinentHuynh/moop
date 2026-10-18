import SwiftUI
import MoopCore

struct StarsView: View {
    @EnvironmentObject var store: AppStore

    private struct WeekDay: Identifiable {
        let id: Date
        let letter: String
        let earned: Bool
    }

    var body: some View {
        let history = store.state.history
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("My stars").font(.moop(.largeTitle))
                weekCard(history)
                skillsGrid(history)
                missions(history)
            }
            .padding(24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.moopInk)
    }

    private func weekCard(_ history: [LessonSession]) -> some View {
        let days = week(history)
        let stars = days.filter(\.earned).count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week").font(.moop(.headline, weight: .heavy))
                Spacer()
                Text(stars == 1 ? "1 star" : "\(stars) stars")
                    .font(.moop(.subheadline))
                    .foregroundStyle(Color(hex: 0xD4DCF5))
            }
            HStack(spacing: 0) {
                ForEach(days) { day in
                    VStack(spacing: 4) {
                        Image(systemName: day.earned ? "star.fill" : "star")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(day.earned ? Color.moopSun : Color.moopFaint)
                        Text(day.letter).font(.moop(.footnote, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.id.formatted(.dateTime.weekday(.wide))): \(day.earned ? "star earned" : "no star")")
                }
            }
        }
        .foregroundStyle(Color.white)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.moopInk))
    }

    @ViewBuilder
    private func skillsGrid(_ history: [LessonSession]) -> some View {
        let skills = Skill.allCases.map { ($0, recentAccuracy(for: $0, in: history)) }.filter { $0.1.total > 0 }
        if !skills.isEmpty {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                ForEach(skills, id: \.0) { skill, result in
                    let ratio = Double(result.correct) / Double(result.total)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            SkillSymbolTile(skill: skill, size: 28)
                            Text(skill.kidName).font(.moop(.subheadline, weight: .heavy))
                        }
                        ChunkyProgressBar(value: ratio, fill: skill.tileColor, track: .moopSky, height: 10)
                        Text(ratio >= 0.9 ? "Super strong" : (ratio >= 0.7 ? "Getting stronger" : "Keep practicing"))
                            .font(.moop(.footnote))
                            .foregroundStyle(Color.moopInkSoft)
                    }
                    .moopCard(padding: 14, radius: 22)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private func missions(_ history: [LessonSession]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My missions").font(.moop(.title3, weight: .semibold))
            if history.isEmpty {
                HStack(spacing: 12) {
                    MoopMascot(size: 72)
                    Text("Finish your first mission to earn a star!").font(.moop(.headline))
                }
                .moopCard(padding: 16, radius: 22)
            }
            ForEach(Array(history.reversed())) { lesson in
                HStack(spacing: 14) {
                    if lesson.passed {
                        Image(systemName: "star.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.moopSun)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Color.moopBlueDeep)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.moopBlueTint))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.passed ? "Mission complete" : "Practice round").font(.moop(.headline, weight: .heavy))
                        Text("\((lesson.completedAt ?? lesson.startedAt).formatted(.dateTime.weekday(.wide).month().day())) · \(lesson.correctCount) of \(lesson.questions.count)")
                            .font(.moop(.subheadline, weight: .semibold))
                            .foregroundStyle(Color.moopInkSoft)
                    }
                    Spacer(minLength: 0)
                    if lesson.passed {
                        Pill(text: "+\(lesson.plan.allowanceMinutes) min", fill: .moopSunTint)
                    }
                }
                .moopCard(padding: 14, radius: 22)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func week(_ history: [LessonSession]) -> [WeekDay] {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        let passedDays = Set(history.filter(\.passed).compactMap { $0.completedAt.map { calendar.startOfDay(for: $0) } })
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let letter = calendar.veryShortStandaloneWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            return WeekDay(id: day, letter: letter, earned: passedDays.contains(calendar.startOfDay(for: day)))
        }
    }

    /// Accuracy over the most recent 30 answers for a skill.
    private func recentAccuracy(for skill: Skill, in history: [LessonSession]) -> (correct: Int, total: Int) {
        var results: [Bool] = []
        for lesson in history {
            for (index, attempt) in lesson.attempts.enumerated() where lesson.questions[index].skill == skill {
                results.append(attempt.wasCorrect)
            }
        }
        let recent = results.suffix(30)
        return (recent.filter { $0 }.count, recent.count)
    }
}
