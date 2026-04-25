import SwiftUI

struct SequenceView: View {
    @Binding var clips: [SequenceClip]
    @State private var activeSheet: SequenceSheet?
    @State private var clipPendingRemoval: SequenceClip?
    @State private var showRemoveConfirmation = false
    @State private var isExporting = false
    @State private var showExportComplete = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(clips) { clip in
                            VStack(spacing: 6) {
                                sequenceRow(clip)

                                if clip.continuesFromPreviousFrame {
                                    Label("Continues from previous frame", systemImage: "link")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(PannotateTheme.Colors.accent.opacity(0.74))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 142)
                                        .padding(.top, -2)
                                }
                            }
                        }

                        addClipPlaceholder
                    }
                    .padding(PannotateTheme.Metrics.pagePadding)
                    .padding(.bottom, 22)
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
        }
        .pannotatePage()
        .sheet(item: $activeSheet) { sheet in
            SequencePlaceholderSheet(sheet: sheet)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Export Complete", isPresented: $showExportComplete) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your mock sequence export is ready. Real video export will come later.")
        }
        .alert("Remove Clip?", isPresented: $showRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                if let clipPendingRemoval {
                    remove(clipPendingRemoval)
                }

                clipPendingRemoval = nil
            }

            Button("Cancel", role: .cancel) {
                clipPendingRemoval = nil
            }
        } message: {
            Text("This removes the clip from the local mock sequence.")
        }
    }

    private var header: some View {
        VStack(spacing: 18) {
            PageTitle(title: "Sequence", subtitle: "\(clips.count) clips · \(totalDuration)s total")
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(PannotateTheme.Colors.background.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            SecondaryActionButton(title: "Preview", systemImage: "play") {
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

                    Text(isExporting ? "Exporting..." : "Export")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isExporting ? PannotateTheme.Colors.accent.opacity(0.72) : PannotateTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                .shadow(color: PannotateTheme.Colors.accent.opacity(0.32), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(isExporting)
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    PannotateTheme.Colors.background.opacity(0.0),
                    PannotateTheme.Colors.background.opacity(0.96),
                    PannotateTheme.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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

    private func sequenceRow(_ clip: SequenceClip) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.grid.3x3.fill")
                .font(.subheadline)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .frame(width: 18)

            Text("\(clip.order)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .frame(width: 40, height: 40)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            FixedClipThumbnail(style: clip.thumbnail, cornerRadius: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .fixedSize(horizontal: false, vertical: true)

                Text(clip.duration)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            sequenceMenu(clip)
        }
        .padding(14)
        .pannotateCard()
    }

    private func sequenceMenu(_ clip: SequenceClip) -> some View {
        Menu {
            Button {
                move(clip, offset: -1)
            } label: {
                Label("Move Up", systemImage: "arrow.up")
            }
            .disabled(isFirst(clip))

            Button {
                move(clip, offset: 1)
            } label: {
                Label("Move Down", systemImage: "arrow.down")
            }
            .disabled(isLast(clip))

            Button(role: .destructive) {
                clipPendingRemoval = clip
                showRemoveConfirmation = true
            } label: {
                Label("Remove from Sequence", systemImage: "minus.circle")
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
                    .font(.largeTitle.weight(.light))
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)

                Text("Add clip")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(PannotateTheme.Colors.tertiaryText.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
            )
        }
        .buttonStyle(.plain)
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

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            clips.swapAt(currentIndex, targetIndex)
            normalizeOrders()
        }
    }

    private func remove(_ clip: SequenceClip) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            clips.removeAll { $0.id == clip.id }
            normalizeOrders()
        }
    }

    private func normalizeOrders() {
        clips = clips.enumerated().map { index, clip in
            SequenceClip(
                id: clip.id,
                title: clip.title,
                order: index + 1,
                duration: clip.duration,
                continuesFromPreviousFrame: index > 0 && clip.continuesFromPreviousFrame,
                thumbnail: clip.thumbnail
            )
        }
    }
}

private enum SequenceSheet: String, Identifiable {
    case preview
    case addClip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preview:
            "Sequence Preview"
        case .addClip:
            "Add Clip"
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
            "This is a mock preview placeholder. Real timeline playback will be added later."
        case .addClip:
            "Clip selection will be wired to generated outputs later. For now this is a local prototype placeholder."
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
                    .font(.title2.weight(.bold))
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
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    SequenceView(clips: .constant(MockPannotateData.sequenceClips))
}
