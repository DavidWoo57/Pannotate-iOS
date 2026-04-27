import SwiftUI

struct OnboardingGuideView: View {
    var showSkipButton = true
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var selection = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $selection) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            BrandHeader()

            Spacer()

            if showSkipButton {
                Button(L10n.string("common.skip")) {
                    complete()
                }
                .font(PannotateTheme.Typography.control)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func onboardingPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 22) {
                Image(systemName: page.systemImage)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 96, height: 96)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.64))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(PannotateTheme.Colors.accent.opacity(0.24), lineWidth: 1))

                VStack(spacing: 10) {
                    Text(L10n.string(page.titleKey))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.string(page.subtitleKey))
                        .font(PannotateTheme.Typography.bodyEmphasis)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.detailKeys, id: \.self) { detailKey in
                        Label {
                            Text(L10n.string(detailKey))
                                .font(PannotateTheme.Typography.metadata)
                                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(PannotateTheme.Colors.accent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .pannotateCard()
            }
            .padding(PannotateTheme.Metrics.pagePadding)

            Spacer(minLength: 20)
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selection ? PannotateTheme.Colors.accent : PannotateTheme.Colors.tertiaryText.opacity(0.28))
                        .frame(width: index == selection ? 24 : 7, height: 7)
                        .animation(.easeInOut(duration: 0.2), value: selection)
                }
            }
            .accessibilityHidden(true)

            Button {
                if selection == pages.count - 1 {
                    complete()
                } else {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        selection += 1
                    }
                }
            } label: {
                Text(selection == pages.count - 1 ? L10n.string("onboarding.get_started") : L10n.string("common.next"))
                    .font(PannotateTheme.Typography.control)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: PannotateTheme.Metrics.buttonHeight)
                    .background(PannotateTheme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(PannotateTheme.Colors.background.opacity(0.98))
    }

    private func complete() {
        onComplete()
        dismiss()
    }
}

private struct OnboardingPage {
    let titleKey: String
    let subtitleKey: String
    let detailKeys: [String]
    let systemImage: String

    static let pages = [
        OnboardingPage(
            titleKey: "onboarding.page1.title",
            subtitleKey: "onboarding.page1.subtitle",
            detailKeys: ["onboarding.page1.detail1", "onboarding.page1.detail2"],
            systemImage: "sparkles.rectangle.stack"
        ),
        OnboardingPage(
            titleKey: "onboarding.page2.title",
            subtitleKey: "onboarding.page2.subtitle",
            detailKeys: ["onboarding.page2.detail1", "onboarding.page2.detail2"],
            systemImage: "folder.badge.plus"
        ),
        OnboardingPage(
            titleKey: "onboarding.page3.title",
            subtitleKey: "onboarding.page3.subtitle",
            detailKeys: ["onboarding.page3.detail1", "onboarding.page3.detail2"],
            systemImage: "pencil.and.outline"
        ),
        OnboardingPage(
            titleKey: "onboarding.page4.title",
            subtitleKey: "onboarding.page4.subtitle",
            detailKeys: ["onboarding.page4.detail1", "onboarding.page4.detail2"],
            systemImage: "brain.head.profile"
        ),
        OnboardingPage(
            titleKey: "onboarding.page5.title",
            subtitleKey: "onboarding.page5.subtitle",
            detailKeys: ["onboarding.page5.detail1", "onboarding.page5.detail2"],
            systemImage: "film.stack"
        ),
        OnboardingPage(
            titleKey: "onboarding.page6.title",
            subtitleKey: "onboarding.page6.subtitle",
            detailKeys: ["onboarding.page6.detail1", "onboarding.page6.detail2"],
            systemImage: "square.stack.3d.up"
        )
    ]
}

#Preview {
    OnboardingGuideView()
}
