import PhotosUI
import SwiftUI
import UIKit

struct StudioView: View {
    @State private var motionPrompt = ""
    @State private var isGenerating = false
    @State private var successMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedMockThumbnail: ThumbnailStyle?
    @State private var imageSelectionMessage: String?
    @State private var imageScale: CGFloat = 1
    @State private var imageOffset: CGSize = .zero
    @State private var activeImageAdjustment: ImageAdjustmentSession?
    @State private var annotations: [StudioAnnotation] = []
    @State private var annotationEditorSession: AnnotationEditorSession?
    @State private var isPresentingPromptPreview = false
    @State private var generateReviewSession: GenerateReviewSession?
    @State private var isPreparingGenerateReview = false
    @State private var annotationCanvasSize = CGSize(width: 360, height: 224)
    @State private var lastGeneratedInstruction: String?
    @State private var lastGenerationRequest: GenerationRequest?
    @State private var interpretationMode: AnnotationInterpretationMode = .fast
    @State private var generationParameters: GenerationParameterState = .defaults
    @State private var loadedProjectID: UUID?
    @State private var isApplyingPersistedState = false

    let currentProject: Project?
    var isEmbeddedInWorkspace = false
    var continuationContext: StudioContinuationContext? = nil
    var persistedState: StudioProjectState? = nil
    var onShowProjects: () -> Void = {}
    var onClearContinuation: () -> Void = {}
    var onGeneratedClip: (GeneratedClip) -> Void = { _ in }
    var onStudioStateChanged: (StudioProjectState) -> Void = { _ in }

    private let videoGenerationService: VideoGenerationService = MockVideoGenerationService()
    private let visionInterpretationService: VisionInterpretationService = MockVisionInterpretationService()

