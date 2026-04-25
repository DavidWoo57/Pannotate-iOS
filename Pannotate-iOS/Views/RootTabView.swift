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
    @State private var projects = MockPannotateData.projects
    @State private var generatedClips = MockPannotateData.generatedClips
    @State private var sequenceClips = MockPannotateData.sequenceClips

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ProjectsView(projects: $projects)
            }
            .tabItem {
                Label("Projects", systemImage: "house")
            }
            .tag(PannotateTab.projects)

            NavigationStack {
                StudioView { clip in
                    generatedClips.insert(clip, at: 0)

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
                OutputsView(clips: $generatedClips, onAddToSequence: addToSequence) {
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
                SequenceView(clips: $sequenceClips)
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

    private func addToSequence(_ clip: GeneratedClip) -> Bool {
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
        }

        return true
    }
}

#Preview {
    RootTabView()
}
