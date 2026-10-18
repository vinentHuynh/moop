import SwiftUI

/// How the person entered the app. Stored locally; there is no account backend yet.
enum EntryMode: String {
    case none = ""
    case demo
}

struct EntryView: View {
    @AppStorage("moop.entryMode") private var entryMode = EntryMode.none.rawValue

    var body: some View {
        if entryMode == EntryMode.none.rawValue {
            LoginView { entryMode = EntryMode.demo.rawValue }
        } else {
            RootView()
        }
    }
}

/// Sign-in screen. The Apple and Google buttons are UI only until authentication is implemented.
struct LoginView: View {
    let onDemo: () -> Void
    @State private var unavailableProvider: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    MoopMascot(mood: .cheering, size: 170)
                    Text("moop")
                        .font(.moopNumber(56))
                    Text("A little math. A little more freedom.")
                        .font(.moop(.title3, weight: .semibold))
                        .foregroundStyle(Color.moopInkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Grown-ups, sign in")
                        .font(.moop(.title3))
                    Text("Save progress and set your child's missions.")
                        .font(.moop(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.moopInkSoft)

                    Button { unavailableProvider = "Apple" } label: {
                        Label("Sign in with Apple", systemImage: "apple.logo")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black))
                    }
                    .buttonStyle(.plain)

                    Button { unavailableProvider = "Google" } label: {
                        Label("Sign in with Google", systemImage: "globe")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(Color.moopInk)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.moopParentLine, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 12) {
                        Rectangle().fill(Color.moopLine).frame(height: 1.5)
                        Text("or").font(.moop(.subheadline, weight: .heavy)).foregroundStyle(Color.moopInkSoft)
                        Rectangle().fill(Color.moopLine).frame(height: 1.5)
                    }
                    .accessibilityHidden(true)

                    Button(action: onDemo) {
                        HStack(spacing: 10) {
                            Text("Try the demo")
                            Image(systemName: "arrow.right").fontWeight(.heavy)
                        }
                    }
                    .buttonStyle(ChunkyButtonStyle(height: 62, radius: 20))

                    Text("The demo keeps everything on this device. No account needed.")
                        .font(.moop(.footnote, weight: .semibold))
                        .foregroundStyle(Color.moopInkSoft)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .moopCard(padding: 22, radius: 32)
            }
            .foregroundStyle(Color.moopInk)
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color.moopSky.ignoresSafeArea())
        .alert("Coming soon",
               isPresented: Binding(get: { unavailableProvider != nil }, set: { if !$0 { unavailableProvider = nil } })) {
            Button("Try the demo", action: onDemo)
            Button("OK", role: .cancel) {}
        } message: {
            Text("Sign in with \(unavailableProvider ?? "") isn't connected yet. Try the demo to explore moop.")
        }
    }
}