    var body: some View {
        VStack(spacing: 0) {
            if isEmbeddedInWorkspace == false {
                studioHeader
            }

            if let currentProject {
                ScrollView {
                    VStack(spacing: 16) {
                        if isEmbeddedInWorkspace == false {
                            CurrentProjectBanner(prefix: L10n.string("studio.editing"), project: currentProject)
                        }

                        if let continuationContext {
                            continuationBanner(continuationContext)
                        }

                        canvas

                        annotationEntryPoint

                        TextField(L10n.string("studio.motion_placeholder"), text: $motionPrompt)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(PannotateTheme.Colors.primaryText)
                            .padding(.horizontal, 16)
                            .frame(height: 58)
                            .background(PannotateTheme.Colors.cardMuted)
                            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                                    .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                            )

                        interpretationModeSelector

                        promptPreviewButton

                        generateButton

                        if let successMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(successMessage, systemImage: "checkmark.circle.fill")
                                    .font(PannotateTheme.Typography.metadataEmphasis)
                                    .foregroundStyle(PannotateTheme.Colors.success)

                                if lastGeneratedInstruction != nil {
                                    Button {
                                        isPresentingPromptPreview = true
                                    } label: {
                                        Text("studio.view_request_used")
                                            .font(PannotateTheme.Typography.metadataEmphasis)
                                            .foregroundStyle(PannotateTheme.Colors.accent)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if let imageSelectionMessage {
                            Label(imageSelectionMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(PannotateTheme.Typography.metadataEmphasis)
                                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(PannotateTheme.Metrics.pagePadding)
                    .padding(.top, isEmbeddedInWorkspace ? 10 : 12)
                    .padding(.bottom, isEmbeddedInWorkspace ? 0 : PannotateTheme.Metrics.tabBarContentInset)
                }
            } else {
                ProjectRequiredEmptyState(
                    title: L10n.string("studio.select_or_create_project_first"),
                    message: L10n.string("studio.no_project_message"),
                    buttonTitle: L10n.string("common.go_to_projects"),
                    action: onShowProjects
                )
            }
        }
        .pannotatePage()
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .onAppear {
            applyPersistedStateForCurrentProject(force: false)
            applyContinuationContextIfNeeded()
        }
        .onChange(of: currentProject?.id) { _, _ in
            applyPersistedStateForCurrentProject(force: true)
            applyContinuationContextIfNeeded()
        }
        .onChange(of: continuationContext?.id) { _, _ in
            applyContinuationContextIfNeeded()
        }
        .onChange(of: motionPrompt) { _, _ in
            persistStudioState()
        }
        .onChange(of: interpretationMode) { _, _ in
            persistStudioState()
        }
        .fullScreenCover(item: $annotationEditorSession) { session in
            AnnotationEditorView(
                image: session.image,
                thumbnail: session.thumbnail,
                initialAnnotations: session.annotations,
                baseCanvasSize: annotationCanvasSize,
                imageScale: imageScale,
                imageOffset: imageOffset
            ) { editedAnnotations in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    annotations = editedAnnotations
                    successMessage = nil
                }

                persistStudioState()
                annotationEditorSession = nil
            }
        }
        .fullScreenCover(item: $activeImageAdjustment) { session in
            ImageAdjustmentView(session: session) { image, scale, offset in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    selectedImage = image
                    selectedMockThumbnail = nil
                    imageScale = scale
                    imageOffset = offset
                    if session.clearsAnnotationsOnConfirm {
                        clearAnnotations()
                    }
                    successMessage = nil
                }

                if session.exitsContinuationOnConfirm {
                    onClearContinuation()
                }
                persistStudioState()
                activeImageAdjustment = nil
            } onCancel: {
                activeImageAdjustment = nil
            }
        }
        .sheet(isPresented: $isPresentingPromptPreview) {
            PromptPreviewSheet(preview: promptPreview)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $generateReviewSession) { session in
            GenerateReviewSheet(session: session) { editedFinalPrompt in
                generateReviewSession = nil
                startMockGeneration(
                    from: session,
                    editedFinalPrompt: editedFinalPrompt.finalPrompt,
                    parameters: editedFinalPrompt.parameters
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var generateButton: some View {
        Button {
            prepareGenerateReview()
        } label: {
            HStack(spacing: 10) {
                if isGenerating || isPreparingGenerateReview {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }

                Text(generateButtonTitle)
            }
            .font(PannotateTheme.Typography.cardTitle)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(generateButtonColor)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            .shadow(color: hasRequiredInputs ? PannotateTheme.Colors.accent.opacity(0.32) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!hasRequiredInputs || isGenerating || isPreparingGenerateReview)
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
        .animation(.easeInOut(duration: 0.2), value: isPreparingGenerateReview)
        .animation(.easeInOut(duration: 0.2), value: hasRequiredInputs)
    }

    private var generateButtonTitle: String {
        if isPreparingGenerateReview {
            return L10n.string("studio.preparing")
        }

        return isGenerating ? L10n.string("studio.generating") : L10n.string("studio.generate_video")
    }

    private var hasRequiredInputs: Bool {
        currentProject != nil && hasCanvasSource && !motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasCanvasSource: Bool {
        selectedImage != nil || selectedMockThumbnail != nil
    }

    private var activeGenerationMode: GenerationMode {
        continuationContext == nil ? .newShot : .continueFromLastFrame
    }

    private var generateButtonColor: Color {
        if isGenerating || isPreparingGenerateReview {
            return PannotateTheme.Colors.accent.opacity(0.72)
        }

        return hasRequiredInputs ? PannotateTheme.Colors.accent : PannotateTheme.Colors.tertiaryText.opacity(0.52)
    }

    private func prepareGenerateReview() {
        guard currentProject != nil, hasCanvasSource else { return }

        let request = currentGenerationRequest
        let pipelineResult = currentPromptPipelineResult
        successMessage = nil
        lastGenerationRequest = request
        isPreparingGenerateReview = true

        Task {
            let originalFinalPrompt = await finalVideoPrompt(for: pipelineResult)

            await MainActor.run {
                generateReviewSession = GenerateReviewSession(
                    request: request,
                    pipelineResult: pipelineResult,
                    originalFinalPrompt: originalFinalPrompt,
                    title: generatedClipTitle,
                    thumbnail: selectedMockThumbnail ?? .city,
                    image: selectedImage,
                    continuationSourceClipID: continuationContext?.id,
                    continuationSourceClipTitle: continuationContext?.title,
                    generationParameters: generationParameters
                )
                isPreparingGenerateReview = false
            }
        }
    }

    private func startMockGeneration(
        from session: GenerateReviewSession,
        editedFinalPrompt: String,
        parameters: GenerationParameterState
    ) {
        guard currentProject != nil, hasCanvasSource else { return }

        generationParameters = parameters
        persistStudioState()
        let finalPrompt = editedFinalPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? session.originalFinalPrompt
            : editedFinalPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = session.request.applyingGenerationParameters(parameters)
        let shouldClearContinuationAfterGeneration = continuationContext != nil
        lastGeneratedInstruction = finalPrompt
        lastGenerationRequest = request
        isGenerating = true

        Task {
            let baseSubmission = VideoGenerationSubmission(
                request: request,
                pipelineResult: session.pipelineResult,
                title: session.title,
                duration: parameters.duration.value,
                thumbnail: session.thumbnail,
                image: session.image,
                continuationSourceClipID: session.continuationSourceClipID,
                continuationSourceClipTitle: session.continuationSourceClipTitle,
                finalVideoPrompt: finalPrompt,
                originalGeneratedPrompt: session.originalFinalPrompt
            )
            let submission = VideoGenerationSubmission(
                request: baseSubmission.request,
                pipelineResult: baseSubmission.pipelineResult,
                title: baseSubmission.title,
                duration: baseSubmission.duration,
                thumbnail: baseSubmission.thumbnail,
                image: baseSubmission.image,
                continuationSourceClipID: baseSubmission.continuationSourceClipID,
                continuationSourceClipTitle: baseSubmission.continuationSourceClipTitle,
                finalVideoPrompt: baseSubmission.finalVideoPrompt,
                originalGeneratedPrompt: baseSubmission.originalGeneratedPrompt,
                payload: GenerationPayloadBuilder.build(submission: baseSubmission)
            )
            var job = await videoGenerationService.submitGeneration(submission)
            await MainActor.run {
                onGeneratedClip(videoGenerationService.outputClip(for: job, submission: submission, status: job.status))
            }

            var didFail = false
            for step in 0...2 {
                let status = await videoGenerationService.status(for: job, step: step)
                job.status = status

                await MainActor.run {
                    onGeneratedClip(videoGenerationService.outputClip(for: job, submission: submission, status: status))
                }

                if case .failed = status {
                    didFail = true
                    break
                }
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isGenerating = false
                    successMessage = didFail ? L10n.string("generation.generation_failed") : L10n.string("studio.mock_clip_generated")
                }

                if didFail == false && shouldClearContinuationAfterGeneration {
                    onClearContinuation()
                    selectedImage = nil
                    selectedMockThumbnail = nil
                    imageScale = 1
                    imageOffset = .zero
                    clearAnnotations()
                    persistStudioState()
                }
            }
        }
    }

    private func finalVideoPrompt(for pipelineResult: PromptPipelineResult) async -> String {
        guard pipelineResult.interpretationMode == .smart else {
            return pipelineResult.fastPrompt
        }

        let interpretation = await visionInterpretationService.interpret(
            payload: pipelineResult.smartPayload,
            simulatedPrompt: pipelineResult.smartMockResult
        )
        return interpretation.refinedVideoPrompt
    }

    private var generatedClipTitle: String {
        if let continuationContext {
            return "\(continuationContext.title) - Continued"
        }

        let prompt = motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        if prompt.count <= 32 {
            return prompt.isEmpty ? L10n.string("studio.mock_clip_title") : prompt
        }

        return "\(prompt.prefix(32))..."
    }

    private var interpretationModeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Label("studio.interpretation_mode", systemImage: "wand.and.stars")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)

                Spacer()
            }

            Picker(L10n.string("studio.interpretation_mode"), selection: $interpretationMode) {
                ForEach(AnnotationInterpretationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(interpretationModeHelpText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(PannotateTheme.Colors.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private var interpretationModeHelpText: String {
        switch interpretationMode {
        case .fast:
            L10n.string("studio.fast_help")
        case .smart:
            L10n.string("studio.smart_help")
        }
    }

    private var promptPreviewButton: some View {
        Button {
            isPresentingPromptPreview = true
        } label: {
            Label("studio.preview_request", systemImage: "doc.text.magnifyingglass")
                .font(PannotateTheme.Typography.cardTitle)
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                        .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        imageSelectionMessage = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        imageSelectionMessage = L10n.string("studio.photo_load_failed")
                    }
                    return
                }

                await MainActor.run {
                    activeImageAdjustment = ImageAdjustmentSession(image: image)
                }
            } catch {
                await MainActor.run {
                    imageSelectionMessage = L10n.string("studio.photo_selection_unavailable")
                }
            }
        }
    }

    private var studioHeader: some View {
        HStack {
            Text("tab.studio")
                .font(.title2.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Spacer()

            Image(systemName: "ellipsis")
                .font(.title2.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .frame(height: 62)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    private func continuationBanner(_ context: StudioContinuationContext) -> some View {
        HStack(spacing: 12) {
            Group {
                if let image = context.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    MockThumbnail(style: context.thumbnail, cornerRadius: 12)
                }
            }
            .frame(width: 58, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("studio.continuing_from")
                    .font(PannotateTheme.Typography.label)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(PannotateTheme.Colors.accent)

                Text(context.title)
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                exitContinuationMode()
            } label: {
                Image(systemName: "xmark")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(PannotateTheme.Colors.accentSoft.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.accent.opacity(0.36), lineWidth: 1)
        )
    }

    private var canvas: some View {
        ZStack {
            if hasCanvasSource {
                annotatedImageCanvas()

                HStack(spacing: 10) {
                    if let selectedImage {
                        Button {
                            activeImageAdjustment = ImageAdjustmentSession(
                                image: selectedImage,
                                initialScale: imageScale,
                                initialOffset: imageOffset,
                                clearsAnnotationsOnConfirm: false,
                                exitsContinuationOnConfirm: false
                            )
                        } label: {
                            canvasOverlayLabel(L10n.string("studio.adjust"), systemImage: "crop")
                        }
                        .buttonStyle(.plain)
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        canvasOverlayLabel(L10n.string("studio.change"), systemImage: "photo")
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(14)
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(PannotateTheme.Colors.accent)

                        VStack(spacing: 6) {
                            Text("empty.studio.no_image.title")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(PannotateTheme.Colors.primaryText)

                            Text("empty.studio.no_image.message")
                                .font(PannotateTheme.Typography.metadata)
                                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        Label("empty.studio.add_image", systemImage: "plus")
                            .font(PannotateTheme.Typography.control)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 42)
                            .background(PannotateTheme.Colors.accent)
                            .clipShape(Capsule())
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .frame(height: 224)
                    .background(PannotateTheme.cardGradient)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 224)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func annotatedImageCanvas() -> some View {
        GeometryReader { geometry in
            ZStack {
                canvasSourceView()
                    .frame(width: geometry.size.width, height: geometry.size.height)

                annotationOverlay
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onAppear {
                annotationCanvasSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                annotationCanvasSize = newSize
            }
        }
    }

    @ViewBuilder
    private func canvasSourceView() -> some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .scaleEffect(imageScale)
                .offset(imageOffset)
                .clipped()
        } else if let selectedMockThumbnail {
            MockThumbnail(style: selectedMockThumbnail, cornerRadius: 0)
        }
    }

    private func canvasOverlayLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(PannotateTheme.Typography.label)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.72))
            .clipShape(Capsule())
    }

    private var annotationEntryPoint: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("studio.annotations")
                        .font(PannotateTheme.Typography.cardTitle)
                        .foregroundStyle(PannotateTheme.Colors.primaryText)

                    Text(annotationCountSummary)
                        .font(PannotateTheme.Typography.metadata)
                        .foregroundStyle(PannotateTheme.Colors.secondaryText)
                }

                Spacer()
            }

            Button {
                openAnnotationEditor()
            } label: {
                Label(hasCanvasSource ? L10n.string("studio.edit_annotations") : L10n.string("studio.select_image_first"), systemImage: "pencil.and.outline")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(hasCanvasSource ? PannotateTheme.Colors.accent : PannotateTheme.Colors.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                            .stroke(hasCanvasSource ? PannotateTheme.Colors.accent.opacity(0.42) : PannotateTheme.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!hasCanvasSource)
        }
        .padding(14)
        .background(PannotateTheme.Colors.cardMuted.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
    }

    private var annotationCountSummary: String {
        let strokeCount = annotations.compactMap(\.stroke).count
        let circleCount = annotations.compactMap(\.circle).count
        let textCount = annotations.compactMap(\.text).count

        if annotations.isEmpty {
            return L10n.string("studio.no_annotations_summary")
        }

        return String.localizedStringWithFormat(
            L10n.string("studio.annotation_count_format"),
            strokeCount,
            circleCount,
            textCount
        )
    }

    private func openAnnotationEditor() {
        guard hasCanvasSource else { return }

        annotationEditorSession = AnnotationEditorSession(
            image: selectedImage,
            thumbnail: selectedMockThumbnail,
            annotations: annotations
        )
    }

    private var annotationOverlay: some View {
        AnnotationOverlayView(
            annotations: annotations,
            baseSize: annotationCanvasSize,
            renderAspectRatio: canvasSourceAspectRatio
        )
    }

    private var canvasSourceAspectRatio: CGFloat? {
        if let selectedImage {
            return selectedImage.size.width / max(selectedImage.size.height, 1)
        }

        return nil
    }

    private func clearAnnotations() {
        annotations.removeAll()
    }

    private func applyContinuationContextIfNeeded() {
        guard let continuationContext else { return }

        isApplyingPersistedState = true
        selectedImage = continuationContext.image
        selectedMockThumbnail = continuationContext.image == nil ? continuationContext.thumbnail : nil
        imageScale = 1
        imageOffset = .zero
        annotations.removeAll()
        successMessage = nil
        imageSelectionMessage = nil
        isApplyingPersistedState = false
        persistStudioState()
    }

    private func exitContinuationMode() {
        onClearContinuation()
        selectedImage = nil
        selectedMockThumbnail = nil
        imageScale = 1
        imageOffset = .zero
        annotations.removeAll()
        successMessage = nil
        persistStudioState()
    }

    private func applyPersistedStateForCurrentProject(force: Bool) {
        guard let projectID = currentProject?.id else {
            loadedProjectID = nil
            return
        }

        guard force || loadedProjectID != projectID else { return }
        loadedProjectID = projectID

        isApplyingPersistedState = true
        let state = persistedState ?? StudioProjectState()
        motionPrompt = state.motionPrompt
        interpretationMode = state.interpretationMode
        annotations = state.annotations
        selectedMockThumbnail = state.selectedMockThumbnail
        selectedImage = state.selectedImageData.flatMap(UIImage.init(data:))
        imageScale = state.imageScale
        imageOffset = state.imageOffset
        generationParameters = state.generationParameters
        successMessage = nil
        imageSelectionMessage = nil
        isApplyingPersistedState = false
    }

    private func persistStudioState() {
        guard currentProject != nil, isApplyingPersistedState == false else { return }

        onStudioStateChanged(
            StudioProjectState(
                motionPrompt: motionPrompt,
                interpretationMode: interpretationMode,
                annotations: annotations,
                selectedMockThumbnail: selectedMockThumbnail,
                selectedImageData: selectedImage?.jpegData(compressionQuality: 0.82),
                imageScale: imageScale,
                imageOffset: imageOffset,
                generationParameters: generationParameters
            )
        )
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    private var promptPreview: StudioPromptPreview {
        StudioPromptPreview(request: currentGenerationRequest, pipelineResult: currentPromptPipelineResult)
    }

    private var currentPromptPipelineResult: PromptPipelineResult {
        let annotationSummary = AnnotationIntentBuilder.buildSummary(
            from: annotations,
            canvasSize: annotationCanvasSize
        )

        let context = VideoPromptBuildContext(
            interpretationMode: interpretationMode,
            userMotionPrompt: motionPrompt,
            projectName: currentProject?.title,
            generationMode: activeGenerationMode,
            continuationSourceClipTitle: continuationContext?.title,
            sourceImageStatus: sourceImageStatus,
            annotationSummary: annotationSummary
        )

        return VideoPromptBuilder.build(context: context)
    }

    private var currentGenerationRequest: GenerationRequest {
        let trimmedPrompt = motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let strokes = annotations.compactMap(\.stroke)
        let circles = annotations.compactMap(\.circle)
        let texts = annotations.compactMap(\.text)
        let textDetails = texts.map { text in
            "\"\(text.text)\" near \(positionLabel(for: text.position))"
        }
        let pipelineResult = currentPromptPipelineResult

        let annotationSummary = annotationSummaryText(
            strokeCount: strokes.count,
            circleCount: circles.count,
            textAnnotations: textDetails
        )

        return GenerationRequest(
            projectID: currentProject?.id,
            projectName: currentProject?.title,
            sourceImageStatus: sourceImageStatus,
            sourceClipID: continuationContext?.id,
            sourceClipTitle: continuationContext?.title,
            motionPrompt: trimmedPrompt.isEmpty ? "No motion prompt yet" : trimmedPrompt,
            annotationSummary: annotationSummary,
            strokeCount: strokes.count,
            circleCount: circles.count,
            textAnnotations: textDetails,
            generationMode: activeGenerationMode,
            mockDuration: generationParameters.duration.value,
            outputStyle: generationParameters.quality.outputStyle,
            quality: generationParameters.quality.title,
            generationParameters: generationParameters,
            startsFromPreviousFrame: continuationContext != nil,
            generatedInstruction: pipelineResult.finalVideoPrompt
        )
    }

    private var sourceImageStatus: String {
        if let continuationContext {
            return continuationContext.image == nil
                ? "Mock last frame from output clip \"\(continuationContext.title)\""
                : "Image from output clip \"\(continuationContext.title)\""
        }

        return selectedImage == nil ? "No image selected yet" : "Selected local Photos image"
    }

    private func annotationSummaryText(strokeCount: Int, circleCount: Int, textAnnotations: [String]) -> String {
        var lines = [
            "Freehand strokes: \(strokeCount)",
            "Circles / ellipses: \(circleCount)",
            "Text annotations: \(textAnnotations.count)"
        ]

        if textAnnotations.isEmpty == false {
            lines.append("Text content: \(textAnnotations.joined(separator: "; "))")
        }

        if strokeCount == 0 && circleCount == 0 && textAnnotations.isEmpty {
            lines.append("No annotations have been added yet.")
        }

        return lines.joined(separator: "\n")
    }

    private func positionLabel(for point: CGPoint) -> String {
        let horizontal: String
        let vertical: String
        let width = max(annotationCanvasSize.width, 1)
        let height = max(annotationCanvasSize.height, 1)

        switch point.x / width {
        case ..<0.34:
            horizontal = "left"
        case 0.34..<0.67:
            horizontal = "center"
        default:
            horizontal = "right"
        }

        switch point.y / height {
        case ..<0.34:
            vertical = "upper"
        case 0.34..<0.67:
            vertical = "middle"
        default:
            vertical = "lower"
        }

        if horizontal == "center" && vertical == "middle" {
            return "center"
        }

        if horizontal == "center" {
            return "\(vertical)-center"
        }

        if vertical == "middle" {
            return "center-\(horizontal)"
        }

        return "\(vertical)-\(horizontal)"
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), size.width),
            y: min(max(point.y, 0), size.height)
        )
    }
}

private struct AnnotationEditorSession: Identifiable {
    let id = UUID()
    let image: UIImage?
    let thumbnail: ThumbnailStyle?
    let annotations: [StudioAnnotation]
}

private struct AnnotationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTool = "Pan"
    @State private var draftAnnotations: [StudioAnnotation]
    @State private var activeStroke: AnnotationStroke?
    @State private var activeCircle: AnnotationCircle?
    @State private var activeTextDragID: UUID?
    @State private var activeTextDragStartPosition: CGPoint?
    @State private var pendingTextPosition: CGPoint?
    @State private var isPresentingTextAnnotation = false

    let image: UIImage?
    let thumbnail: ThumbnailStyle?
    let baseCanvasSize: CGSize
    let imageScale: CGFloat
    let imageOffset: CGSize
    let onDone: ([StudioAnnotation]) -> Void

    private let tools = [
        ("Pan", "hand.draw"),
        ("Draw", "pencil.tip"),
        ("Circle", "circle"),
        ("Text", "textformat"),
        ("Eraser", "eraser")
    ]

    init(
        image: UIImage?,
        thumbnail: ThumbnailStyle?,
        initialAnnotations: [StudioAnnotation],
        baseCanvasSize: CGSize,
        imageScale: CGFloat,
        imageOffset: CGSize,
        onDone: @escaping ([StudioAnnotation]) -> Void
    ) {
        self.image = image
        self.thumbnail = thumbnail
        self.baseCanvasSize = baseCanvasSize
        self.imageScale = imageScale
        self.imageOffset = imageOffset
        self.onDone = onDone
        _draftAnnotations = State(initialValue: initialAnnotations)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                editorCanvas

                toolControls

                Text(selectedToolHint)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(L10n.string("annotation.editor.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        onDone(draftAnnotations)
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .sheet(isPresented: $isPresentingTextAnnotation) {
            ManagementRenameSheet(title: L10n.string("annotation.add_text"), placeholder: L10n.string("annotation.text_placeholder"), initialName: "") { text in
                addTextAnnotation(text)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var editorCanvas: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let maxHeight = max(proxy.size.height, 320)
            let aspectRatio = canvasAspectRatio
            let canvasHeight = min(max(width / aspectRatio, 320), maxHeight)

            VStack {
                ZStack {
                    editorSourceView(displaySize: CGSize(width: width, height: canvasHeight))
                        .frame(width: width, height: canvasHeight)

                    AnnotationOverlayView(
                        annotations: draftAnnotations,
                        baseSize: baseCanvasSize,
                        renderAspectRatio: canvasAspectRatio,
                        activeStroke: activeStroke,
                        activeCircle: activeCircle
                    )
                    .frame(width: width, height: canvasHeight)
                    .allowsHitTesting(false)
                }
                .frame(width: width, height: canvasHeight)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .contentShape(Rectangle())
                .gesture(annotationGesture(in: CGSize(width: width, height: canvasHeight)))
                .overlay(alignment: .topLeading) {
                    Label(toolTitle(selectedTool), systemImage: selectedToolIcon)
                        .font(PannotateTheme.Typography.label)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial.opacity(0.72))
                        .clipShape(Capsule())
                        .padding(14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                )

                Spacer(minLength: 0)
            }
        }
    }

    private var toolControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(tools, id: \.0) { tool in
                    let isSelected = selectedTool == tool.0

                    Button {
                        selectedTool = tool.0
                        finishTextDrag()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tool.1)
                                .font(PannotateTheme.Typography.cardTitle)

                            Text(toolTitle(tool.0))
                                .font(PannotateTheme.Typography.label)
                        }
                        .foregroundStyle(isSelected ? PannotateTheme.Colors.accent : PannotateTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(isSelected ? PannotateTheme.Colors.accentSoft.opacity(0.72) : PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? PannotateTheme.Colors.accent.opacity(0.8) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Button {
                    undoLastAnnotation()
                } label: {
                    Label("common.undo", systemImage: "arrow.uturn.backward")
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(canUndoAnnotations ? PannotateTheme.Colors.secondaryText : PannotateTheme.Colors.tertiaryText.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canUndoAnnotations)

                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        clearAnnotations()
                    }
                } label: {
                    Label("common.clear", systemImage: "eraser")
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(canUndoAnnotations ? .red : PannotateTheme.Colors.tertiaryText.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canUndoAnnotations)
            }
        }
    }

    private var canUndoAnnotations: Bool {
        draftAnnotations.isEmpty == false || activeStroke != nil || activeCircle != nil
    }

    private var selectedToolIcon: String {
        tools.first(where: { $0.0 == selectedTool })?.1 ?? "hand.draw"
    }

    private func toolTitle(_ tool: String) -> String {
        switch tool {
        case "Draw":
            L10n.string("annotation.tool.draw")
        case "Circle":
            L10n.string("annotation.tool.circle")
        case "Text":
            L10n.string("annotation.tool.text")
        case "Eraser":
            L10n.string("annotation.tool.eraser")
        default:
            L10n.string("annotation.tool.pan")
        }
    }

    private var canvasAspectRatio: CGFloat {
        if let image {
            return max(image.size.width / max(image.size.height, 1), 0.62)
        }

        return 16 / 9
    }

    @ViewBuilder
    private func editorSourceView(displaySize: CGSize) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(imageScale)
                .offset(scaledImageOffset(for: displaySize))
                .clipped()
        } else if let thumbnail {
            MockThumbnail(style: thumbnail, cornerRadius: 0)
        }
    }

    private var selectedToolHint: String {
        switch selectedTool {
        case "Draw":
            return L10n.string("annotation.draw_hint")
        case "Circle":
            return L10n.string("annotation.circle_hint")
        case "Text":
            return L10n.string("annotation.text_hint")
        case "Eraser":
            return L10n.string("annotation.eraser_hint")
        default:
            return L10n.string("annotation.pan_hint")
        }
    }

    private func scaledImageOffset(for displaySize: CGSize) -> CGSize {
        CGSize(
            width: imageOffset.width * displaySize.width / max(baseCanvasSize.width, 1),
            height: imageOffset.height * displaySize.height / max(baseCanvasSize.height, 1)
        )
    }

    private func annotationGesture(in displaySize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: selectedTool == "Text" || selectedTool == "Eraser" ? 0 : 2)
            .onChanged { value in
                let start = basePoint(for: value.startLocation, in: displaySize)
                let current = basePoint(for: value.location, in: displaySize)

                switch selectedTool {
                case "Draw":
                    updateActiveStroke(with: current)
                case "Circle":
                    updateActiveCircle(start: start, current: current)
                case "Pan", "Text":
                    updateTextDrag(start: start, current: current)
                case "Eraser":
                    eraseAnnotation(near: current)
                default:
                    break
                }
            }
            .onEnded { value in
                let start = basePoint(for: value.startLocation, in: displaySize)
                let current = basePoint(for: value.location, in: displaySize)

                switch selectedTool {
                case "Draw":
                    commitActiveStroke()
                case "Circle":
                    commitActiveCircle()
                case "Text":
                    if activeTextDragID != nil {
                        finishTextDrag()
                    } else if distance(from: start, to: current) < 8 {
                        pendingTextPosition = current
                        isPresentingTextAnnotation = true
                    }
                case "Pan":
                    finishTextDrag()
                case "Eraser":
                    eraseAnnotation(near: current)
                default:
                    break
                }
            }
    }

    private func updateActiveStroke(with point: CGPoint) {
        if activeStroke == nil {
            activeStroke = AnnotationStroke(points: [point])
        } else {
            activeStroke?.points.append(point)
        }
    }

    private func commitActiveStroke() {
        guard let activeStroke, activeStroke.points.count > 1 else {
            activeStroke = nil
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            draftAnnotations.append(.stroke(activeStroke))
        }
        self.activeStroke = nil
    }

    private func updateActiveCircle(start: CGPoint, current: CGPoint) {
        activeCircle = AnnotationCircle(rect: CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        ))
    }

    private func commitActiveCircle() {
        guard let activeCircle, activeCircle.rect.width > 8, activeCircle.rect.height > 8 else {
            activeCircle = nil
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            draftAnnotations.append(.circle(activeCircle))
        }
        self.activeCircle = nil
    }

    private func addTextAnnotation(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false, let pendingTextPosition else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            draftAnnotations.append(.text(AnnotationText(text: trimmedText, position: pendingTextPosition)))
        }

        self.pendingTextPosition = nil
    }

    private func updateTextDrag(start: CGPoint, current: CGPoint) {
        if activeTextDragID == nil {
            guard let hit = hitTextAnnotation(at: start) else { return }
            activeTextDragID = hit.id
            activeTextDragStartPosition = hit.position
        }

        guard let activeTextDragID,
              let activeTextDragStartPosition,
              let index = draftAnnotations.firstIndex(where: { $0.id == activeTextDragID }) else { return }

        let translation = CGSize(width: current.x - start.x, height: current.y - start.y)
        let proposedPosition = CGPoint(
            x: activeTextDragStartPosition.x + translation.width,
            y: activeTextDragStartPosition.y + translation.height
        )

        if case .text(let text) = draftAnnotations[index] {
            draftAnnotations[index] = .text(AnnotationText(
                id: text.id,
                text: text.text,
                position: clampedPoint(proposedPosition)
            ))
        }
    }

    private func finishTextDrag() {
        activeTextDragID = nil
        activeTextDragStartPosition = nil
    }

    private func eraseAnnotation(near point: CGPoint) {
        guard let index = draftAnnotations.lastIndex(where: { annotationHits($0, at: point) }) else { return }

        withAnimation(.easeInOut(duration: 0.12)) {
            _ = draftAnnotations.remove(at: index)
        }
    }

    private func undoLastAnnotation() {
        withAnimation(.easeInOut(duration: 0.18)) {
            if activeStroke != nil {
                activeStroke = nil
            } else if activeCircle != nil {
                activeCircle = nil
            } else if draftAnnotations.isEmpty == false {
                draftAnnotations.removeLast()
            }
        }
    }

    private func clearAnnotations() {
        draftAnnotations.removeAll()
        activeStroke = nil
        activeCircle = nil
        finishTextDrag()
        pendingTextPosition = nil
    }

    private func hitTextAnnotation(at point: CGPoint) -> AnnotationText? {
        draftAnnotations.compactMap(\.text).last { text in
            textHitRect(for: text).contains(point)
        }
    }

    private func annotationHits(_ annotation: StudioAnnotation, at point: CGPoint) -> Bool {
        let hitRadius: CGFloat = 24

        switch annotation {
        case .stroke(let stroke):
            return stroke.points.contains { distance(from: $0, to: point) <= hitRadius }
        case .circle(let circle):
            return circle.rect.insetBy(dx: -hitRadius, dy: -hitRadius).contains(point)
        case .text(let text):
            return textHitRect(for: text).insetBy(dx: -hitRadius, dy: -hitRadius).contains(point)
        }
    }

    private func textHitRect(for text: AnnotationText) -> CGRect {
        let width = max(CGFloat(text.text.count) * 9 + 28, 72)
        let height: CGFloat = 42

        return CGRect(
            x: text.position.x - width / 2,
            y: text.position.y - height / 2,
            width: width,
            height: height
        )
    }

    private func basePoint(for displayPoint: CGPoint, in displaySize: CGSize) -> CGPoint {
        clampedPoint(CGPoint(
            x: displayPoint.x * max(baseCanvasSize.width, 1) / max(displaySize.width, 1),
            y: displayPoint.y * max(baseCanvasSize.height, 1) / max(displaySize.height, 1)
        ))
    }

    private func clampedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), max(baseCanvasSize.width, 1)),
            y: min(max(point.y, 0), max(baseCanvasSize.height, 1))
        )
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }
}

