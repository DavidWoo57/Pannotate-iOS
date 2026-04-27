import SwiftUI

struct ProfileStats {
    let projectCount: Int
    let clipCount: Int
    let exportCount: Int

    static let preview = ProfileStats(
        projectCount: MockPannotateData.profile.projectCount,
        clipCount: MockPannotateData.profile.clipCount,
        exportCount: 0
    )
}

struct ProfileActivityItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let thumbnail: ThumbnailStyle
    let image: UIImage?
}

struct ProfileView: View {
    @AppStorage("authMode") private var authModeRawValue = AuthMode.guest.rawValue

    var developerToolsActions: DeveloperToolsActions = .preview
    var stats: ProfileStats = .preview
    var recentActivity: [ProfileActivityItem] = []

    private let profile = MockPannotateData.profile

    var body: some View {
        FixedHeaderPage(bottomPadding: PannotateTheme.Metrics.tabBarContentInset + 12) {
            HStack {
                BrandHeader()

                NavigationLink {
                    SettingsView(developerToolsActions: developerToolsActions)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                        .frame(width: 46, height: 46)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(PannotateTheme.Colors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        } content: {
            userCard

            statsGrid

            VStack(spacing: 14) {
                SectionLabel(title: L10n.string("profile.recent_activity"))

                recentActivityContent
            }

            settingsRow

            prototypeRows
        }
    }

    private var userCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(PannotateTheme.brandGradient)
                    .frame(width: 82, height: 82)
                    .overlay {
                        Text("G")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(profileDisplayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(profileHandle)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)

                    Text(profilePlan)
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(PannotateTheme.Colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(PannotateTheme.Colors.accent.opacity(0.4), lineWidth: 1))
                }

                Spacer()
            }

            Divider()
                .overlay(PannotateTheme.Colors.border)

            VStack(spacing: 10) {
                HStack {
                    Text("profile.prototype_credits")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)

                    Spacer()

                    Text("\(profile.monthlyCreditsUsed) / \(profile.monthlyCreditsTotal)")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.accent)
                }

                ProgressView(value: Double(profile.monthlyCreditsUsed), total: Double(profile.monthlyCreditsTotal))
                    .tint(PannotateTheme.Colors.accent)
                    .background(PannotateTheme.Colors.tertiaryText.opacity(0.35))
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .pannotateCard()
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(title: L10n.string("tab.projects"), value: stats.projectCount, systemImage: "folder")
            statCard(title: L10n.string("profile.clips"), value: stats.clipCount, systemImage: "film")
            statCard(title: L10n.string("profile.exports"), value: stats.exportCount, systemImage: "square.stack.3d.up")
        }
    }

    private func statCard(title: String, value: Int, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)

            Text("\(value)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text(title)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .pannotateCard()
    }

    @ViewBuilder
    private var recentActivityContent: some View {
        if recentActivity.isEmpty {
            HStack(spacing: 12) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 42, height: 42)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                    .clipShape(Circle())

                Text("profile.no_recent_activity")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)

                Spacer()
            }
            .padding(16)
            .pannotateCard()
        } else {
            VStack(spacing: 0) {
                ForEach(recentActivity) { item in
                    activityRow(item)
                }
            }
            .pannotateCard()
        }
    }

    private func activityRow(_ item: ProfileActivityItem) -> some View {
        HStack(spacing: 12) {
            activityThumbnail(item)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(item.subtitle)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
        }
        .padding(16)
    }

    private func activityThumbnail(_ item: ProfileActivityItem) -> some View {
        Group {
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                MockThumbnail(style: item.thumbnail, cornerRadius: 12)
            }
        }
        .frame(width: 62, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var profileDisplayName: String {
        switch AuthMode(rawValue: authModeRawValue) ?? .guest {
        case .guest, .appleMock, .googleMock, .emailMock:
            L10n.string("profile.guest_user")
        }
    }

    private var profileHandle: String {
        "@guest"
    }

    private var profilePlan: String {
        L10n.string("profile.local_prototype")
    }

    private var settingsRow: some View {
        NavigationLink {
            SettingsView(developerToolsActions: developerToolsActions)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "gearshape")
                    .font(.headline)
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                    .clipShape(Circle())

                Text("settings.title")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }
            .padding(16)
            .pannotateCard()
        }
        .buttonStyle(.plain)
    }

    private var prototypeRows: some View {
        VStack(spacing: 14) {
            SectionLabel(title: L10n.string("profile.account_support"))

            VStack(spacing: 0) {
                profileLink(title: L10n.string("settings.subscription"), subtitle: L10n.string("profile.subscription_subtitle"), systemImage: "creditcard")
                profileLink(title: L10n.string("profile.help"), subtitle: L10n.string("profile.help_subtitle"), systemImage: "questionmark.circle")
                profileLink(title: L10n.string("profile.privacy"), subtitle: L10n.string("profile.privacy_subtitle"), systemImage: "lock.shield")
                profileLink(title: L10n.string("profile.rate_pannotate"), subtitle: L10n.string("profile.rate_pannotate_subtitle"), systemImage: "star")
            }
            .pannotateCard()
        }
    }

    private func profileLink(title: String, subtitle: String, systemImage: String) -> some View {
        NavigationLink {
            ProfilePlaceholderDetailView(title: title, subtitle: subtitle, systemImage: systemImage)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.5))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(subtitle)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfilePlaceholderDetailView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 104, height: 104)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                .clipShape(Circle())

            Text(title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text(subtitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)

            Text("profile.placeholder_detail_note")
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()
        }
        .padding(PannotateTheme.Metrics.pagePadding)
        .frame(maxWidth: .infinity)
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
