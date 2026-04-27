import SwiftUI

enum PannotateTab {
    case projects
    case studio
    case outputs
    case sequence
    case profile
}

struct RootTabView: View {
    @State private var selectedTab: PannotateTab = .projects
    @State private var projects: [Project]
    @State private var currentProjectID: UUID?
    @State private var outputsByProject: [UUID: [GeneratedClip]]
    @State private var sequenceClipsByProject: [UUID: [SequenceClip]]
    @State private var studioStateByProject: [UUID: StudioProjectState]
    @State private var studioContinuationContext: StudioContinuationContext?
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
        } else {
            let projects = MockPannotateData.projects
            let initialProjectID = projects.first?.id

            _projects = State(initialValue: projects)
            _currentProjectID = State(initialValue: initialProjectID)
            _outputsByProject = State(initialValue: initialProjectID.map { [$0: MockPannotateData.generatedClips] } ?? [:])
            _sequenceClipsByProject = State(initialValue: initialProjectID.map { [$0: MockPannotateData.sequenceClips] } ?? [:])
            _studioStateByProject = State(initialValue: [:])
            _studioContinuationContext = State(initialValue: nil)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ProjectsView(
                    projects: projectsBinding,
                    currentProjectID: currentProjectIDBinding,
                    onProjectCreated: prepareProjectState,
                    onProjectDeleted: handleProjectDeleted
                )
            }
            .tabItem {
                Label("tab.projects", systemImage: "house")
            }
            .tag(PannotateTab.projects)

            NavigationStack {
                StudioView(
                    currentProject: currentProject,
                    continuationContext: studioContinuationContext,
                    persistedState: currentStudioState,
                    onShowProjects: showProjectsTab,
                    onClearContinuation: clearContinuation
                ) { clip in
                    guard let currentProjectID else { return }

                    var clips = outputsByProject[currentProjectID, default: []]
                    if let index = clips.firstIndex(where: { $0.id == clip.id }) {
                        clips[index] = clip
                    } else {
                        clips.insert(clip, at: 0)
                    }
                    outputsByProject[currentProjectID] = clips
                    saveState()

                    withAnimation(.easeInOut) {
                        selectedTab = .outputs
                    }
                } onStudioStateChanged: { state in
                    guard let currentProjectID else { return }
                    studioStateByProject[currentProjectID] = state
                    saveState()
                }
            }
            .tabItem {
                Label("tab.studio", systemImage: "video")
            }
            .tag(PannotateTab.studio)

            NavigationStack {
                OutputsView(
                    clips: currentOutputsBinding,
                    currentProject: currentProject,
                    onShowProjects: showProjectsTab,
                    onShowStudio: showStudioTab,
                    onContinueClip: continueFromClip,
                    onAddToSequence: addToSequence,
                    onRetryClip: retryGeneration
                ) {
                    withAnimation(.easeInOut) {
                        selectedTab = .sequence
                    }
                }
            }
            .tabItem {
                Label("tab.outputs", systemImage: "film")
            }
            .tag(PannotateTab.outputs)

            NavigationStack {
                SequenceView(clips: currentSequenceBinding, currentProject: currentProject, onShowProjects: showProjectsTab, onShowOutputs: showOutputsTab)
            }
            .tabItem {
                Label("tab.sequence", systemImage: "square.stack.3d.up")
            }
            .tag(PannotateTab.sequence)

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
        return projects.first { $0.id == currentProjectID }
    }

    private var currentStudioState: StudioProjectState? {
        guard let currentProjectID else { return nil }
        return studioStateByProject[currentProjectID]
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
        outputsByProject.values
            .flatMap { $0 }
            .prefix(3)
            .map { clip in
                ProfileActivityItem(
                    id: clip.id,
                    title: clip.title,
                    subtitle: activitySubtitle(for: clip),
                    thumbnail: clip.thumbnail,
                    image: clip.image
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

    private var currentOutputsBinding: Binding<[GeneratedClip]> {
        Binding {
            guard let currentProjectID else { return [] }
            return outputsByProject[currentProjectID, default: []]
        } set: { newValue in
            guard let currentProjectID else { return }
            removeSequenceClipsForDeletedOutputs(oldOutputs: outputsByProject[currentProjectID, default: []], newOutputs: newValue, projectID: currentProjectID)
            outputsByProject[currentProjectID] = newValue
            saveState()
        }
    }

    private var currentSequenceBinding: Binding<[SequenceClip]> {
        Binding {
            guard let currentProjectID else { return [] }
            return sequenceClipsByProject[currentProjectID, default: []]
        } set: { newValue in
            guard let currentProjectID else { return }
            sequenceClipsByProject[currentProjectID] = newValue
            saveState()
        }
    }

    private func showProjectsTab() {
        withAnimation(.easeInOut) {
            selectedTab = .projects
        }
    }

    private func showStudioTab() {
        withAnimation(.easeInOut) {
            selectedTab = .studio
        }
    }

    private func showOutputsTab() {
        withAnimation(.easeInOut) {
            selectedTab = .outputs
        }
    }

    private func continueFromClip(_ clip: GeneratedClip) {
        studioContinuationContext = StudioContinuationContext(
            id: clip.id,
            title: clip.title,
            thumbnail: clip.thumbnail,
            image: clip.image
        )
        saveState()

        withAnimation(.easeInOut) {
            selectedTab = .studio
        }
    }

    private func clearContinuation() {
        withAnimation(.easeInOut) {
            studioContinuationContext = nil
        }
        saveState()
    }

    private func activitySubtitle(for clip: GeneratedClip) -> String {
        let status = clip.status.label
        return "\(L10n.string("profile.generated_clip")) · \(status) · \(clip.createdAt)"
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

    private func handleProjectDeleted(_ project: Project) {
        outputsByProject[project.id] = nil
        sequenceClipsByProject[project.id] = nil
        studioStateByProject[project.id] = nil
        studioContinuationContext = nil

        if currentProjectID == project.id {
            currentProjectID = projects.first?.id
        }

        saveState()
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
        }
        saveState()
    }

    private func addSampleOutputs() {
        let projectID = ensureDebugProject()
        let samples = [
            GeneratedClip(
                title: L10n.string("developer_tools.sample_completed_clip_title"),
                duration: "4s",
                createdAt: L10n.string("developer_tools.just_now"),
                status: .done,
                thumbnail: .city,
                generationRequestID: UUID(),
                generationRequestSummary: L10n.string("developer_tools.sample_request_summary"),
                interpretationMode: .fast,
                finalVideoPrompt: L10n.string("developer_tools.sample_final_prompt"),
                annotationCount: 1,
                generationMode: .newShot
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
        saveState()
    }

    private func addToSequence(_ clip: GeneratedClip) -> Bool {
        guard let currentProjectID else { return false }

        var sequenceClips = sequenceClipsByProject[currentProjectID, default: []]
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
            sequenceClipsByProject[currentProjectID] = sequenceClips
        }

        saveState()
        return true
    }

    private func retryGeneration(_ clip: GeneratedClip) {
        guard let currentProjectID else { return }

        Task {
            var job = await videoGenerationService.submitRetry(for: clip)
            await MainActor.run {
                upsertOutputClip(
                    videoGenerationService.retryOutputClip(for: job, failedClip: clip, status: job.status),
                    projectID: currentProjectID
                )
            }

            for step in 0...2 {
                let status = await videoGenerationService.status(for: job, step: step)
                job.status = status

                await MainActor.run {
                    upsertOutputClip(
                        videoGenerationService.retryOutputClip(for: job, failedClip: clip, status: status),
                        projectID: currentProjectID
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
        if let index = clips.firstIndex(where: { $0.id == clip.id }) {
            clips[index] = clip
        } else {
            clips.insert(clip, at: 0)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            outputsByProject[projectID] = clips
        }
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
                studioContinuationContext: studioContinuationContext
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
