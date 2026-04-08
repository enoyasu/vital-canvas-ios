import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var isRequestingPermission = false

    var controller: AppController
    var languageManager: LanguageManager

    private var s: Strings { languageManager.s }

    private var pages: [(symbol: String, title: String, body: String)] {
        [
            ("sparkles", s.ob1Title, s.ob1Body),
            ("lock.shield", s.ob2Title, s.ob2Body),
            ("leaf", s.ob3Title, s.ob3Body)
        ]
    }

    var body: some View {
        ZStack {
            VCColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(symbolName: page.symbol, title: page.title, body: page.body)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)

                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? VCColor.accent : Color.white.opacity(0.2))
                            .frame(width: i == currentPage ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, VCSpacing.lg)

                Spacer()

                VStack(spacing: VCSpacing.md) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text(s.obContinue)
                                .font(VCFont.body(17))
                                .foregroundStyle(VCColor.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(VCColor.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    } else {
                        Button {
                            Task { await connectHealth() }
                        } label: {
                            HStack(spacing: 8) {
                                if isRequestingPermission {
                                    ProgressView().tint(VCColor.background)
                                } else {
                                    Image(systemName: "heart.fill")
                                }
                                Text(s.obConnect)
                                    .font(VCFont.body(17))
                            }
                            .foregroundStyle(VCColor.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(VCColor.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(isRequestingPermission)

                        Button(s.obSkip) {
                            controller.completeOnboarding(modelContext: modelContext)
                        }
                        .font(VCFont.body(15))
                        .foregroundStyle(VCColor.textTertiary)
                    }
                }
                .padding(.horizontal, VCSpacing.xl)
                .padding(.bottom, VCSpacing.xxl)
            }
        }
    }

    private func connectHealth() async {
        isRequestingPermission = true
        await controller.requestHealthPermissions()
        controller.completeOnboarding(modelContext: modelContext)
        isRequestingPermission = false
    }
}

private struct OnboardingPageView: View {
    let symbolName: String
    let title: String
    let body: String

    var body: some View {
        VStack(spacing: VCSpacing.xl) {
            ZStack {
                Circle()
                    .fill(VCColor.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: symbolName)
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(VCColor.accent)
            }
            VStack(spacing: VCSpacing.md) {
                Text(title)
                    .font(VCFont.display(30))
                    .foregroundStyle(VCColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(body)
                    .font(VCFont.body(15))
                    .foregroundStyle(VCColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, VCSpacing.md)
            }
        }
        .padding(VCSpacing.xl)
    }
}
