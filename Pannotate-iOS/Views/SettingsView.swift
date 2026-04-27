import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var selectedThemeRawValue = AppTheme.dark.rawValue
    @AppStorage("hasCompletedAuthWelcome") private var hasCompletedAuthWelcome = false
    @AppStorage("authMode") private var authModeRawValue = AuthMode.guest.rawValue
    @State private var pushNotificationsEnabled = true
    @State private var outputQuality = "Standard"
    @State private var autoChainClips = false
    @State private var motionSmoothing = true
    @State private var showSignOutConfirmation = false

    private let qualities = [
        ("Draft", "settings.quality.draft", "settings.quality.draft_subtitle"),
        ("Standard", "settings.quality.standard", "settings.quality.standard_subtitle"),
        ("High", "settings.quality.high", "settings.quality.high_subtitle")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                settingsSection(L10n.string("settings.section.appearance")) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("settings.theme")
                            .font(PannotateTheme.Typography.cardTitle)
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)

                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases) { theme in
                                optionTile(
                                    title: theme.title,
                                    subtitle: nil,
                                    systemImage: theme.systemImage,
                                    isSelected: selectedTheme == theme
                                ) {
                                    selectedTheme = theme
                                }
                            }
                        }
                    }
                    .padding(16)
                    .pannotateCard()
                }

                settingsSection(L10n.string("settings.notifications")) {
                    toggleRow(
                        title: L10n.string("settings.push_notifications"),
                        subtitle: L10n.string("settings.push_notifications_subtitle"),
                        systemImage: "bell",
                        isOn: $pushNotificationsEnabled
                    )
                }

                settingsSection(L10n.string("settings.section.generation")) {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.output_quality")
                                .font(PannotateTheme.Typography.cardTitle)
                                .foregroundStyle(PannotateTheme.Colors.secondaryText)

                            HStack(spacing: 12) {
                                ForEach(qualities, id: \.0) { quality in
                                    optionTile(
                                        title: L10n.string(quality.1),
                                        subtitle: L10n.string(quality.2),
                                        systemImage: nil,
                                        isSelected: outputQuality == quality.0
                                    ) {
                                        outputQuality = quality.0
                                    }
                                }
                            }
                        }

                        toggleRowContent(
                            title: L10n.string("settings.auto_chain_clips"),
                            subtitle: L10n.string("settings.auto_chain_clips_subtitle"),
                            systemImage: "bolt",
                            isOn: $autoChainClips
                        )

                        toggleRowContent(
                            title: L10n.string("settings.motion_smoothing"),
                            subtitle: L10n.string("settings.motion_smoothing_subtitle"),
                            systemImage: "waveform.path",
                            isOn: $motionSmoothing
                        )

                        Divider()
                            .overlay(PannotateTheme.Colors.border)

                        NavigationLink {
                            AIServicesSettingsView()
                        } label: {
                            settingsLinkContent(
                                title: L10n.string("ai_services.title"),
                                detail: L10n.string("ai_services.settings_subtitle"),
                                systemImage: "cpu"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .pannotateCard()
                }

                settingsSection(L10n.string("settings.account")) {
                    VStack(spacing: 0) {
                        accountModeRow
                        settingsLink(title: L10n.string("settings.subscription"), systemImage: "creditcard")
                        settingsLink(title: L10n.string("settings.privacy_data"), systemImage: "lock.shield")
                        settingsLink(title: L10n.string("settings.connected_accounts"), systemImage: "person.2")
                        signOutButton
                    }
                    .pannotateCard()
                }

                settingsSection(L10n.string("settings.about")) {
                    VStack(spacing: 0) {
                        NavigationLink {
                            OnboardingGuideView(showSkipButton: false)
                        } label: {
                            settingsLinkContent(
                                title: L10n.string("onboarding.help_title"),
                                detail: L10n.string("onboarding.help_subtitle"),
                                systemImage: "questionmark.circle"
                            )
                            .padding(16)
                        }
                        .buttonStyle(.plain)

                        settingsLink(title: L10n.string("app.name"), detail: L10n.string("settings.version_1"), systemImage: "bolt")
                        settingsLink(title: L10n.string("settings.terms"), systemImage: "doc.text")
                        settingsLink(title: L10n.string("settings.privacy_policy"), systemImage: "hand.raised")
                    }
                    .pannotateCard()
                }
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .padding(.bottom, 48)
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(L10n.string("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PannotateTheme.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert(L10n.string("auth.sign_out_confirmation_title"), isPresented: $showSignOutConfirmation) {
            Button("settings.sign_out", role: .destructive) {
                signOut()
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("auth.sign_out_confirmation_message")
        }
    }


    private var accountModeRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle")
                .font(.headline)
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 38, height: 38)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("auth.account_mode")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(authModeTitle)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }

            Spacer()

            Text(authModeTitle)
                .font(PannotateTheme.Typography.label)
                .foregroundStyle(PannotateTheme.Colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                .clipShape(Capsule())
        }
        .padding(16)
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            showSignOutConfirmation = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.headline)
                    .foregroundStyle(Color.red)
                    .frame(width: 38, height: 38)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Circle())

                Text("settings.sign_out")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(Color.red)

                Spacer()
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private var authModeTitle: String {
        switch AuthMode(rawValue: authModeRawValue) ?? .guest {
        case .guest:
            L10n.string("auth.guest_mode")
        case .appleMock:
            L10n.string("auth.apple_mock_mode")
        case .googleMock:
            L10n.string("auth.google_mock_mode")
        case .emailMock:
            L10n.string("auth.email_mock_mode")
        }
    }

    private func signOut() {
        authModeRawValue = AuthMode.guest.rawValue
        hasCompletedAuthWelcome = false
    }

    private var selectedTheme: AppTheme {
        get {
            AppTheme(rawValue: selectedThemeRawValue) ?? .system
        }
        nonmutating set {
            selectedThemeRawValue = newValue.rawValue
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            SectionLabel(title: title)
            content()
        }
    }

    private func optionTile(
        title: String,
        subtitle: String?,
        systemImage: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                }

                Text(title)
                    .font(PannotateTheme.Typography.metadataEmphasis)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
            }
            .foregroundStyle(isSelected ? PannotateTheme.Colors.accent : PannotateTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(isSelected ? PannotateTheme.Colors.accentSoft.opacity(0.62) : PannotateTheme.Colors.cardMuted)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                    .stroke(isSelected ? PannotateTheme.Colors.accent.opacity(0.72) : PannotateTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        toggleRowContent(title: title, subtitle: subtitle, systemImage: systemImage, isOn: isOn)
            .padding(16)
            .pannotateCard()
    }

    private func toggleRowContent(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(width: 46, height: 46)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(subtitle)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(PannotateTheme.Colors.accent)
        }
    }

    private func settingsLink(title: String, detail: String? = nil, systemImage: String) -> some View {
        settingsLinkContent(title: title, detail: detail, systemImage: systemImage)
            .padding(16)
    }

    private func settingsLinkContent(title: String, detail: String? = nil, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 38, height: 38)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                if let detail {
                    Text(detail)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
        }
    }
}

