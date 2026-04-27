import SwiftUI
import UIKit

struct DeveloperToolsStateSummary {
    let currentProjectName: String
    let projectCount: Int
    let currentProjectOutputCount: Int
    let currentProjectSequenceCount: Int

    static let preview = DeveloperToolsStateSummary(
        currentProjectName: "Urban Sunset",
        projectCount: 3,
        currentProjectOutputCount: 3,
        currentProjectSequenceCount: 4
    )
}

struct DeveloperToolsActions {
    let stateSummary: () -> DeveloperToolsStateSummary
    let clearAllLocalData: () -> Void
    let addSampleProject: () -> Void
    let addSampleOutputs: () -> Void
    let addFailedMockJob: () -> Void

    static let preview = DeveloperToolsActions(
        stateSummary: { .preview },
        clearAllLocalData: {},
        addSampleProject: {},
        addSampleOutputs: {},
        addFailedMockJob: {}
    )
}

struct SettingsView: View {
    @AppStorage("appTheme") private var selectedThemeRawValue = AppTheme.dark.rawValue
    @AppStorage("hasCompletedAuthWelcome") private var hasCompletedAuthWelcome = false
    @AppStorage("authMode") private var authModeRawValue = AuthMode.guest.rawValue
    let developerToolsActions: DeveloperToolsActions
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

    init(developerToolsActions: DeveloperToolsActions = .preview) {
        self.developerToolsActions = developerToolsActions
    }

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

