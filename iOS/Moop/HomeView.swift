import SwiftUI
import MoopCore

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    let onStart: () -> Void
    @State private var showingGrownUps = false

    var body: some View {
        let active = store.state.active
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                HStack(alignment: .bottom, spacing: 8) {
                    MoopMascot(size: 120)
                    Text(active == nil ? "Ready for today's math mission?" : "Let's finish your mission!")
                        .font(.moop(.title3, weight: .semibold))
                        .foregroundStyle(Color.moopInk)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 6,
                                                   bottomTrailingRadius: 24, topTrailingRadius: 24, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .moopLine, radius: 0, x: 0, y: 3)
                        )
                        .padding(.bottom, 36)
                }
                missionCard(plan: active?.plan ?? store.state.plan)
                VStack(spacing: 12) {
                    Button(action: onStart) {
                        HStack(spacing: 10) {
                            Text(startTitle(active))
                            Image(systemName: "arrow.right").fontWeight(.heavy)
                        }
                    }
                    .buttonStyle(ChunkyButtonStyle())
                    Text("Prototype: earned play time is not connected to device limits yet.")
                        .font(.moop(.footnote, weight: .semibold))
                        .foregroundStyle(Color.moopInkSoft)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showingGrownUps) {
            GrownUpsView().environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.moop(.subheadline))
                    .foregroundStyle(Color.moopInkSoft)
                Text("Hi, math explorer!")
                    .font(.moop(.title2))
                    .foregroundStyle(Color.moopInk)
            }
            Spacer()
            Button { showingGrownUps = true } label: { IconTileLabel(systemName: "lock.fill") }
                .accessibilityLabel("Grown-ups area")
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private func startTitle(_ active: LessonSession?) -> String {
        guard let active, !active.isComplete else { return "Let's go!" }
        return "Keep going · \(active.attempts.count + 1) of \(active.questions.count)"
    }

    private func missionCard(plan: LessonPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's mission").font(.moop(.title2))
                Spacer()
                Pill(text: "\(plan.questionCount) questions", fill: .moopBlueTint, foreground: .moopBlueDeep)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                ForEach(plan.items.filter { $0.count > 0 }, id: \.skill) { item in
                    HStack(spacing: 12) {
                        SkillSymbolTile(skill: item.skill)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.skill.kidName).font(.moop(.headline, weight: .heavy))
                            Text("\(item.count) questions")
                                .font(.moop(.subheadline, weight: .semibold))
                                .foregroundStyle(Color.moopInkSoft)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(item.skill.tint))
                    .accessibilityElement(children: .combine)
                }
            }
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.moopSun)
                    .accessibilityHidden(true)
                (Text("Get ") + Text("\(plan.requiredCorrect) right").fontWeight(.heavy)
                 + Text(" to earn ") + Text("\(plan.allowanceMinutes) minutes").fontWeight(.heavy)
                 + Text(" of play time"))
                    .font(.moop(.callout, weight: .semibold))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.moopSunTint))
        }
        .foregroundStyle(Color.moopInk)
        .moopCard(padding: 22, radius: 32)
    }
}

enum MoopTab { case learn, stars }

struct MoopTabBar: View {
    @Binding var selection: MoopTab

    var body: some View {
        HStack(spacing: 8) {
            item(.learn, title: "Learn", icon: "house.fill")
            item(.stars, title: "My stars", icon: "star.fill")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: .moopLine, radius: 0, x: 0, y: 3)
        )
        .frame(maxWidth: 600)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func item(_ tab: MoopTab, title: String, icon: String) -> some View {
        let selected = selection == tab
        return Button { selection = tab } label: {
            Label(title, systemImage: icon)
                .font(.moop(.headline, weight: .heavy))
                .foregroundStyle(selected ? Color.white : Color.moopInk)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(selected ? Color.moopInk : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
