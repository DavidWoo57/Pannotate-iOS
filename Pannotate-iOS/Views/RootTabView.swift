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
    @State private var studioContinuationContext: StudioContinuationContext?

    init() {
        let projects = MockPannotateData.projects
        let initialProjectID = projects.first?.id

        _projects = State(initialValue: projects)
        _currentProjectID = State(initialValue: initialProjectID)
        _outputsByProject = State(initialValue: initialProjectID.map { [$0: MockPannotateData.generatedClips] } ?? [:])
        _sequenceClipsByProject = State(initialValue: initialProjectID.map { [$0: MockPannotateData.sequenceClips] } ?? [:])
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ProjectsView(
                    projects: $projects,
                    currentProjectID: $currentProjectID,
                    onProjectCreated: prepareProjectState,
                    onProjectDeleted: handleProjectDeleted
                )
            }
            .tabItem {
                Label("Projects", systemImage: "house")
            }
            .tag(PannotateTab.projects)

            NavigationStack {
                StudioView(
                    currentProject: currentProject,
                    continuationContext: studioContinuationContext,
                    onShowProjects: showProjectsTab,
                    onClearContinuation: clearContinuation
                ) { clip in
                    guard let currentProjectID else { return }

                    var clips = outputsByProject[currentProjectID, default: []]
                    clips.insert(clip, at: 0)
                    outputsByProject[currentProjectID] = clips

                    withAnimation(.easeInOut) {
                        selectedTab = .outputs
                    }
                }
            }
            .tabItem {
                Label("Studio", systemImage: "video")
            }
            .tag(PannotateTab.studio)

            NavigationStack {
                OutputsView(
                    clips: currentOutputsBinding,
                    currentProject: currentProject,
                    onShowProjects: showProjectsTab,
                    onContinueClip: continueFromClip,
                    onAddToSequence: addToSequence
                ) {
                    withAnimation(.easeInOut) {
                        selectedTab = .sequence
                    }
                }
            }
            .tabItem {
                Label("Outputs", systemImage: "film")
            }
            .tag(PannotateTab.outputs)

            NavigationStack {
                SequenceView(clips: currentSequenceBinding, currentProject: currentProject, onShowProjects: showProjectsTab)
            }
            .tabItem {
                Label("Sequence", systemImage: "square.stack.3d.up")
            }
            .tag(PannotateTab.sequence)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(PannotateTab.profile)
        }
        .tint(PannotateTheme.Colors.accent)
    }

    private var currentProject: Project? {
        guard let currentProjectID else { return nil }
        return projects.first { $0.id == currentProjectID }
    }

    private var currentOutputsBinding: Binding<[GeneratedClip]> {
        Binding {
            guard let currentProjectID else { return [] }
            return outputsByProject[currentProjectID, default: []]
        } set: { newValue in
            guard let currentProjectID else { return }
            outputsByProject[currentProjectID] = newValue
        }
    }

    private var currentSequenceBinding: Binding<[SequenceClip]> {
        Binding {
            guard let currentProjectID else { return [] }
            return sequenceClipsByProject[currentProjectID, default: []]
        } set: { newValue in
            guard let currentProjectID else { return }
            sequenceClipsByProject[currentProjectID] = newValue
        }
    }

    private func showProjectsTab() {
        withAnimation(.easeInOut) {
            selectedTab = .projects
        }
    }

    private func continueFromClip(_ clip: GeneratedClip) {
        studioContinuationContext = StudioContinuationContext(
            id: clip.id,
            title: clip.title,
            thumbnail: clip.thumbnail,
            image: clip.image
        )

        withAnimation(.easeInOut) {
            selectedTab = .studio
        }
    }

    private func clearContinuation() {
        withAnimation(.easeInOut) {
            studioContinuationContext = nil
        }
    }

    private func prepareProjectState(_ project: Project) {
        if outputsByProject[project.id] == nil {
            outputsByProject[project.id] = []
        }

        if sequenceClipsByProject[project.id] == nil {
            sequenceClipsByProject[project.id] = []
        }
    }

    private func handleProjectDeleted(_ project: Project) {
        outputsByProject[project.id] = nil
        sequenceClipsByProject[project.id] = nil
        studioContinuationContext = nil

        guard currentProjectID == project.id else { return }
        currentProjectID = projects.first?.id
    }

    private func addToSequence(_ clip: GeneratedClip) -> Bool {
        guard let currentProjectID else { return false }

        var sequenceClips = sequenceClipsByProject[currentProjectID, default: []]
        guard sequenceClips.contains(where: { $0.title == clip.title }) == false else {
            return false
        }

        let sequenceClip = SequenceClip(
            title: clip.title,
            order: sequenceClips.count + 1,
            duration: clip.duration,
            continuesFromPreviousFrame: sequenceClips.isEmpty == false,
            thumbnail: clip.thumbnail
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            sequenceClips.append(sequenceClip)
            sequenceClipsByProject[currentProjectID] = sequenceClips
        }

        return true
    }
}

#Preview {
    RootTabView()
}