                        NavigationLink {
                            DeveloperToolsView(actions: developerToolsActions)
                        } label: {
                            settingsLinkContent(
                                title: L10n.string("developer_tools.title"),
                                detail: L10n.string("developer_tools.subtitle"),
                                systemImage: "hammer"
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

private struct DeveloperToolsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedAuthWelcome") private var hasCompletedAuthWelcome = false
    @AppStorage("authMode") private var authModeRawValue = AuthMode.guest.rawValue
    @AppStorage("appTheme") private var selectedThemeRawValue = AppTheme.dark.rawValue

    let actions: DeveloperToolsActions

    @State private var pendingConfirmation: DeveloperToolConfirmation?
    @State private var statusMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                appFlowSection
                localDataSection
                appStateSection

                Text("developer_tools.safety_note")
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .padding(.bottom, 48)
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(L10n.string("developer_tools.title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.string("developer_tools.are_you_sure"), isPresented: confirmationBinding) {
            Button(L10n.string("common.cancel"), role: .cancel) {
                pendingConfirmation = nil
            }

            Button(pendingConfirmation?.actionTitle ?? L10n.string("common.confirm"), role: .destructive) {
                executePendingConfirmation()
            }
        } message: {
            Text(pendingConfirmation?.message ?? L10n.string("developer_tools.cannot_undo"))
        }
    }

    private var appFlowSection: some View {
        debugSection(title: L10n.string("developer_tools.section.app_flow")) {
            VStack(spacing: 0) {
                debugActionRow(
                    title: L10n.string("developer_tools.reset_onboarding"),
                    subtitle: L10n.string("developer_tools.reset_onboarding_subtitle"),
                    systemImage: "rectangle.stack.badge.play"
                ) {
                    pendingConfirmation = .resetOnboarding
                }

                Divider().overlay(PannotateTheme.Colors.border)

                debugActionRow(
                    title: L10n.string("developer_tools.reset_auth_welcome"),
                    subtitle: L10n.string("developer_tools.reset_auth_welcome_subtitle"),
                    systemImage: "person.crop.circle.badge.questionmark"
                ) {
                    pendingConfirmation = .resetAuthWelcome
                }
            }
            .pannotateCard()
        }
    }

    private var localDataSection: some View {
        debugSection(title: L10n.string("developer_tools.section.local_data")) {
            VStack(spacing: 0) {
                debugActionRow(
                    title: L10n.string("developer_tools.add_sample_project"),
                    subtitle: L10n.string("developer_tools.add_sample_project_subtitle"),
                    systemImage: "folder.badge.plus"
                ) {
                    actions.addSampleProject()
                    showStatus(L10n.string("developer_tools.sample_project_added"))
                }

                Divider().overlay(PannotateTheme.Colors.border)

                debugActionRow(
                    title: L10n.string("developer_tools.add_sample_outputs"),
                    subtitle: L10n.string("developer_tools.add_sample_outputs_subtitle"),
                    systemImage: "film.badge.plus"
                ) {
                    actions.addSampleOutputs()
                    showStatus(L10n.string("developer_tools.sample_outputs_added"))
                }

                Divider().overlay(PannotateTheme.Colors.border)

                debugActionRow(
                    title: L10n.string("developer_tools.add_failed_mock_job"),
                    subtitle: L10n.string("developer_tools.add_failed_mock_job_subtitle"),
                    systemImage: "exclamationmark.triangle"
                ) {
                    actions.addFailedMockJob()
                    showStatus(L10n.string("developer_tools.failed_job_added"))
                }

                Divider().overlay(PannotateTheme.Colors.border)

                debugActionRow(
                    title: L10n.string("developer_tools.clear_all_local_data"),
                    subtitle: L10n.string("developer_tools.clear_all_local_data_subtitle"),
                    systemImage: "trash",
                    isDestructive: true
                ) {
                    pendingConfirmation = .clearAllLocalData
                }
            }
            .pannotateCard()
        }
    }

    private var appStateSection: some View {
        debugSection(title: L10n.string("developer_tools.app_state_summary")) {
            VStack(alignment: .leading, spacing: 14) {
                if let statusMessage {
                    Label(statusMessage, systemImage: "checkmark.circle.fill")
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(PannotateTheme.Colors.success)
                }

                VStack(spacing: 10) {
                    ForEach(summaryRows, id: \.label) { row in
                        HStack(alignment: .top, spacing: 12) {
                            Text(row.label)
                                .font(PannotateTheme.Typography.label)
                                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                                .frame(width: 142, alignment: .leading)

                            Text(row.value)
                                .font(PannotateTheme.Typography.metadataEmphasis)
                                .foregroundStyle(PannotateTheme.Colors.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                PrimaryActionButton(title: L10n.string("developer_tools.copy_summary"), systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = stateSummaryText
                    showStatus(L10n.string("developer_tools.summary_copied"))
                }
            }
            .padding(16)
            .pannotateCard()
        }
    }

    private var summaryRows: [(label: String, value: String)] {
        let summary = actions.stateSummary()
        return [
            (L10n.string("developer_tools.current_project"), summary.currentProjectName),
            (L10n.string("developer_tools.project_count"), "\(summary.projectCount)"),
            (L10n.string("developer_tools.output_count"), "\(summary.currentProjectOutputCount)"),
            (L10n.string("developer_tools.sequence_count"), "\(summary.currentProjectSequenceCount)"),
            (L10n.string("developer_tools.onboarding_completed"), yesNo(hasCompletedOnboarding)),
            (L10n.string("developer_tools.auth_welcome_completed"), yesNo(hasCompletedAuthWelcome)),
            (L10n.string("developer_tools.auth_mode"), authModeTitle),
            (L10n.string("developer_tools.selected_theme"), selectedThemeTitle),
            (L10n.string("developer_tools.language"), L10n.string("developer_tools.language_follows_ios"))
        ]
    }

    private var stateSummaryText: String {
        summaryRows
            .map { "\($0.label): \($0.value)" }
            .joined(separator: "\n")
    }

    private var confirmationBinding: Binding<Bool> {
        Binding {
            pendingConfirmation != nil
        } set: { isPresented in
            if isPresented == false {
                pendingConfirmation = nil
            }
        }
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

    private var selectedThemeTitle: String {
        (AppTheme(rawValue: selectedThemeRawValue) ?? .system).title
    }

    private func debugSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            SectionLabel(title: title)
            content()
        }
    }

    private func debugActionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isDestructive ? .red : PannotateTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background((isDestructive ? Color.red : PannotateTheme.Colors.accent).opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(isDestructive ? .red : PannotateTheme.Colors.primaryText)

                    Text(subtitle)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func executePendingConfirmation() {
        guard let pendingConfirmation else { return }

        switch pendingConfirmation {
        case .resetOnboarding:
            hasCompletedOnboarding = false
            showStatus(L10n.string("developer_tools.onboarding_reset"))
        case .resetAuthWelcome:
            authModeRawValue = AuthMode.guest.rawValue
            hasCompletedAuthWelcome = false
            showStatus(L10n.string("developer_tools.auth_welcome_reset"))
        case .clearAllLocalData:
            actions.clearAllLocalData()
            showStatus(L10n.string("developer_tools.local_data_cleared"))
        }

        self.pendingConfirmation = nil
    }

    private func showStatus(_ message: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            statusMessage = message
        }
    }

    private func yesNo(_ value: Bool) -> String {
        value ? L10n.string("common.yes") : L10n.string("common.no")
    }
}

private enum DeveloperToolConfirmation: Identifiable {
    case resetOnboarding
    case resetAuthWelcome
    case clearAllLocalData

    var id: String {
        switch self {
        case .resetOnboarding:
            "resetOnboarding"
        case .resetAuthWelcome:
            "resetAuthWelcome"
        case .clearAllLocalData:
            "clearAllLocalData"
        }
    }

    var actionTitle: String {
        switch self {
        case .resetOnboarding:
            L10n.string("developer_tools.reset_onboarding")
        case .resetAuthWelcome:
            L10n.string("developer_tools.reset_auth_welcome")
        case .clearAllLocalData:
            L10n.string("developer_tools.clear_all_local_data")
        }
    }

    var message: String {
        switch self {
        case .resetOnboarding:
            L10n.string("developer_tools.reset_onboarding_confirmation")
        case .resetAuthWelcome:
            L10n.string("developer_tools.reset_auth_welcome_confirmation")
        case .clearAllLocalData:
            L10n.string("developer_tools.clear_all_local_data_confirmation")
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
