import SwiftUI

struct SequenceView: View {
    @Binding var clips: [SequenceClip]
    let currentProject: Project?
    var isEmbeddedInWorkspace = false
    var onShowProjects: () -> Void = {}
    var onShowOutputs: () -> Void = {}

    private let actionFadeHeight: CGFloat = 24
    private let reorderAnimation = Animation.spring(response: 0.28, dampingFraction: 0.86)
    private let sequenceCoordinateSpace = "sequence-reorder-coordinate-space"

    @State private var activeSheet: SequenceSheet?
    @State private var clipPendingRemoval: SequenceClip?
    @State private var showRemoveConfirmation = false
    @State private var isExporting = false
    @State private var showExportComplete = false
    @State private var displayedClips: [SequenceClip] = []
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var draggedClip: SequenceClip?
    @State private var dragLocationY: CGFloat = 0
    @State private var dragGrabOffsetY: CGFloat = 0
    @State private var dragFrame: CGRect = .zero

    var body: some View {
        VStack(spacing: 0) {
            if isEmbeddedInWorkspace == false {
                header
            }

            if let currentProject {
                sequenceList(currentProject)
                .safeAreaInset(edge: .bottom) {
                    actionBar
                }
            } else {
                ProjectRequiredEmptyState(
                    title: L10n.string("common.select_project_first"),
                    message: L10n.string("sequence.no_project_message"),
                    buttonTitle: L10n.string("common.go_to_projects"),
                    action: onShowProjects
                )
            }
        }
        .pannotatePage()
        .sheet(item: $activeSheet) { sheet in
            SequencePlaceholderSheet(sheet: sheet)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert(L10n.string("sequence.export_complete"), isPresented: $showExportComplete) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("sequence.export_complete_message")
        }
        .alert(L10n.string("sequence.remove_clip_question"), isPresented: $showRemoveConfirmation) {
            Button("common.remove", role: .destructive) {
                if let clipPendingRemoval {
                    remove(clipPendingRemoval)
                }

                clipPendingRemoval = nil
            }

            Button("common.cancel", role: .cancel) {
                clipPendingRemoval = nil
            }
        } message: {
            Text("sequence.remove_clip_message")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            PageTitle(
                title: L10n.string("tab.sequence"),
                subtitle: sequenceSubtitle
            )
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(PannotateTheme.Colors.background.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    private var isReordering: Bool {
        draggedClip != nil
    }

    private var sequenceSubtitle: String {
        guard let currentProject else {
            return L10n.string("common.select_project_first")
        }

        return String.localizedStringWithFormat(
            L10n.string("sequence.subtitle_for_project_format"),
            currentProject.title,
            clips.count,
            totalDuration
        )
    }

    private func sequenceList(_ currentProject: Project) -> some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isEmbeddedInWorkspace == false {
                        CurrentProjectBanner(prefix: L10n.string("sequence.for_project"), project: currentProject)
                    }

                    if displayedClips.isEmpty {
                        sequenceGuidedEmptyState
                    } else {
                        ForEach(Array(displayedClips.enumerated()), id: \.element.id) { index, clip in
                            reorderableSequenceItem(clip, displayOrder: index + 1)
                        }
                    }

                    addClipPlaceholder
                }
                .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .coordinateSpace(name: sequenceCoordinateSpace)
            .scrollDisabled(isReordering)
            .onPreferenceChange(SequenceRowFramePreferenceKey.self) { frames in
                rowFrames = frames
            }

            dragOverlay
        }
        .background(PannotateTheme.Colors.background)
        .onAppear {
            syncDisplayedClips()
        }
        .onChange(of: clips.map(\.id)) { _, _ in
            syncDisplayedClips()
        }
        .onChange(of: clips.map(\.order)) { _, _ in
            syncDisplayedClips()
        }
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    PannotateTheme.Colors.background.opacity(0.0),
                    PannotateTheme.Colors.background.opacity(0.62),
                    PannotateTheme.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: actionFadeHeight)
            .allowsHitTesting(false)

