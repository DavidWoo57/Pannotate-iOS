import SwiftUI

enum PannotateTab {
    case projects
    case profile
}

struct RootTabView: View {
    @State private var selectedTab: PannotateTab = .projects
    @State private var projectNavigationPath: [UUID] = []
    @State private var projects: [Project]
    @State private var currentProjectID: UUID?
    @State private var outputsByProject: [UUID: [GeneratedClip]]
    @State private var sequenceClipsByProject: [UUID: [SequenceClip]]
    @State private var studioStateByProject: [UUID: StudioProjectState]
    @State private var studioContinuationContext: StudioContinuationContext?
    @State private var activityByProject: [UUID: [ProjectActivityItem]]
    private let videoGenerationService: VideoGenerationService = MockVideoGenerationService()

    init() {
        if let savedState = AppStateStore.load() {
            let validProjectIDs = Set(savedState.projects.map(\.id))
            let savedCurrentProjectID = savedState.currentProjectID.flatMap { validProjectIDs.contains($0) ? $0 : savedState.projects.first?.id } ?? savedState.projects.first?.id

            _projects = State(initialValue: savedState.projects)
            _currentProjectID = State(initialValue: savedCurrentProjectID)
            _outputsByProject = State(initialValue: savedState.outputsByProject.filter { validProjectIDs.contains($0.key) })
            _sequenceClipsByProject = State(initialValue: savedState.sequenceClipsByProject.filter { validProjectIDs.contains($0.key) })
            _studioStateByProject = State(initialValue: savedState.studioStateByProject.filter { validProjectIDs.contains($0.key) })
            _studioContinuationContext = State(initialValue: savedState.studioContinuationContext)
            _activityByProject = State(initialValue: savedState.activityByProject.filter { validProjectIDs.contains($0.key) })
        } else {
            let projects = MockPannotateData.projects
            let initialProjectID = projects.first?.id

            _projects = State(initialValue: projects)
            _currentProjectID = State(initialValue: initialProjectID)
            _outputsByProject = State(initialValue: initialProjectID.map { [$0: MockPannotateData.generatedClips] } ?? [:])
            _sequenceClipsByProject = State(initialValue: initialProjectID.map { [$0: MockPannotateData.sequenceClips] } ?? [:])
            _studioStateByProject = State(initialValue: [:])
            _studioContinuationContext = State(initialValue: nil)
            _activityByProject = State(initialValue: [:])
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $projectNavigationPath) {
                ProjectsView(
                    projects: projectsBinding,
                    currentProjectID: currentProjectIDBinding,
                    projectCover: projectCover,
                    projectOutputCount: { project in outputsByProject[project.id, default: []].count },
                    onProjectCreated: createProjectState,
                    onProjectRenamed: recordProjectListRename,
                    onProjectDuplicated: recordProjectListDuplicate,
                    onProjectDeleted: handleProjectDeleted,
                    onOpenProject: openProjectWorkspace
                )
                .navigationDestination(for: UUID.self) { projectID in
                    if let project = project(for: projectID) {
                        ProjectWorkspaceView(
                            project: project,
                            outputs: outputsBinding(for: projectID),
                            sequenceClips: sequenceBinding(for: projectID),
                            activities: activityByProject[projectID, default: []],
                            studioState: studioStateByProject[projectID],
                            continuationContext: studioContinuationContext,
                            onShowProjects: closeProjectWorkspace,
                            onGeneratedClip: { clip in
                                upsertOutputClip(clip, projectID: projectID)
                            },
                            onStudioStateChanged: { state in
                                studioStateByProject[projectID] = state
                                saveState()
                            },
                            onClearContinuation: clearContinuation,
                            onContinueClip: beginContinuation,
                            onAddToSequence: { clip in
                                addToSequence(clip, projectID: projectID)
                            },
                            onRetryClip: { clip in
                                retryGeneration(clip, projectID: projectID)
                            },
                            onRenameProject: renameProject,
                            onUpdateProject: updateProject,
                            onDuplicateProject: duplicateProject,
                            onDeleteProject: deleteProjectFromWorkspace
                        )
                    } else {
                        ProjectRequiredEmptyState(
                            title: L10n.string("workspace.open_project_first"),
                            message: L10n.string("studio.no_project_message"),
                            buttonTitle: L10n.string("common.go_to_projects"),
                            action: closeProjectWorkspace
                        )
                    }
                }
            }
            .tabItem {
                Label("tab.projects", systemImage: "house")
            }
            .tag(PannotateTab.projects)

            NavigationStack {
                ProfileView(
                    developerToolsActions: developerToolsActions,
                    stats: profileStats,
                    recentActivity: profileRecentActivity
                )
            }
            .tabItem {
                Label("tab.profile", systemImage: "person")
            }
            .tag(PannotateTab.profile)
        }
        .tint(PannotateTheme.Colors.accent)
    }

    private var currentProject: Project? {
        guard let currentProjectID else { return nil }
        return project(for: currentProjectID)
    }

    private var developerToolsActions: DeveloperToolsActions {
        DeveloperToolsActions(
            stateSummary: makeDeveloperStateSummary,
            clearAllLocalData: clearAllLocalData,
            addSampleProject: { _ = ensureDebugProject() },
            addSampleOutputs: addSampleOutputs,
            addFailedMockJob: addFailedMockJob
        )
    }

    private var profileStats: ProfileStats {
        ProfileStats(
            projectCount: projects.count,
            clipCount: outputsByProject.values.reduce(0) { $0 + $1.count },
            exportCount: 0
        )
    }

    private var profileRecentActivity: [ProfileActivityItem] {
        activityByProject.values
            .flatMap { $0 }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { activity in
                let project = project(for: activity.projectID)
                let cover = project.map(projectCover) ?? ProjectCoverSource(thumbnail: .lights, image: nil)
                return ProfileActivityItem(
                    id: activity.id,
                    title: activity.type.title,
                    subtitle: activitySubtitle(for: activity, project: project),
                    thumbnail: cover.thumbnail,
                    image: cover.image
                )
            }
    }

    private var projectsBinding: Binding<[Project]> {
        Binding {
            projects
        } set: { newValue in
            projects = newValue
            saveState()
        }
    }

    private var currentProjectIDBinding: Binding<UUID?> {
        Binding {
            currentProjectID
        } set: { newValue in
            currentProjectID = newValue
            saveState()
        }
    }

    private func project(for id: UUID) -> Project? {
        projects.first { $0.id == id }
    }

    private func projectCover(for project: Project) -> ProjectCoverSource {
        let latestCompletedOutput = outputsByProject[project.id, default: []].first { $0.status.isCompleted }
        return ProjectCoverSource(
            thumbnail: latestCompletedOutput?.thumbnail ?? project.thumbnail,
            image: latestCompletedOutput?.image
        )
    }

    private func outputsBinding(for projectID: UUID) -> Binding<[GeneratedClip]> {
        Binding {
            outputsByProject[projectID, default: []]
        } set: { newValue in
            let oldOutputs = outputsByProject[projectID, default: []]
            recordOutputDeletionActivity(oldOutputs: oldOutputs, newOutputs: newValue, projectID: projectID)
            removeSequenceClipsForDeletedOutputs(oldOutputs: oldOutputs, newOutputs: newValue, projectID: projectID)
            outputsByProject[projectID] = newValue
            touchProject(projectID)
            saveState()
        }
    }

    private func sequenceBinding(for projectID: UUID) -> Binding<[SequenceClip]> {
        Binding {
            sequenceClipsByProject[projectID, default: []]
        } set: { newValue in
            recordSequenceMutationActivity(oldClips: sequenceClipsByProject[projectID, default: []], newClips: newValue, projectID: projectID)
            sequenceClipsByProject[projectID] = newValue
            touchProject(projectID)
            saveState()
        }
    }

    private func openProjectWorkspace(_ project: Project) {
        currentProjectID = project.id
        prepareProjectState(project)
        withAnimation(.easeInOut) {
            selectedTab = .projects
            projectNavigationPath = [project.id]
        }
    }

    private func closeProjectWorkspace() {
        withAnimation(.easeInOut) {
            selectedTab = .projects
            projectNavigationPath = []
        }
    }

    private func beginContinuation(_ clip: GeneratedClip) {
        studioContinuationContext = StudioContinuationContext(
            id: clip.id,
            title: clip.title,
            thumbnail: clip.thumbnail,
            image: clip.image
        )
        saveState()
    }

    private func clearContinuation() {
        withAnimation(.easeInOut) {
            studioContinuationContext = nil
        }
        saveState()
    }

    private func activitySubtitle(for activity: ProjectActivityItem, project: Project?) -> String {
        let projectName = project?.title ?? L10n.string("common.no_project")
        return "\(projectName) · \(activity.detail) · \(formattedActivityDate(activity.date))"
    }

    private func prepareProjectState(_ project: Project) {
        if outputsByProject[project.id] == nil {
            outputsByProject[project.id] = []
        }

        if sequenceClipsByProject[project.id] == nil {
            sequenceClipsByProject[project.id] = []
        }

        if studioStateByProject[project.id] == nil {
            studioStateByProject[project.id] = StudioProjectState()
        }

        saveState()
    }

    private func createProjectState(_ project: Project) {
        prepareProjectState(project)
        recordActivity(.projectCreated, projectID: project.id, detail: project.title)
        saveState()
    }

    private func recordProjectListRename(_ project: Project, newName: String) {
        recordActivity(.projectRenamed, projectID: project.id, detail: newName)
        saveState()
    }

    private func recordProjectListDuplicate(_ sourceProject: Project, copy: Project) {
        prepareProjectState(copy)
        recordActivity(.projectDuplicated, projectID: copy.id, detail: sourceProject.title)
        saveState()
    }

    private func handleProjectDeleted(_ project: Project) {
        outputsByProject[project.id] = nil
        sequenceClipsByProject[project.id] = nil
        studioStateByProject[project.id] = nil
        activityByProject[project.id] = nil
        studioContinuationContext = nil
        projectNavigationPath.removeAll { $0 == project.id }

        if currentProjectID == project.id {
            currentProjectID = projects.first?.id
        }

        saveState()
    }

    private func renameProject(_ project: Project, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false,
              let index = projects.firstIndex(where: { $0.id == project.id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects[index] = Project(
                id: project.id,
                title: trimmedName,
                clipCount: project.clipCount,
                updatedAt: L10n.string("common.just_now"),
                thumbnail: project.thumbnail,
                description: project.description,
                createdAt: project.createdAt,
                updatedAtDate: Date()
            )
        }
        recordActivity(.projectRenamed, projectID: project.id, detail: trimmedName)
        saveState()
    }

    private func updateProject(_ project: Project, name: String, description: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false,
              let index = projects.firstIndex(where: { $0.id == project.id }) else { return }

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let didChangeDescription = trimmedDescription != project.description
        let didChangeName = trimmedName != project.title
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects[index] = Project(
                id: project.id,
                title: trimmedName,
                clipCount: project.clipCount,
                updatedAt: L10n.string("common.just_now"),
                thumbnail: project.thumbnail,
                description: trimmedDescription,
                createdAt: project.createdAt,
                updatedAtDate: Date()
            )
        }
        if didChangeName {
            recordActivity(.projectRenamed, projectID: project.id, detail: trimmedName)
        }
        if didChangeDescription {
            recordActivity(.descriptionUpdated, projectID: project.id, detail: trimmedName)
        }
        saveState()
    }

    private func duplicateProject(_ project: Project) {
        let copy = Project(
            title: String.localizedStringWithFormat(L10n.string("projects.copy_format"), project.title),
            clipCount: project.clipCount,
            updatedAt: L10n.string("common.just_now"),
            thumbnail: project.thumbnail,
            description: project.description
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects.insert(copy, at: 0)
        }
        prepareProjectState(copy)
        recordActivity(.projectDuplicated, projectID: copy.id, detail: project.title)
        saveState()
    }

    private func deleteProjectFromWorkspace(_ project: Project) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects.removeAll { $0.id == project.id }
            projectNavigationPath = []
        }
        handleProjectDeleted(project)
    }

    @discardableResult
    private func ensureDebugProject() -> UUID {
        if let currentProjectID, projects.contains(where: { $0.id == currentProjectID }) {
            return currentProjectID
        }

        let project = Project(
            title: L10n.string("developer_tools.sample_project_title"),
            clipCount: 0,
            updatedAt: L10n.string("developer_tools.just_now"),
            thumbnail: .city
        )
        projects.insert(project, at: 0)
        currentProjectID = project.id
        outputsByProject[project.id] = outputsByProject[project.id, default: []]
        sequenceClipsByProject[project.id] = sequenceClipsByProject[project.id, default: []]
        studioStateByProject[project.id] = studioStateByProject[project.id] ?? StudioProjectState()
        recordActivity(.projectCreated, projectID: project.id, detail: project.title)
        saveState()
        return project.id
    }

    private func clearAllLocalData() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            projects = []
            currentProjectID = nil
            outputsByProject = [:]
            sequenceClipsByProject = [:]
            studioStateByProject = [:]
            studioContinuationContext = nil
            activityByProject = [:]
        }
        saveState()
    }

    private func addSampleOutputs() {
        let projectID = ensureDebugProject()
        let completedRequestID = UUID()
        let completedDate = Date()
        let completedParameterSummary = """
        \(L10n.string("generation.duration")): 4s
        \(L10n.string("generation.aspect_ratio")): auto
        \(L10n.string("generation.quality")): \(GenerationQualityOption.standard.title)
        \(L10n.string("generation.seed")): \(L10n.string("generation.automatic"))
        """
        let samples = [
            GeneratedClip(
                title: L10n.string("developer_tools.sample_completed_clip_title"),
                duration: "4s",
                createdAt: L10n.string("developer_tools.just_now"),
                status: .done,
                thumbnail: .city,
                generationRequestID: completedRequestID,
                generationRequestSummary: L10n.string("developer_tools.sample_request_summary"),
                interpretationMode: .fast,
                finalVideoPrompt: L10n.string("developer_tools.sample_final_prompt"),
                annotationCount: 1,
                generationMode: .newShot,
                generationProviderID: GenerationProviderID.mock.rawValue,
                generationProviderName: GenerationProviderConfiguration.mock.displayName,
                providerJobID: "mock-sample-\(completedRequestID.uuidString.prefix(8))",
                providerModelID: GenerationProviderConfiguration.mock.modelID,
                generationParameters: .defaults,
                outputResult: GeneratedOutputResult(
                    providerID: GenerationProviderID.mock.rawValue,
                    providerName: GenerationProviderConfiguration.mock.displayName,
                    providerJobID: "mock-sample-\(completedRequestID.uuidString.prefix(8))",
                    modelID: GenerationProviderConfiguration.mock.modelID,
                    createdAt: completedDate,
                    completedAt: completedDate,
                    duration: "4s",
                    generationParameterSummary: completedParameterSummary,
                    payloadSummary: nil,
                    failureReason: nil,
                    rawProviderMetadata: ["mode": "mock", "playback": "unavailable"],
                    media: OutputMediaMetadata(
                        remoteVideoURL: nil,
                        localVideoFileURL: nil,
                        thumbnailReference: String(describing: ThumbnailStyle.city),
                        hasThumbnailImage: true,
                        duration: "4s",
                        resolution: "1280x720",
                        fileSize: nil,
                        isPlaybackAvailable: false,
                        isExportAvailable: false,
                        isMockResult: true
                    )
                )
            ),
            GeneratedClip(
                title: L10n.string("developer_tools.sample_processing_clip_title"),
                duration: "4s",
                createdAt: "Processing",
                status: .processing(45),
                thumbnail: .forest,
                generationRequestID: UUID(),
                generationRequestSummary: L10n.string("developer_tools.sample_request_summary"),
                interpretationMode: .smart,
                finalVideoPrompt: L10n.string("developer_tools.sample_final_prompt"),
                annotationCount: 2,
                generationMode: .newShot
            )
        ]

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            outputsByProject[projectID, default: []].insert(contentsOf: samples, at: 0)
        }
        samples.forEach { clip in
            if clip.status.isCompleted {
                recordActivity(.outputGenerated, projectID: projectID, detail: clip.title, relatedClipID: clip.id)
            }
        }
        touchProject(projectID)
        saveState()
    }

    private func addFailedMockJob() {
        let projectID = ensureDebugProject()
        let failedClip = GeneratedClip(
            title: L10n.string("developer_tools.sample_failed_clip_title"),
            duration: "4s",
            createdAt: L10n.string("generation.failed"),
            status: .failed,
            thumbnail: .lights,
            generationRequestID: UUID(),
            generationRequestSummary: L10n.string("developer_tools.sample_failed_request_summary"),
            interpretationMode: .fast,
            finalVideoPrompt: "mock fail: \(L10n.string("developer_tools.sample_final_prompt"))",
            annotationCount: 1,
            generationMode: .newShot,
            failureReason: L10n.string("generation.mock_generation_failed")
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            outputsByProject[projectID, default: []].insert(failedClip, at: 0)
        }
        recordActivity(.generationFailed, projectID: projectID, detail: failedClip.title, relatedClipID: failedClip.id)
        touchProject(projectID)
        saveState()
    }

    private func addToSequence(_ clip: GeneratedClip, projectID: UUID) -> Bool {
        var sequenceClips = sequenceClipsByProject[projectID, default: []]
        guard sequenceClips.contains(where: { $0.sourceOutputClipID == clip.id || ($0.sourceOutputClipID == nil && $0.title == clip.title) }) == false else {
            return false
        }

        let sequenceClip = SequenceClip(
            sourceOutputClipID: clip.id,
            title: clip.title,
            order: sequenceClips.count + 1,
            duration: clip.duration,
            continuesFromPreviousFrame: sequenceClips.isEmpty == false,
            thumbnail: clip.thumbnail,
            image: clip.image
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            sequenceClips.append(sequenceClip)
            sequenceClipsByProject[projectID] = sequenceClips
        }

        recordActivity(.addedToSequence, projectID: projectID, detail: clip.title, relatedClipID: clip.id)
        touchProject(projectID)
        saveState()
        return true
    }

    private func retryGeneration(_ clip: GeneratedClip, projectID: UUID) {
        recordActivity(.generationRetried, projectID: projectID, detail: clip.title, relatedClipID: clip.id)
        saveState()

        Task {
            var job = await videoGenerationService.submitRetry(for: clip, projectID: projectID)
            await MainActor.run {
                upsertOutputClip(
                    videoGenerationService.retryOutputClip(for: job, failedClip: clip, status: job.status),
                    projectID: projectID
                )
            }

            for step in 0...2 {
                let status = await videoGenerationService.status(for: job, step: step)
                job.status = status

                await MainActor.run {
                    upsertOutputClip(
                        videoGenerationService.retryOutputClip(for: job, failedClip: clip, status: status),
                        projectID: projectID
                    )
                }

                if case .failed = status {
                    break
                }
            }
        }
    }

    private func upsertOutputClip(_ clip: GeneratedClip, projectID: UUID) {
        var clips = outputsByProject[projectID, default: []]
        let oldClip = clips.first { $0.id == clip.id }
        if let index = clips.firstIndex(where: { $0.id == clip.id }) {
            clips[index] = clip
        } else {
            clips.insert(clip, at: 0)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            outputsByProject[projectID] = clips
        }
        recordOutputStatusActivity(oldClip: oldClip, newClip: clip, projectID: projectID)
        touchProject(projectID)
        saveState()
    }

    private func removeSequenceClipsForDeletedOutputs(oldOutputs: [GeneratedClip], newOutputs: [GeneratedClip], projectID: UUID) {
        let removedOutputIDs = Set(oldOutputs.map(\.id)).subtracting(Set(newOutputs.map(\.id)))
        guard removedOutputIDs.isEmpty == false else { return }
        let removedOutputTitles = Set(oldOutputs.filter { removedOutputIDs.contains($0.id) }.map(\.title))

        var sequenceClips = sequenceClipsByProject[projectID, default: []]
        let originalCount = sequenceClips.count
        sequenceClips.removeAll { clip in
            if let sourceOutputClipID = clip.sourceOutputClipID {
                return removedOutputIDs.contains(sourceOutputClipID)
            }

            // Older persisted sequence rows may not have a source id yet, so fall back to title matching.
            return removedOutputTitles.contains(clip.title)
        }

        guard sequenceClips.count != originalCount else { return }
        sequenceClipsByProject[projectID] = normalizedSequenceClips(sequenceClips)
        removedOutputTitles.forEach { title in
            recordActivity(.removedFromSequence, projectID: projectID, detail: title)
        }
        touchProject(projectID)
    }

    private func recordOutputStatusActivity(oldClip: GeneratedClip?, newClip: GeneratedClip, projectID: UUID) {
        if newClip.status.isCompleted, oldClip?.status.isCompleted != true {
            recordActivity(.outputGenerated, projectID: projectID, detail: newClip.title, relatedClipID: newClip.id)
        } else if newClip.status.isFailed, oldClip?.status.isFailed != true {
            recordActivity(.generationFailed, projectID: projectID, detail: newClip.title, relatedClipID: newClip.id)
        }
    }

    private func recordOutputDeletionActivity(oldOutputs: [GeneratedClip], newOutputs: [GeneratedClip], projectID: UUID) {
        let newIDs = Set(newOutputs.map(\.id))
        oldOutputs
            .filter { newIDs.contains($0.id) == false }
            .forEach { clip in
                recordActivity(.clipDeleted, projectID: projectID, detail: clip.title, relatedClipID: clip.id)
            }
    }

    private func recordSequenceMutationActivity(oldClips: [SequenceClip], newClips: [SequenceClip], projectID: UUID) {
        let newIDs = Set(newClips.map(\.id))
        oldClips
            .filter { newIDs.contains($0.id) == false }
            .forEach { clip in
                recordActivity(.removedFromSequence, projectID: projectID, detail: clip.title, relatedClipID: clip.sourceOutputClipID)
            }

        guard oldClips.count == newClips.count,
              oldClips.map(\.id) != newClips.map(\.id) else { return }
        recordActivity(.sequenceReordered, projectID: projectID, detail: L10n.string("activity.sequence_reordered_detail"))
    }

    private func recordActivity(_ type: ProjectActivityType, projectID: UUID, detail: String, relatedClipID: UUID? = nil) {
        let item = ProjectActivityItem(
            projectID: projectID,
            type: type,
            detail: detail,
            relatedClipID: relatedClipID
        )
        var activities = activityByProject[projectID, default: []]
        activities.insert(item, at: 0)
        activityByProject[projectID] = Array(activities.prefix(50))
    }

    private func formattedActivityDate(_ date: Date) -> String {
        date.formatted(.dateTime.month().day().hour().minute())
    }

    private func touchProject(_ projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        let project = projects[index]
        projects[index] = Project(
            id: project.id,
            title: project.title,
            clipCount: outputsByProject[projectID, default: []].count,
            updatedAt: L10n.string("common.just_now"),
            thumbnail: project.thumbnail,
            description: project.description,
            createdAt: project.createdAt,
            updatedAtDate: Date()
        )
    }

    private func normalizedSequenceClips(_ clips: [SequenceClip]) -> [SequenceClip] {
        clips.enumerated().map { index, clip in
            SequenceClip(
                id: clip.id,
                sourceOutputClipID: clip.sourceOutputClipID,
                title: clip.title,
                order: index + 1,
                duration: clip.duration,
                continuesFromPreviousFrame: index > 0 && clip.continuesFromPreviousFrame,
                thumbnail: clip.thumbnail,
                image: clip.image
            )
        }
    }

    private func saveState() {
        let validProjectIDs = Set(projects.map(\.id))
        let sanitizedCurrentProjectID = currentProjectID.flatMap { validProjectIDs.contains($0) ? $0 : projects.first?.id }

        AppStateStore.save(
            PersistedAppState(
                projects: projects,
                currentProjectID: sanitizedCurrentProjectID,
                outputsByProject: outputsByProject.filter { validProjectIDs.contains($0.key) },
                sequenceClipsByProject: sequenceClipsByProject.filter { validProjectIDs.contains($0.key) },
                studioStateByProject: studioStateByProject.filter { validProjectIDs.contains($0.key) },
                studioContinuationContext: studioContinuationContext,
                activityByProject: activityByProject.filter { validProjectIDs.contains($0.key) }
            )
        )
    }

    private func makeDeveloperStateSummary() -> DeveloperToolsStateSummary {
        let outputsCount = currentProjectID.map { outputsByProject[$0, default: []].count } ?? 0
        let sequenceCount = currentProjectID.map { sequenceClipsByProject[$0, default: []].count } ?? 0

        return DeveloperToolsStateSummary(
            currentProjectName: currentProject?.title ?? L10n.string("common.no_project"),
            projectCount: projects.count,
            currentProjectOutputCount: outputsCount,
            currentProjectSequenceCount: sequenceCount
        )
    }
}

#Preview {
    RootTabView()
}
