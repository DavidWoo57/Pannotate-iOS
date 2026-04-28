import SwiftUI

struct ProjectWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss

    let project: Project
    @Binding var outputs: [GeneratedClip]
    @Binding var sequenceClips: [SequenceClip]
    let activities: [ProjectActivityItem]
    let studioState: StudioProjectState?
    let continuationContext: StudioContinuationContext?
    var onShowProjects: () -> Void = {}
    var onGeneratedClip: (GeneratedClip) -> Void = { _ in }
    var onStudioStateChanged: (StudioProjectState) -> Void = { _ in }
    var onClearContinuation: () -> Void = {}
    var onContinueClip: (GeneratedClip) -> Void = { _ in }
    var onAddToSequence: (GeneratedClip) -> Bool = { _ in false }
    var onRetryClip: (GeneratedClip) -> Void = { _ in }
    var onRenameProject: (Project, String) -> Void = { _, _ in }
    var onUpdateProject: (Project, String, String) -> Void = { _, _, _ in }
    var onDuplicateProject: (Project) -> Void = { _ in }
    var onDeleteProject: (Project) -> Void = { _ in }

    @State private var selectedSection: ProjectWorkspaceSection = .overview
    @State private var projectToRename: Project?
    @State private var isShowingProjectSettings = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            workspaceTopBar

            workspaceContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PannotateTheme.Colors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            workspaceBottomNavigation
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $projectToRename) { project in
            ManagementRenameSheet(
                title: L10n.string("projects.rename_project"),
                placeholder: L10n.string("projects.project_name"),
                initialName: project.title
            ) { newName in
                onRenameProject(project, newName)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingProjectSettings) {
            ProjectSettingsView(
                project: project,
                cover: projectCover,
                outputCount: outputs.count,
                sequenceClipCount: sequenceClips.count,
                activityCount: activities.count,
                onSave: { name, description in
                    onUpdateProject(project, name, description)
                },
                onDuplicate: {
                    onDuplicateProject(project)
                },
                onDelete: {
                    onDeleteProject(project)
                }
            )
        }
        .alert(L10n.string("projects.delete_project_question"), isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) {
                onDeleteProject(project)
            }

            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("projects.delete_project_message")
        }
    }

    private var workspaceTopBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(PannotateTheme.Colors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("common.go_to_projects"))

            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(1)

                Text("workspace.title")
                    .font(PannotateTheme.Typography.label)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }

            Spacer()

            projectActionsMenu
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(PannotateTheme.Colors.background.opacity(0.97))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var workspaceContent: some View {
        switch selectedSection {
        case .overview:
            overview
        case .studio:
            StudioView(
                currentProject: project,
                isEmbeddedInWorkspace: true,
                continuationContext: continuationContext,
                persistedState: studioState,
                onShowProjects: onShowProjects,
                onClearContinuation: onClearContinuation
            ) { clip in
                onGeneratedClip(clip)
                withAnimation(.easeInOut) {
                    selectedSection = .outputs
                }
            } onStudioStateChanged: { state in
                onStudioStateChanged(state)
            }
        case .outputs:
            OutputsView(
                clips: $outputs,
                currentProject: project,
                isEmbeddedInWorkspace: true,
                onShowProjects: onShowProjects,
                onShowStudio: {
                    withAnimation(.easeInOut) {
                        selectedSection = .studio
                    }
                },
                onContinueClip: { clip in
                    onContinueClip(clip)
                    withAnimation(.easeInOut) {
                        selectedSection = .studio
                    }
                },
                onAddToSequence: onAddToSequence,
                onRetryClip: onRetryClip
            ) {
                withAnimation(.easeInOut) {
                    selectedSection = .sequence
                }
            }
        case .sequence:
            SequenceView(
                clips: $sequenceClips,
                currentProject: project,
                isEmbeddedInWorkspace: true,
                onShowProjects: onShowProjects,
                onShowOutputs: {
                    withAnimation(.easeInOut) {
                        selectedSection = .outputs
                    }
                }
            )
        }
    }

    private var overview: some View {
        ScrollView {
            VStack(spacing: 16) {
                projectSummaryCard
                quickActionsSection
                continueWorkingSection
                recentOutputsSection
                sequencePreviewSection
                recentActivitySection
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .padding(.bottom, 10)
        }
    }

    private var projectSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProjectCoverThumbnail(cover: projectCover, cornerRadius: 24)
                .frame(height: 174)
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.54)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(project.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text("\(L10n.string("project.last_updated")) \(formattedDate(project.updatedAtDate))")
                            .font(PannotateTheme.Typography.metadataEmphasis)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(16)
                }

            Text(project.description.isEmpty ? L10n.string("project.no_description") : project.description)
                .font(PannotateTheme.Typography.body)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)

            HStack(spacing: 10) {
                dashboardMetric(title: L10n.string("project.clips"), value: "\(outputs.count)", systemImage: "film")
                dashboardMetric(title: L10n.string("project.sequence_clips"), value: "\(sequenceClips.count)", systemImage: "square.stack.3d.up")
            }

            Label("\(L10n.string("project.last_updated")) \(formattedDate(project.updatedAtDate))", systemImage: "clock")
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
        }
        .padding(12)
        .pannotateCard()
    }

    private func dashboardMetric(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 28, height: 28)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(title)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(PannotateTheme.Colors.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.quick_actions"))

            PrimaryActionButton(
                title: outputs.isEmpty ? L10n.string("workspace.open_studio") : L10n.string("workspace.continue_in_studio"),
                systemImage: "video"
            ) {
                switchToSection(.studio)
            }

            HStack(spacing: 10) {
                SecondaryActionButton(title: L10n.string("workspace.view_outputs"), systemImage: "film") {
                    switchToSection(.outputs)
                }

                SecondaryActionButton(title: L10n.string("workspace.edit_sequence"), systemImage: "square.stack.3d.up") {
                    switchToSection(.sequence)
                }
            }
        }
    }

    private var continueWorkingSection: some View {
        let nextStep = dashboardNextStep

        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.continue_working"))

            Button {
                switchToSection(nextStep.section)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: nextStep.systemImage)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.accent)
                        .frame(width: 42, height: 42)
                        .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextStep.title)
                            .font(PannotateTheme.Typography.cardTitle)
                            .foregroundStyle(PannotateTheme.Colors.primaryText)

                        Text(nextStep.message)
                            .font(PannotateTheme.Typography.metadata)
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .pannotateCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var recentOutputsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.recent_outputs"))

            if outputs.isEmpty {
                compactEmptyAction(
                    systemImage: "film.badge.plus",
                    title: L10n.string("workspace.no_clips_yet"),
                    message: L10n.string("empty.outputs.message"),
                    buttonTitle: L10n.string("workspace.start_in_studio"),
                    buttonSystemImage: "video"
                ) {
                    switchToSection(.studio)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(outputs.prefix(3)) { clip in
                        outputPreviewRow(clip)
                    }
                }
            }
        }
    }

    private var sequencePreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.sequence_preview"))

            if sequenceClips.isEmpty {
                compactEmptyAction(
                    systemImage: "square.stack.3d.up.slash",
                    title: L10n.string("workspace.no_sequence_clips_yet"),
                    message: L10n.string("empty.sequence.message"),
                    buttonTitle: L10n.string("workspace.add_from_outputs"),
                    buttonSystemImage: "film"
                ) {
                    switchToSection(.outputs)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        dashboardMetric(title: L10n.string("project.sequence_clips"), value: "\(sequenceClips.count)", systemImage: "square.stack.3d.up")
                        dashboardMetric(title: L10n.string("workspace.estimated_duration"), value: estimatedSequenceDuration, systemImage: "timer")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sequenceClips.prefix(6)) { clip in
                                sequenceThumbnail(clip)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    SecondaryActionButton(title: L10n.string("workspace.edit_sequence"), systemImage: "square.stack.3d.up") {
                        switchToSection(.sequence)
                    }
                }
                .padding(14)
                .pannotateCard()
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("activity.recent_activity"))

            if activities.isEmpty {
                compactActivityEmptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(activities.prefix(5)) { activity in
                        activityRow(activity)

                        if activity.id != activities.prefix(5).last?.id {
                            Divider()
                                .overlay(PannotateTheme.Colors.border)
                                .padding(.leading, 58)
                        }
                    }
                }
                .pannotateCard()
            }
        }
    }

    private var compactActivityEmptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 42, height: 42)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                .clipShape(Circle())

            Text("activity.no_recent_activity")
                .font(PannotateTheme.Typography.cardTitle)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)

            Spacer()
        }
        .padding(14)
        .pannotateCard()
    }

    private func activityRow(_ activity: ProjectActivityItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activity.type.systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 36, height: 36)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.56))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(activity.detail)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .lineLimit(2)

                Text(formattedActivityDate(activity.date))
                    .font(PannotateTheme.Typography.label)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }

            Spacer()
        }
        .padding(14)
    }

    private func outputPreviewRow(_ clip: GeneratedClip) -> some View {
        Button {
            switchToSection(.outputs)
        } label: {
            HStack(spacing: 12) {
                FixedClipThumbnail(style: clip.thumbnail, image: clip.image, cornerRadius: 14)

                VStack(alignment: .leading, spacing: 4) {
                    Text(clip.title)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)
                        .lineLimit(1)

                    Text("\(clip.status.label) · \(clip.duration)")
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }
            .padding(12)
            .pannotateCard()
        }
        .buttonStyle(.plain)
    }

    private func sequenceThumbnail(_ clip: SequenceClip) -> some View {
        VStack(spacing: 6) {
            Text("\(clip.order)")
                .font(PannotateTheme.Typography.metadataEmphasis)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            ProjectCoverThumbnail(
                cover: ProjectCoverSource(thumbnail: clip.thumbnail, image: clip.image),
                size: CGSize(width: 72, height: 50),
                cornerRadius: 12
            )
        }
        .frame(width: 76)
    }

    private func compactEmptyAction(
        systemImage: String,
        title: String,
        message: String,
        buttonTitle: String,
        buttonSystemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 42, height: 42)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(message)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SecondaryActionButton(title: buttonTitle, systemImage: buttonSystemImage, action: action)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .pannotateCard()
    }

    private var projectActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: L10n.string("workspace.project_actions"))

            HStack(spacing: 10) {
                SecondaryActionButton(title: L10n.string("common.rename"), systemImage: "pencil") {
                    projectToRename = project
                }

                SecondaryActionButton(title: L10n.string("project.settings"), systemImage: "slider.horizontal.3") {
                    isShowingProjectSettings = true
                }
            }

            HStack(spacing: 10) {
                SecondaryActionButton(title: L10n.string("projects.duplicate_project"), systemImage: "plus.square.on.square") {
                    onDuplicateProject(project)
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("common.delete", systemImage: "trash")
                        .font(PannotateTheme.Typography.control)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: PannotateTheme.Metrics.buttonHeight)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var projectActionsMenu: some View {
        Menu {
            Button {
                isShowingProjectSettings = true
            } label: {
                Label("project.settings", systemImage: "slider.horizontal.3")
            }

            Button {
                projectToRename = project
            } label: {
                Label("projects.rename_project", systemImage: "pencil")
            }

            Button {
                onDuplicateProject(project)
            } label: {
                Label("projects.duplicate_project", systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("projects.delete_project", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
    }

    private var projectCover: ProjectCoverSource {
        let latestCompletedOutput = outputs.first { $0.status.isCompleted }
        return ProjectCoverSource(
            thumbnail: latestCompletedOutput?.thumbnail ?? project.thumbnail,
            image: latestCompletedOutput?.image
        )
    }

    private var dashboardNextStep: DashboardNextStep {
        if outputs.isEmpty {
            return DashboardNextStep(
                title: L10n.string("workspace.start_creating"),
                message: L10n.string("empty.studio.no_image.message"),
                systemImage: "video.badge.plus",
                section: .studio
            )
        }

        if sequenceClips.isEmpty {
            return DashboardNextStep(
                title: L10n.string("workspace.add_clips_to_sequence"),
                message: L10n.string("empty.sequence.message"),
                systemImage: "square.stack.3d.up.badge.plus",
                section: .outputs
            )
        }

        return DashboardNextStep(
            title: L10n.string("workspace.preview_sequence"),
            message: L10n.string("workspace.sequence_ready_message"),
            systemImage: "play.rectangle",
            section: .sequence
        )
    }

    private var estimatedSequenceDuration: String {
        let totalSeconds = sequenceClips.compactMap { seconds(from: $0.duration) }.reduce(0, +)
        guard totalSeconds > 0 else { return "—" }
        return "\(totalSeconds)s"
    }

    private func seconds(from duration: String) -> Int? {
        let numberText = duration
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "s", with: "")
            .replacingOccurrences(of: "S", with: "")
        return Int(numberText)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }

    private func formattedActivityDate(_ date: Date) -> String {
        date.formatted(.dateTime.month().day().hour().minute())
    }

    private func switchToSection(_ section: ProjectWorkspaceSection) {
        withAnimation(.easeInOut) {
            selectedSection = section
        }
    }

    private var workspaceBottomNavigation: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.primary.opacity(0.14))
                    .frame(height: 0.5)

                HStack(spacing: 4) {
                    ForEach(ProjectWorkspaceSection.allCases) { section in
                        workspaceNavigationButton(section)
                    }
                }
                .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 9)
            }
            .background(PannotateTheme.Colors.background)
        }
        .background(PannotateTheme.Colors.background.ignoresSafeArea(edges: .bottom))
    }

    private func workspaceNavigationButton(_ section: ProjectWorkspaceSection) -> some View {
        let isSelected = selectedSection == section

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                selectedSection = section
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: section.systemImage)
                    .font(.caption2.weight(.semibold))

                Text(section.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(isSelected ? PannotateTheme.Colors.accent : PannotateTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isSelected ? PannotateTheme.Colors.accentSoft.opacity(0.62) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private enum ProjectWorkspaceSection: String, CaseIterable, Identifiable {
    case overview
    case studio
    case outputs
    case sequence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            L10n.string("workspace.overview")
        case .studio:
            L10n.string("tab.studio")
        case .outputs:
            L10n.string("tab.outputs")
        case .sequence:
            L10n.string("tab.sequence")
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            "rectangle.grid.1x2"
        case .studio:
            "video"
        case .outputs:
            "film"
        case .sequence:
            "square.stack.3d.up"
        }
    }
}

private struct DashboardNextStep {
    let title: String
    let message: String
    let systemImage: String
    let section: ProjectWorkspaceSection
}

#Preview {
    NavigationStack {
        ProjectWorkspaceView(
            project: MockPannotateData.projects[0],
            outputs: .constant(MockPannotateData.generatedClips),
            sequenceClips: .constant(MockPannotateData.sequenceClips),
            activities: [],
            studioState: nil,
            continuationContext: nil
        )
    }
}