            HStack(spacing: 12) {
                SecondaryActionButton(title: L10n.string("common.preview"), systemImage: "play") {
                    activeSheet = .preview
                }

                Button {
                    exportMockSequence()
                } label: {
                    HStack(spacing: 10) {
                        if isExporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }

                        Text(isExporting ? L10n.string("sequence.exporting") : L10n.string("common.export"))
                    }
                    .font(PannotateTheme.Typography.control)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: PannotateTheme.Metrics.buttonHeight)
                    .background(isExporting ? PannotateTheme.Colors.accent.opacity(0.72) : PannotateTheme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .shadow(color: PannotateTheme.Colors.accent.opacity(0.32), radius: 18, y: 8)
                }
                .buttonStyle(.plain)
                .disabled(isExporting)
            }
            .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(PannotateTheme.Colors.background)
        }
    }

    private func exportMockSequence() {
        isExporting = true

        Task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)

            await MainActor.run {
                isExporting = false
                showExportComplete = true
            }
        }
    }

    private func sequenceListItem(_ clip: SequenceClip, displayOrder: Int? = nil, isDragPreview: Bool = false) -> some View {
        VStack(spacing: 6) {
            sequenceRow(clip, displayOrder: displayOrder, isDragPreview: isDragPreview)

            if clip.continuesFromPreviousFrame {
                Label("sequence.continues_from_previous_frame", systemImage: "link")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(PannotateTheme.Colors.accent.opacity(0.74))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 132)
                    .padding(.top, -2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sequenceRow(_ clip: SequenceClip, displayOrder: Int? = nil, isDragPreview: Bool = false) -> some View {
        HStack(spacing: 10) {
            dragHandle(for: clip, isDragPreview: isDragPreview)

            Text("\(displayOrder ?? clip.order)")
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .frame(width: 40, height: 40)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            FixedClipThumbnail(style: clip.thumbnail, image: clip.image, cornerRadius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .fixedSize(horizontal: false, vertical: true)

                Text(clip.duration)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            sequenceMenu(clip)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pannotateCard()
        .contentShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isDragPreview ? PannotateTheme.Colors.accent.opacity(0.28) : .clear, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func dragHandle(for clip: SequenceClip, isDragPreview: Bool) -> some View {
        let canReorder = clips.count > 1
        let handle = Image(systemName: "circle.grid.3x3.fill")
            .font(.subheadline)
            .foregroundStyle(canReorder ? PannotateTheme.Colors.accent : PannotateTheme.Colors.tertiaryText)
            .frame(width: 30, height: 44)
            .contentShape(Rectangle())
            .accessibilityHidden(true)

        if canReorder && isDragPreview == false {
            handle
                .gesture(reorderDragGesture(for: clip))
        } else {
            handle
        }
    }

    private func sequenceMenu(_ clip: SequenceClip) -> some View {
        Menu {
            Button {
                move(clip, offset: -1)
            } label: {
                Label("sequence.move_up", systemImage: "arrow.up")
            }
            .disabled(isFirst(clip))

            Button {
                move(clip, offset: 1)
            } label: {
                Label("sequence.move_down", systemImage: "arrow.down")
            }
            .disabled(isLast(clip))

            Button(role: .destructive) {
                clipPendingRemoval = clip
                showRemoveConfirmation = true
            } label: {
                Label("sequence.remove_from_sequence", systemImage: "minus.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
    }

    private var addClipPlaceholder: some View {
        Button {
            activeSheet = .addClip
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title.weight(.regular))
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)

                Text("sequence.add_clip")
                    .font(PannotateTheme.Typography.control)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(PannotateTheme.Colors.tertiaryText.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
            )
        }
        .buttonStyle(.plain)
        .disabled(isReordering)
        .opacity(isReordering ? 0.55 : 1)
    }


    private var sequenceGuidedEmptyState: some View {
        GuidedEmptyState(
            systemImage: "square.stack.3d.up.slash",
            title: L10n.string("empty.sequence.title"),
            message: L10n.string("empty.sequence.message"),
            primaryTitle: L10n.string("empty.sequence.go_to_outputs"),
            primarySystemImage: "film"
        ) {
            onShowOutputs()
        }
    }

    private var emptySequenceState: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.title.weight(.medium))
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            Text("sequence.empty_title")
                .font(PannotateTheme.Typography.cardTitle)
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Text("sequence.empty_message")
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(PannotateTheme.Colors.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var totalDuration: Int {
        clips.reduce(0) { total, clip in
            total + (Int(clip.duration.replacingOccurrences(of: "s", with: "")) ?? 0)
        }
    }

    private func isFirst(_ clip: SequenceClip) -> Bool {
        clips.first?.id == clip.id
    }

    private func isLast(_ clip: SequenceClip) -> Bool {
        clips.last?.id == clip.id
    }

    private func move(_ clip: SequenceClip, offset: Int) {
        guard let currentIndex = clips.firstIndex(where: { $0.id == clip.id }) else { return }

        let targetIndex = currentIndex + offset
        guard clips.indices.contains(targetIndex) else { return }

        withAnimation(reorderAnimation) {
            clips.swapAt(currentIndex, targetIndex)
            normalizeOrders()
        }
    }

    private func remove(_ clip: SequenceClip) {
        withAnimation(reorderAnimation) {
            clips.removeAll { $0.id == clip.id }
            normalizeOrders()
        }
    }

    private func normalizeOrders() {
        clips = clips.enumerated().map { index, clip in
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

    private func reorderableSequenceItem(_ clip: SequenceClip, displayOrder: Int) -> some View {
        sequenceListItem(clip, displayOrder: displayOrder)
            .opacity(draggedClip?.id == clip.id ? 0 : 1)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: SequenceRowFramePreferenceKey.self,
                        value: [clip.id: proxy.frame(in: .named(sequenceCoordinateSpace))]
                    )
                }
            )
            .animation(reorderAnimation, value: displayedClips.map(\.id))
    }

    @ViewBuilder
    private var dragOverlay: some View {
        if let draggedClip {
            let displayOrder = displayedClips.firstIndex(where: { $0.id == draggedClip.id }).map { $0 + 1 } ?? draggedClip.order

            sequenceListItem(draggedClip, displayOrder: displayOrder, isDragPreview: true)
                .frame(width: dragFrame.width)
                .scaleEffect(1.015)
                .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
                .position(
                    x: dragFrame.midX,
                    y: dragLocationY - dragGrabOffsetY + (dragFrame.height / 2)
                )
                .zIndex(10)
                .allowsHitTesting(false)
        }
    }

    private func reorderDragGesture(for clip: SequenceClip) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(sequenceCoordinateSpace))
            .onChanged { value in
                if draggedClip == nil {
                    beginDrag(clip, value: value)
                }

                updateDragLocation(value.location.y, draggedClipID: clip.id)
            }
            .onEnded { _ in
                finishDrag()
            }
    }

    private func beginDrag(_ clip: SequenceClip, value: DragGesture.Value) {
        guard clips.count > 1, let frame = rowFrames[clip.id] else { return }

        syncDisplayedClips(force: true)
        draggedClip = clip
        dragFrame = frame
        dragGrabOffsetY = value.startLocation.y - frame.minY
        dragLocationY = value.location.y
    }

    private func updateDragLocation(_ locationY: CGFloat, draggedClipID: UUID) {
        guard draggedClip?.id == draggedClipID else { return }

        dragLocationY = locationY
        updateDisplayedOrder(draggedClipID: draggedClipID, locationY: locationY)
    }

    private func updateDisplayedOrder(draggedClipID: UUID, locationY: CGFloat) {
        guard let currentIndex = displayedClips.firstIndex(where: { $0.id == draggedClipID }) else { return }

        let remainingClips = displayedClips.filter { $0.id != draggedClipID }
        var destinationIndex = remainingClips.count

        for (index, clip) in remainingClips.enumerated() {
            guard let frame = rowFrames[clip.id] else { continue }

            if locationY < frame.midY {
                destinationIndex = index
                break
            }
        }

        var reorderedClips = displayedClips
        let dragged = reorderedClips.remove(at: currentIndex)
        let safeDestinationIndex = min(destinationIndex, reorderedClips.count)

        guard safeDestinationIndex != currentIndex else { return }

        withAnimation(reorderAnimation) {
            reorderedClips.insert(dragged, at: safeDestinationIndex)
            displayedClips = reorderedClips
        }
    }

    private func finishDrag() {
        guard draggedClip != nil else { return }

        let normalizedClips = normalized(displayedClips)
        let orderChanged = normalizedClips.map(\.id) != clips.map(\.id)

        withAnimation(reorderAnimation) {
            displayedClips = normalizedClips
            draggedClip = nil
            dragLocationY = 0
            dragGrabOffsetY = 0
            dragFrame = .zero
        }

        if orderChanged {
            clips = normalizedClips
        }
    }

    private func syncDisplayedClips(force: Bool = false) {
        guard force || isReordering == false else { return }
        displayedClips = normalized(clips)
    }

    private func normalized(_ clips: [SequenceClip]) -> [SequenceClip] {
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
}

private struct SequenceRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private enum SequenceSheet: String, Identifiable {
    case preview
    case addClip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preview:
            L10n.string("sequence.preview_title")
        case .addClip:
            L10n.string("sequence.add_clip")
        }
    }

    var systemImage: String {
        switch self {
        case .preview:
            "play.rectangle"
        case .addClip:
            "plus.rectangle.on.rectangle"
        }
    }

    var message: String {
        switch self {
        case .preview:
            L10n.string("sequence.preview_message")
        case .addClip:
            L10n.string("sequence.add_clip_message")
        }
    }
}

private struct SequencePlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let sheet: SequenceSheet

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: sheet.systemImage)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(PannotateTheme.Colors.accent)
                    .frame(width: 104, height: 104)
                    .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                    .clipShape(Circle())

                Text(sheet.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Text(sheet.message)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(sheet.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    SequenceView(clips: .constant(MockPannotateData.sequenceClips), currentProject: MockPannotateData.projects.first)
}