private struct AIServicesSettingsView: View {
    @AppStorage("useMockAIServices") private var useMockServices = true
    @State private var visualLLMAPIKey = ""
    @State private var videoAPIKey = ""
    @State private var showMockRequiredAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                mockModeSection

                serviceSection(
                    title: L10n.string("ai_services.visual_understanding"),
                    systemImage: "eye",
                    description: L10n.string("ai_services.visual_understanding_description"),
                    apiKeyTitle: L10n.string("ai_services.visual_llm_api_key"),
                    apiKey: $visualLLMAPIKey
                )

                serviceSection(
                    title: L10n.string("ai_services.video_generation"),
                    systemImage: "play.rectangle",
                    description: L10n.string("ai_services.video_generation_description"),
                    apiKeyTitle: L10n.string("ai_services.video_api_key"),
                    apiKey: $videoAPIKey
                )

                Text("ai_services.storage_note")
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .padding(.bottom, 48)
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(L10n.string("ai_services.title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.string("ai_services.mock_required_title"), isPresented: $showMockRequiredAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("ai_services.mock_required_message")
        }
    }

    private var mockModeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: mockServicesBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ai_services.use_mock_services")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text("ai_services.real_api_later")
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                }
            }
            .tint(PannotateTheme.Colors.accent)

            statusPill(L10n.string("ai_services.mock_mode"), color: PannotateTheme.Colors.accent)
        }
        .padding(16)
        .pannotateCard()
    }

    private var mockServicesBinding: Binding<Bool> {
        Binding {
            useMockServices
        } set: { newValue in
            if newValue {
                useMockServices = true
            } else {
                useMockServices = true
                showMockRequiredAlert = true
            }
        }
    }

    private func serviceSection(
        title: String,
        systemImage: String,
        description: String,
        apiKeyTitle: String,
        apiKey: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 42, height: 42)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(description)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                statusPill(L10n.string("ai_services.mock_mode"), color: PannotateTheme.Colors.accent)
                statusPill(apiKey.wrappedValue.isEmpty ? L10n.string("ai_services.not_connected") : L10n.string("ai_services.ready_placeholder"), color: apiKey.wrappedValue.isEmpty ? PannotateTheme.Colors.tertiaryText : PannotateTheme.Colors.success)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(apiKeyTitle)
                    .font(PannotateTheme.Typography.label)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)

                SecureField(L10n.string("ai_services.api_key_placeholder"), text: apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(PannotateTheme.Typography.metadataEmphasis)
                    .padding(12)
                    .background(PannotateTheme.Colors.background.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .pannotateCard()
    }

    private func statusPill(_ title: String, color: Color) -> some View {
        Text(title)
            .font(PannotateTheme.Typography.label)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
