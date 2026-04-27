import SwiftUI

enum AuthMode: String {
    case guest
    case appleMock
    case googleMock
    case emailMock
}

struct AuthWelcomeView: View {
    var onContinue: (AuthMode) -> Void

    @State private var activePlaceholder: AuthPlaceholder?

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 36)

            VStack(spacing: 18) {
                appMark

                VStack(spacing: 8) {
                    Text("app.name")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text("auth.tagline")
                        .font(PannotateTheme.Typography.bodyEmphasis)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, PannotateTheme.Metrics.pagePadding)

            Spacer(minLength: 28)

            signInPanel
        }
        .background(authBackground)
        .alert(item: $activePlaceholder) { placeholder in
            Alert(
                title: Text(placeholder.titleKey),
                message: Text(placeholder.messageKey),
                dismissButton: .default(Text("common.ok"))
            )
        }
    }

    private var appMark: some View {
        ZStack {
            Circle()
                .fill(PannotateTheme.brandGradient)
                .frame(width: 108, height: 108)
                .shadow(color: PannotateTheme.Colors.accent.opacity(0.28), radius: 28, y: 14)

            Image(systemName: "pencil.and.sparkles")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var signInPanel: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("auth.welcome_title")
                    .font(PannotateTheme.Typography.sectionTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text("auth.welcome_subtitle")
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 4)

            authButton(title: L10n.string("auth.continue_with_apple"), systemImage: "apple.logo", style: .primary) {
                activePlaceholder = .apple
            }

            authButton(title: L10n.string("auth.continue_with_google"), systemImage: "globe", style: .secondary) {
                activePlaceholder = .google
            }

            authButton(title: L10n.string("auth.continue_with_email"), systemImage: "envelope", style: .secondary) {
                activePlaceholder = .email
            }

            Button {
                onContinue(.guest)
            } label: {
                Text("auth.continue_as_guest")
                    .font(PannotateTheme.Typography.control)
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: PannotateTheme.Metrics.buttonHeight)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.42))
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                            .stroke(PannotateTheme.Colors.accent.opacity(0.24), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .pannotateCard()
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.bottom, 24)
    }

    private func authButton(title: String, systemImage: String, style: AuthButtonStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .frame(width: 22)

                Text(title)
                    .font(PannotateTheme.Typography.control)

                Spacer(minLength: 0)
            }
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: PannotateTheme.Metrics.buttonHeight)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                    .stroke(style.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var authBackground: some View {
        ZStack {
            PannotateTheme.Colors.background.ignoresSafeArea()

            Circle()
                .fill(PannotateTheme.Colors.accentSoft.opacity(0.34))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(x: -120, y: -220)

            Circle()
                .fill(PannotateTheme.Colors.purple.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 46)
                .offset(x: 120, y: 160)
        }
    }
}

private enum AuthButtonStyle {
    case primary
    case secondary

    var foreground: Color {
        switch self {
        case .primary:
            PannotateTheme.Colors.background
        case .secondary:
            PannotateTheme.Colors.primaryText
        }
    }

    var background: Color {
        switch self {
        case .primary:
            PannotateTheme.Colors.primaryText
        case .secondary:
            PannotateTheme.Colors.cardMuted
        }
    }

    var border: Color {
        switch self {
        case .primary:
            .clear
        case .secondary:
            PannotateTheme.Colors.border
        }
    }
}

private enum AuthPlaceholder: Identifiable {
    case apple
    case google
    case email

    var id: String {
        switch self {
        case .apple: "apple"
        case .google: "google"
        case .email: "email"
        }
    }

    var titleKey: String {
        switch self {
        case .apple: "auth.apple_placeholder_title"
        case .google: "auth.google_placeholder_title"
        case .email: "auth.email_placeholder_title"
        }
    }

    var messageKey: String {
        switch self {
        case .apple: "auth.apple_placeholder_message"
        case .google: "auth.google_placeholder_message"
        case .email: "auth.email_placeholder_message"
        }
    }
}

#Preview {
    AuthWelcomeView { _ in }
}