private struct AnnotationOverlayView: View {
    let annotations: [StudioAnnotation]
    let baseSize: CGSize
    var renderAspectRatio: CGFloat?
    var activeStroke: AnnotationStroke?
    var activeCircle: AnnotationCircle?

    var body: some View {
        GeometryReader { geometry in
            let annotationRect = annotationRenderRect(in: geometry.size)

            ZStack {
                ForEach(annotations) { annotation in
                    annotationView(annotation, renderRect: annotationRect)
                }

                if let activeStroke {
                    strokeView(activeStroke, renderRect: annotationRect)
                }

                if let activeCircle {
                    circleView(activeCircle, renderRect: annotationRect)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    @ViewBuilder
    private func annotationView(_ annotation: StudioAnnotation, renderRect: CGRect) -> some View {
        switch annotation {
        case .stroke(let stroke):
            strokeView(stroke, renderRect: renderRect)
        case .circle(let circle):
            circleView(circle, renderRect: renderRect)
        case .text(let text):
            textView(text, renderRect: renderRect)
        }
    }

    private func strokeView(_ stroke: AnnotationStroke, renderRect: CGRect) -> some View {
        Path { path in
            guard let firstPoint = stroke.points.first else { return }

            path.move(to: displayPoint(for: firstPoint, in: renderRect))

            for point in stroke.points.dropFirst() {
                path.addLine(to: displayPoint(for: point, in: renderRect))
            }
        }
        .stroke(PannotateTheme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    private func circleView(_ circle: AnnotationCircle, renderRect: CGRect) -> some View {
        let rect = displayRect(for: circle.rect, in: renderRect)

        return Ellipse()
            .stroke(PannotateTheme.Colors.accent, lineWidth: 4)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func textView(_ text: AnnotationText, renderRect: CGRect) -> some View {
        Text(text.text)
            .font(.headline.weight(.heavy))
            .foregroundStyle(PannotateTheme.Colors.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(PannotateTheme.Colors.accent.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .position(displayPoint(for: text.position, in: renderRect))
    }

    private func displayPoint(for point: CGPoint, in renderRect: CGRect) -> CGPoint {
        CGPoint(
            x: renderRect.minX + point.x * renderRect.width / max(baseSize.width, 1),
            y: renderRect.minY + point.y * renderRect.height / max(baseSize.height, 1)
        )
    }

    private func displayRect(for rect: CGRect, in renderRect: CGRect) -> CGRect {
        CGRect(
            x: renderRect.minX + rect.minX * renderRect.width / max(baseSize.width, 1),
            y: renderRect.minY + rect.minY * renderRect.height / max(baseSize.height, 1),
            width: rect.width * renderRect.width / max(baseSize.width, 1),
            height: rect.height * renderRect.height / max(baseSize.height, 1)
        )
    }

    private func annotationRenderRect(in displaySize: CGSize) -> CGRect {
        guard let renderAspectRatio, renderAspectRatio > 0 else {
            return CGRect(origin: .zero, size: displaySize)
        }

        return AspectRatioRect.scaledToFill(aspectRatio: renderAspectRatio, in: displaySize)
    }
}

private enum AspectRatioRect {
    static func scaledToFill(aspectRatio: CGFloat, in containerSize: CGSize) -> CGRect {
        let containerWidth = max(containerSize.width, 1)
        let containerHeight = max(containerSize.height, 1)
        let containerAspectRatio = containerWidth / containerHeight

        let size: CGSize
        if aspectRatio > containerAspectRatio {
            size = CGSize(width: containerHeight * aspectRatio, height: containerHeight)
        } else {
            size = CGSize(width: containerWidth, height: containerWidth / aspectRatio)
        }

        return CGRect(
            x: (containerWidth - size.width) / 2,
            y: (containerHeight - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
}

private struct ImageAdjustmentSession: Identifiable {
    let id = UUID()
    let image: UIImage
    var initialScale: CGFloat = 1
    var initialOffset: CGSize = .zero
    var clearsAnnotationsOnConfirm = true
    var exitsContinuationOnConfirm = true
}

private struct GenerateReviewSession: Identifiable {
    let id = UUID()
    let request: GenerationRequest
    let pipelineResult: PromptPipelineResult
    let originalFinalPrompt: String
    let title: String
    let thumbnail: ThumbnailStyle
    let image: UIImage?
    let continuationSourceClipID: UUID?
    let continuationSourceClipTitle: String?
    let generationParameters: GenerationParameterState
}

private struct GenerateReviewResult {
    let finalPrompt: String
    let parameters: GenerationParameterState
}

private struct GenerateReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: GenerateReviewSession
    let onConfirm: (GenerateReviewResult) -> Void
    @State private var editedFinalPrompt: String
    @State private var parameters: GenerationParameterState
    @State private var showsAdvancedSettings = false

    init(session: GenerateReviewSession, onConfirm: @escaping (GenerateReviewResult) -> Void) {
        self.session = session
        self.onConfirm = onConfirm
        _editedFinalPrompt = State(initialValue: session.originalFinalPrompt)
        _parameters = State(initialValue: session.generationParameters)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summarySection
                    imageSection
                    promptSection
                    generationSettingsSection
                    payloadSummarySection
                    detailsSection
                }
                .padding(PannotateTheme.Metrics.pagePadding)
            }
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(L10n.string("generation.review_generation"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("generation.confirm_generate") {
                        onConfirm(
                            GenerateReviewResult(
                                finalPrompt: editedFinalPrompt,
                                parameters: sanitizedParameters
                            )
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var summarySection: some View {
        reviewCard(title: L10n.string("common.summary")) {
            VStack(alignment: .leading, spacing: 10) {
                metadataRow(label: L10n.string("common.project"), value: session.request.projectName ?? L10n.string("common.no_project"))
                metadataRow(label: L10n.string("generation.context"), value: generationContextText)
                metadataRow(label: L10n.string("generation.mode"), value: session.pipelineResult.interpretationMode.title)
                metadataRow(label: L10n.string("studio.annotations"), value: "\(session.pipelineResult.normalizedAnnotations.count)")
            }
        }
    }

    private var imageSection: some View {
        reviewCard(title: L10n.string("generation.image_preview")) {
            ZStack {
                if let image = session.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    MockThumbnail(style: session.thumbnail, cornerRadius: 18)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(PannotateTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    private var promptSection: some View {
        reviewCard(title: L10n.string("generation.editable_final_prompt")) {
            VStack(alignment: .leading, spacing: 10) {
                Text("generation.review_prompt_note")
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)

                TextEditor(text: $editedFinalPrompt)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .padding(12)
                    .background(PannotateTheme.Colors.background.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                    )

                if editedFinalPrompt != session.originalFinalPrompt {
                    Button {
                        editedFinalPrompt = session.originalFinalPrompt
                    } label: {
                        Label("generation.restore_generated_prompt", systemImage: "arrow.counterclockwise")
                            .font(PannotateTheme.Typography.metadataEmphasis)
                            .foregroundStyle(PannotateTheme.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var generationSettingsSection: some View {
        reviewCard(title: L10n.string("generation.settings")) {
            VStack(alignment: .leading, spacing: 14) {
                parameterPicker(
                    title: L10n.string("generation.duration"),
                    selection: $parameters.duration,
                    options: GenerationDurationOption.allCases
                )

                parameterPicker(
                    title: L10n.string("generation.aspect_ratio"),
                    selection: $parameters.aspectRatio,
                    options: GenerationAspectRatioOption.allCases
                )

                parameterPicker(
                    title: L10n.string("generation.quality"),
                    selection: $parameters.quality,
                    options: GenerationQualityOption.allCases
                )

                DisclosureGroup(isExpanded: $showsAdvancedSettings) {
                    VStack(alignment: .leading, spacing: 12) {
                        labeledParameterField(title: L10n.string("generation.negative_prompt")) {
                            TextField(L10n.string("generation.negative_prompt_placeholder"), text: $parameters.negativePrompt, axis: .vertical)
                                .lineLimit(2...4)
                        }

                        labeledParameterField(title: L10n.string("generation.seed")) {
                            TextField(L10n.string("generation.automatic"), text: $parameters.seedText)
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Label(L10n.string("generation.advanced"), systemImage: "slider.horizontal.3")
                        .font(PannotateTheme.Typography.metadataEmphasis)
                        .foregroundStyle(PannotateTheme.Colors.accent)
                }
            }
        }
    }

    private var detailsSection: some View {
        reviewCard(title: L10n.string("common.details")) {
            VStack(alignment: .leading, spacing: 10) {
                metadataRow(label: L10n.string("generation.request_id"), value: String(session.request.id.uuidString.prefix(8)))
                metadataRow(label: L10n.string("generation.prompt"), value: session.request.motionPrompt)
                metadataRow(label: L10n.string("generation.duration"), value: sanitizedParameters.duration.value)

                if let sourceClipTitle = session.continuationSourceClipTitle {
                    metadataRow(label: L10n.string("generation.source_clip"), value: sourceClipTitle)
                }
            }
        }
    }

    private var payloadSummarySection: some View {
        reviewCard(title: L10n.string("generation.api_payload_summary")) {
            Text(apiPayloadSummary)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var apiPayloadSummary: String {
        let finalPrompt = editedFinalPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? session.originalFinalPrompt
            : editedFinalPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let submission = VideoGenerationSubmission(
            request: session.request.applyingGenerationParameters(sanitizedParameters),
            pipelineResult: session.pipelineResult,
            title: session.title,
            duration: sanitizedParameters.duration.value,
            thumbnail: session.thumbnail,
            image: session.image,
            continuationSourceClipID: session.continuationSourceClipID,
            continuationSourceClipTitle: session.continuationSourceClipTitle,
            finalVideoPrompt: finalPrompt,
            originalGeneratedPrompt: session.originalFinalPrompt
        )

        return GenerationPayloadBuilder.build(submission: submission).compactSummary
    }

    private var sanitizedParameters: GenerationParameterState {
        var sanitized = parameters
        sanitized.negativePrompt = sanitized.negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSeed = sanitized.seedText.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized.seedText = Int(trimmedSeed) == nil ? "" : trimmedSeed
        return sanitized
    }

    private var generationContextText: String {
        session.request.startsFromPreviousFrame
            ? L10n.string("generation.continue_from_last_frame")
            : L10n.string("generation.new_shot")
    }

    private func reviewCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(PannotateTheme.Typography.label)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PannotateTheme.Colors.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(PannotateTheme.Typography.label)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)
                .frame(width: 92, alignment: .leading)

            Text(value)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func parameterPicker<Option: GenerationParameterOption>(
        title: String,
        selection: Binding<Option>,
        options: Option.AllCases
    ) -> some View where Option.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(PannotateTheme.Typography.label)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            Picker(title, selection: selection) {
                ForEach(Array(options), id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func labeledParameterField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(PannotateTheme.Typography.label)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            content()
                .textFieldStyle(.plain)
                .font(PannotateTheme.Typography.metadata)
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .padding(12)
                .background(PannotateTheme.Colors.background.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                )
        }
    }
}

private struct StudioPromptPreview {
    let request: GenerationRequest
    let pipelineResult: PromptPipelineResult

    var interpretationModeText: String {
        switch pipelineResult.interpretationMode {
        case .fast:
            L10n.string("studio.fast_mode_preview_text")
        case .smart:
            L10n.string("studio.smart_mode_preview_text")
        }
    }

    var currentProjectText: String {
        request.projectName ?? L10n.string("common.no_project_selected")
    }

    var generationContextText: String {
        if request.startsFromPreviousFrame {
            return String.localizedStringWithFormat(
                L10n.string("generation.context_continue_format"),
                request.sourceClipTitle ?? L10n.string("outputs.selected_output_clip")
            )
        }

        return L10n.string("generation.context_new_shot")
    }

    var motionPromptText: String {
        request.motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? L10n.string("studio.no_motion_prompt")
            : request.motionPrompt
    }

    var annotationSummaryText: String {
        """
        \(request.annotationSummary)

        \(pipelineResult.annotationSummary.humanSummary)
        """
    }

    var normalizedAnnotationData: String {
        guard pipelineResult.normalizedAnnotations.isEmpty == false else {
            return "No normalized annotation objects yet."
        }

        return pipelineResult.normalizedAnnotations
            .map { annotation in
                """
                - id: \(annotation.id.uuidString.prefix(8))
                  type: \(annotation.type.rawValue)
                  position: \(annotation.positionDescription.rawValue)
                  size: \(annotation.sizeDescription.rawValue)
                  bounds: x \(formatted(annotation.normalizedBounds.minX)), y \(formatted(annotation.normalizedBounds.minY)), w \(formatted(annotation.normalizedBounds.width)), h \(formatted(annotation.normalizedBounds.height))
                  text: \(annotation.textContent ?? "None")
                """
            }
            .joined(separator: "\n")
    }

    var structuredFields: String {
        """
        Request ID: \(request.id.uuidString)
        Created: \(request.createdAt.formatted(date: .abbreviated, time: .shortened))
        Project: \(request.projectName ?? "No project")\(request.projectID.map { " (\($0.uuidString))" } ?? "")
        Source image: \(request.sourceImageStatus)
        Source clip: \(request.sourceClipTitle ?? "None")\(request.sourceClipID.map { " (\($0.uuidString))" } ?? "")
        Mode: \(request.generationMode.title) (\(request.generationMode.requestValue))
        Interpretation mode: \(pipelineResult.interpretationMode.title) (\(pipelineResult.interpretationMode.requestValue))
        Continuation: \(request.startsFromPreviousFrame ? "Yes" : "No")
        Mock duration: \(request.mockDuration)
        Aspect ratio: \(request.generationParameters.aspectRatio.value)
        Output style: \(request.outputStyle)
        Quality: \(request.quality)
        Negative prompt: \(request.generationParameters.negativePrompt.isEmpty ? "None" : request.generationParameters.negativePrompt)
        Seed: \(request.generationParameters.seedText.isEmpty ? "Automatic" : request.generationParameters.seedText)
        Motion prompt: \(request.motionPrompt)
        Text annotations: \(request.textAnnotations.isEmpty ? "None" : request.textAnnotations.joined(separator: "; "))
        """
    }

    var smartPayloadPreview: String {
        let payload = pipelineResult.smartPayload
        let annotationLines = payload.annotations.isEmpty
            ? "None"
            : payload.annotations.map { "- \($0.readableDescription)" }.joined(separator: "\n")

        return """
        Smart Mode preview. This is a simulated LLM interpretation. No real API call yet.

        Future LLM instruction:
        \(payload.instruction)

        Original image: \(payload.originalImageStatus)
        Project: \(payload.projectName ?? "No project")
        Mode: \(payload.generationMode.title)
        Continuation source: \(payload.continuationSourceClipTitle ?? "None")
        User prompt: \(payload.userPrompt)

        Normalized annotation objects:
        \(annotationLines)
        """
    }

    var jsonPreview: String {
        let textValues = request.textAnnotations
            .map { "\"\(jsonEscaped($0))\"" }
            .joined(separator: ", ")

        return """
        {
          "requestId": "\(request.id.uuidString)",
          "interpretationMode": "\(pipelineResult.interpretationMode.requestValue)",
          "project": {
            "id": "\(request.projectID?.uuidString ?? "none")",
            "name": "\(jsonEscaped(request.projectName ?? "No project"))"
          },
          "mode": "\(request.generationMode.requestValue)",
          "sourceImage": "\(jsonEscaped(request.sourceImageStatus))",
          "sourceClip": {
            "id": "\(request.sourceClipID?.uuidString ?? "none")",
            "title": "\(jsonEscaped(request.sourceClipTitle ?? "None"))"
          },
          "motionPrompt": "\(jsonEscaped(request.motionPrompt))",
          "annotationSummary": "\(jsonEscaped(request.annotationSummary))",
          "annotations": {
            "strokes": \(request.strokeCount),
            "circles": \(request.circleCount),
            "texts": [\(textValues)],
            "normalizedCount": \(pipelineResult.normalizedAnnotations.count)
          },
          "fastPrompt": "\(jsonEscaped(pipelineResult.fastPrompt))",
          "smartMockResult": "\(jsonEscaped(pipelineResult.smartMockResult))",
          "finalVideoPrompt": "\(jsonEscaped(pipelineResult.finalVideoPrompt))",
          "duration": "\(request.mockDuration)",
          "aspectRatio": "\(request.generationParameters.aspectRatio.value)",
          "outputStyle": "\(jsonEscaped(request.outputStyle))",
          "quality": "\(jsonEscaped(request.quality))",
          "negativePrompt": "\(jsonEscaped(request.generationParameters.negativePrompt))",
          "seed": "\(request.generationParameters.seedText.isEmpty ? "automatic" : jsonEscaped(request.generationParameters.seedText))",
          "continueFromLastFrame": \(request.startsFromPreviousFrame ? "true" : "false")
        }
        """
    }

    private func jsonEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func formatted(_ value: CGFloat) -> String {
        String(format: "%.2f", Double(value))
    }
}

private struct PromptPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preview: StudioPromptPreview

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    previewSection(title: L10n.string("studio.interpretation_mode"), text: preview.interpretationModeText)
                    previewSection(title: L10n.string("studio.user_motion_prompt"), text: preview.motionPromptText)
                    previewSection(title: L10n.string("common.current_project"), text: preview.currentProjectText)
                    previewSection(title: L10n.string("generation.context"), text: preview.generationContextText)
                    previewSection(title: L10n.string("generation.annotation_summary"), text: preview.annotationSummaryText)
                    previewSection(title: L10n.string("generation.normalized_annotation_data"), text: preview.normalizedAnnotationData, monospaced: true)
                    previewSection(title: L10n.string("generation.fast_mode_prompt"), text: preview.pipelineResult.fastPrompt)
                    previewSection(title: L10n.string("generation.smart_payload"), text: preview.smartPayloadPreview)
                    previewSection(title: L10n.string("generation.smart_mock_result"), text: preview.pipelineResult.smartMockResult)
                    previewSection(title: L10n.string("generation.final_video_prompt"), text: preview.pipelineResult.finalVideoPrompt)
                    previewSection(title: L10n.string("generation.structured_fields"), text: preview.structuredFields)
                    previewSection(title: L10n.string("generation.json_style_preview"), text: preview.jsonPreview, monospaced: true)
                }
                .padding(PannotateTheme.Metrics.pagePadding)
            }
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(L10n.string("studio.request_preview"))
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

    private func previewSection(title: String, text: String, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(PannotateTheme.Typography.label)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(PannotateTheme.Colors.tertiaryText)

            Text(text)
                .font(monospaced ? .system(.footnote, design: .monospaced).weight(.semibold) : .body.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(PannotateTheme.Colors.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }
}

private struct ImageAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    let session: ImageAdjustmentSession
    let onConfirm: (UIImage, CGFloat, CGSize) -> Void
    let onCancel: () -> Void

    @State private var imageScale: CGFloat
    @State private var lastImageScale: CGFloat
    @State private var imageOffset: CGSize
    @State private var lastImageOffset: CGSize

    init(
        session: ImageAdjustmentSession,
        onConfirm: @escaping (UIImage, CGFloat, CGSize) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.session = session
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _imageScale = State(initialValue: session.initialScale)
        _lastImageScale = State(initialValue: session.initialScale)
        _imageOffset = State(initialValue: session.initialOffset)
        _lastImageOffset = State(initialValue: session.initialOffset)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Text("studio.adjust_image_note")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PannotateTheme.Metrics.pagePadding)

                adjustmentCanvas
                    .padding(.horizontal, PannotateTheme.Metrics.pagePadding)

                Label("studio.adjust_image_hint", systemImage: "hand.draw")
                    .font(PannotateTheme.Typography.metadataEmphasis)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)

                Spacer()

                PrimaryActionButton(title: L10n.string("studio.use_this_framing"), systemImage: "checkmark") {
                    onConfirm(session.image, imageScale, imageOffset)
                    dismiss()
                }
                .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
                .padding(.bottom, 18)
            }
            .padding(.top, 20)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(L10n.string("studio.adjust_image"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.reset") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            imageScale = 1
                            lastImageScale = 1
                            imageOffset = .zero
                            lastImageOffset = .zero
                        }
                    }
                }
            }
        }
    }

    private var adjustmentCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                Image(uiImage: session.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(imageAdjustmentGesture(in: geometry.size))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func imageAdjustmentGesture(in canvasSize: CGSize) -> some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let proposedOffset = CGSize(
                        width: lastImageOffset.width + value.translation.width,
                        height: lastImageOffset.height + value.translation.height
                    )

                    imageOffset = clampedOffset(proposedOffset, canvasSize: canvasSize, scale: imageScale)
                }
                .onEnded { _ in
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                    lastImageOffset = imageOffset
                },
            MagnificationGesture()
                .onChanged { value in
                    imageScale = clampedScale(lastImageScale * value)
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                }
                .onEnded { _ in
                    imageScale = clampedScale(imageScale)
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                    lastImageScale = imageScale
                    lastImageOffset = imageOffset
                }
        )
    }

    private func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, 1), 4)
    }

    private func clampedOffset(_ offset: CGSize, canvasSize: CGSize, scale: CGFloat) -> CGSize {
        let maxX = canvasSize.width * max(scale - 1, 0) / 2
        let maxY = canvasSize.height * max(scale - 1, 0) / 2

        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}

#Preview {
    StudioView(currentProject: MockPannotateData.projects.first)
}
